## check_exporter_metrics.sh - Check exporter metrics

Usage: check_exporter_metrics.sh -H HOST -p PORT -e ENDPOINT -m METRIC [options]

Options:
  -H  <string> : Host (REQUIRED)
  -p  <number> : Port (REQUIRED)
  -e  <string> : Endpoint (REQUIRED)
  --protocol <string> : Protocol (default: https)
  -m  <string> : Metric name (e.g. /customMetrics - REQUIRED)
  -m  <string> : Label to make result unique (e.g. "server=\"test\"")
  -o  <string> : Comparison operators: eq, ne, gt, lt, ge, le (default: gt)
  -w  <number> : Warning threshold (default: 0)
  -c  <number> : Critical threshold (default: 0)
  -t  <number> : Timeout in seconds (default: 60)
  -h  Shows this page


This plugin can check exporter metrics from a http(s) endpoint
and check the result against the thresholds
