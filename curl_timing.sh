DIRNAME=$(dirname $0)

curl -w "@${DIRNAME}/curl_timing_format.txt" -o /dev/null -s $1
