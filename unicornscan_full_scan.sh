unicornscan -i ${1:-tap0} -I -E ${2:-127.0.0.1}:a | grep -v closed
