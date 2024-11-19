#!/usr/bin/env bash

PROGNAME=$(basename $0)
RELEASE="Version 0.2.2"

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

HOST=""
PORT=""
PROTOCOL="https"
ENDPOINT=""
METRIC=""
LABEL=""
OPERATOR="gt"
WARNING=0
CRITICAL=0
TIME_OUT=60

declare -A OPERATORS
OPERATORS=(
    ["eq"]="equal to"
    ["ne"]="not equal to"
    ["lt"]="less than"
    ["le"]="less than or equal to"
    ["gt"]="greater than"
    ["ge"]="greater than or equal to"
)

# plugin version
print_release() {
    echo "$RELEASE"
}

# plugin usage
print_usage() {
        echo ""
        echo "$PROGNAME $RELEASE - Check exporter metrics"
        echo ""
        echo "Usage: $PROGNAME -H HOST -p PORT -e ENDPOINT -m METRIC [options]"
        echo ""
        echo "Options:"
        echo "  -H  <string> : Host (REQUIRED)"
        echo "  -p  <number> : Port (REQUIRED)"
        echo "  -e  <string> : Endpoint (REQUIRED)"
        echo "  --protocol <string> : Protocol (default: https)"
        echo "  -m  <string> : Metric name (e.g. /customMetrics - REQUIRED)"
        echo "  -l  <string> : Label to make result unique (e.g. \"server=\\\"test\\\"\")"
        echo "  -o  <string> : Comparison operators: eq, ne, gt, lt, ge, le (default: gt)"
        echo "  -w  <number> : Warning threshold (default: 0)"
        echo "  -c  <number> : Critical threshold (default: 0)"
        echo "  -t  <number> : Timeout in seconds (default: 60)"
        echo "  -h  Shows this page"
        echo ""
}

print_help() {
        print_usage
        echo ""
        echo "This plugin can check exporter metrics from a http(s) endpoint"
        echo "and check the result against the thresholds"
        echo ""
        exit 0
}

# Parse parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
                print_help
                exit $STATE_OK
                ;;
        -v | --version)
                print_release
                exit $STATE_OK
                ;;
        -H | --host)
                shift
                HOST=$1
                ;;
        -p | --port)
                shift
                PORT=$1
                ;;
        --protocol)
                shift
                PROTOCOL=$1
                ;;
        -e | --endpoint)
                shift
                ENDPOINT=$1
                ;;
        -m | --metric)
                shift
                METRIC=$1
                ;;
        -l | --label)
                shift
                LABEL=$1
                ;;
        -o | --operator)
                shift
                OPERATOR=${1,,}
                ;;
        -w | --warning)
                shift
                WARNING=$1
                ;;
        -c | --critical)
                shift
                CRITICAL=$1
                ;;
        -t | --timeout)
                shift
                TIME_OUT=$1
                ;;
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

# validate args
if [ -z "$HOST" ]; then
    printf "UNKNOWN - Hostname not specified, check --help\n"
    exit $STATE_UNKNOWN
fi

if [ -z "$PORT" ]; then
    printf "UNKNOWN - Port not specified, check --help\n"
    exit $STATE_UNKNOWN
fi

if [ -z "$ENDPOINT" ]; then
    printf "UNKNOWN - Endpoint not specified, check --help\n"
    exit $STATE_UNKNOWN
fi

if [ -z "$METRIC" ]; then
    printf "UNKNOWN - Metric not specified, check --help\n"
    exit $STATE_UNKNOWN
fi

if ! [[ "$OPERATOR" =~ eq|ne|gt|lt|ge|le ]]; then
    printf "UNKNOWN - invalid operator '$OPERATOR', check --help\n"
    exit $STATE_UNKNOWN
fi

# get metrics from endpoint
url="$PROTOCOL://${HOST}:${PORT}${ENDPOINT}"
response_code=$(curl -k --max-time $TIME_OUT -o /dev/null -s -w "%{http_code}" $url)
if [ "$response_code" -eq "200" ]; then
    DATA=$(curl -s -k --max-time $TIME_OUT $url)
    if ! [[ "$DATA" =~ "$METRIC{" ]]; then
        printf "UNKNOWN - did not recieve '$METRIC' metrics\n"
        exit $STATE_UNKNOWN
    fi
else
    printf "UNKNOWN - HTTP $response_code - cannot curl data from $url\n"
    exit $STATE_UNKNOWN
fi

# check if data contains metric
METRICS=$(echo "$DATA" | grep -i "$METRIC{")
readarray -t METRICS_ARRAY <<<"$METRICS"
declare -a RESULTS
pattern="^${METRIC}\{[^}]*${LABEL}[^}]*\} (.*)$"

# loop over data that matched
for line in "${METRICS_ARRAY[@]}"; do
    if [[ "$line" =~ $pattern ]]; then
        VALUE=$(printf "%.0f" "${BASH_REMATCH[1]}")
        RESULTS+=("$VALUE")
        OUTPUT=$(echo "$line" | sed "s/${BASH_REMATCH[1]}/$VALUE/")
    fi
done

if [ "${#RESULTS[@]}" -eq 0 ]; then
    printf "UNKNOWN - found '$METRIC' but none with label '$LABEL' - make sure to set a correct --label\n"
    printf "$METRICS\n"
    exit $STATE_UNKNOWN
elif [ "${#RESULTS[@]}" -gt 1 ]; then
    printf "UNKNOWN - found more than 1 value for '$METRIC' with label '$LABEL' - make sure to set a unique --label\n"
    printf "$METRICS\n"
    exit $STATE_UNKNOWN
fi

# validate exitcode
if [ "${RESULTS[0]}" -${OPERATOR} "$CRITICAL" ]; then
    printf "CRITICAL - $OUTPUT (${OPERATORS[$OPERATOR]} $CRITICAL)\n"
    exit $STATE_CRITICAL
elif [ "${RESULTS[0]}" -${OPERATOR} "$WARNING" ]; then
    printf "WARNING - $OUTPUT (${OPERATORS[$OPERATOR]} $WARNING)\n"
    exit $STATE_CRITICAL
else
    printf "OK - $OUTPUT\n"
    exit $STATE_OK
fi
