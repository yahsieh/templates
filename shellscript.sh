#!/bin/sh

readonly PROG="`basename $0`"

usage_and_exit() {
	cat << EOF
Usage: $PROG
description

Options:
-w                Warning
-c                Critical
-h, --help        Display this help and exit

EOF
	exit 1
}

ARGS=`getopt -n $PROG -o w:c:h -l help -- "$@"`
[ $? -ne 0 ] && { echo; usage_and_exit; }
eval set -- "${ARGS}"

while true; do
	case "$1" in
		-w)
			WARNING_PERCENT=$2
            expr match "$WARNING_PERCENT" "^[1-9][0-9]\?%\|100%\|0%$" > /dev/null
			if [ $? -ne 0 ]; then
				echo "Invalid argument: \"-w $WARNING_PERCENT\""
                exit 1
			fi
            shift 2
			;;
		-c)
			CRITICAL_PERCENT=$2
            expr match "$CRITICAL_PERCENT" "^[1-9][0-9]\?%\|100%\|0%$" > /dev/null
			if [ $? -ne 0 ]; then
				echo "Invalid argument: \"-c $CRITICAL_PERCENT\""
                exit 1
			fi
            shift 2
			;;
		-h|--help)
			usage_and_exit
			exit 1
			;;
        --)
            shift
            break
            ;;
	esac
done

if [ -z "$CRITICAL_PERCENT" ] || [ -z "$WARNING_PERCENT" ]; then
    usage_and_exit
fi

free | sed -n 2p | awk -v c="$CRITICAL_PERCENT" -v w="$WARNING_PERCENT" '{
    sub(/%/, "", c);
    sub(/%/, "", w);
    if ($4 / $2 <= c / 100) {
        status = "CRITICAL";
        retval = 2;
    } else if ($4 / $2 <= w / 100) {
        status = "WARNING";
        retval = 1;
    } else {
        status = "OK";
        retval = 0;
    }
    printf("%s, %.2f%% - total: %d, used: %d, free: %d, shared: %d, buff/cache: %d, available: %d (kB)\n",
           status, ($4/$2)*100, $2, $3, $4, $5 ,$6, $7);
    exit retval;
}'
