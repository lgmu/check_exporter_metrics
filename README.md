## check_exporter_metrics.sh - Check exporter metrics
```
Usage: check_exporter_metrics.sh -H HOST -p PORT -e ENDPOINT -m METRIC [options]

Options:
  -H  <string> : Host (REQUIRED)
  -p  <number> : Port (REQUIRED)
  -e  <string> : Endpoint (REQUIRED)
  --protocol <string> : Protocol (default: https)
  -m  <string> : Metric name (e.g. /customMetrics - REQUIRED)
  -l  <string> : Label to make result unique (e.g. "server=\"test\"")
  -o  <string> : Comparison operators: eq, ne, gt, lt, ge, le (default: gt)
  -w  <number> : Warning threshold (default: 0)
  -c  <number> : Critical threshold (default: 0)
  -t  <number> : Timeout in seconds (default: 60)
  -h  Shows this page


This plugin can check exporter metrics from a http(s) endpoint
and check the result against the thresholds
```

### Examples

**node_exporter**: Check if a device is on AC Power, return critical if the metric does not return 1
```
./check_exporter_metrics.sh -H localhost -p 9100 -e /metrics --protocol http \
  -m node_power_supply_power_source_state -l "state=\"AC Power\"" -w 1 -c 1 -o ne
```
OK - node_power_supply_power_source_state{power_supply="InternalBattery-0",state="AC Power"} 1

CRITICAL - node_power_supply_power_source_state{power_supply="InternalBattery-0",state="AC Power"} 0 (not equal to 1)

### Tips and tricks
- Labels provided with -l are interpreted as regex, so you have to escape special characters like / and also the double quotes
- It has to match exactly one metric, otherwise the plugin will complain:
```
UNKNOWN - found more than 1 value for 'node_power_supply_power_source_state' with label 'state' - make sure to set a unique --label
node_power_supply_power_source_state{power_supply="InternalBattery-0",state="AC Power"} 0
node_power_supply_power_source_state{power_supply="InternalBattery-0",state="Battery Power"} 1
node_power_supply_power_source_state{power_supply="InternalBattery-0",state="Off Line"} 0
```
