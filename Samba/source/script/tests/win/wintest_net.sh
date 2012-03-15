#!/bin/sh

. script/tests/test_functions.sh

. script/tests/win/wintest_functions.sh

# This variable is defined in the per-hosts .fns file.
. $WINTESTCONF

if [ $# -lt 4 ]; then
cat <<EOF
Usage: test_net.sh SERVER USERNAME PASSWORD DOMAIN
EOF
exit 1;
fi

server="$1"
username="$2"
password="$3"
domain="$4"
shift 4

ncacn_np_tests="NET-API-LOOKUP NET-API-LOOKUPHOST NET-API-RPCCONN-BIND NET-API-RPCCONN-SRV NET-API-RPCCONN-DC NET-API-RPCCONN-DCINFO NET-API-LISTSHARES"
#These tests fail on ncacn_np: NET-API-LOOKUPPDC NET-API-CREATEUSER NET-API-DELETEUSER

ncalrpc_tests="NET-API-RPCCONN-SRV NET-API-RPCCONN-DC NET-API-RPCCONN-DCINFO NET-API-LISTSHARES"
#These tests fail on ncalrpc: NET-API-CREATEUSER NET-API-DELETEUSER

ncacn_ip_tcp_tests="NET-API-LOOKUP NET-API-LOOKUPHOST NET-API-RPCCONN-SRV NET-API-RPCCONN-DC NET-API-RPCCONN-DCINFO NET-API-LISTSHARES"
#These tests fail on ncacn_ip_tcp: NET-API-LOOKUPPDC NET-API-CREATEUSER NET-API-DELETEUSER

bind_options="seal,padcheck bigendian"

test_type="ncalrpc ncacn_np ncacn_ip_tcp"

all_errs=0
for o in $bind_options; do
	for transport in $test_type; do
		case $transport in
			ncalrpc) net_test=$ncalrpc_tests ;;
			ncacn_np) net_test=$ncacn_np_tests ;;
			ncacn_ip_tcp) net_test=$ncacn_ip_tcp_tests ;;
		esac

		for t in $net_test; do
			test_name="$t on $transport with $o"
			old_errs=$all_errs
			testit "$test_name" $SMBTORTURE_BIN_PATH \
				-U $username%$password \
				-W $domain \
				$transport:$server[$o] \
				$t || all_errs=`expr $all_errs + 1`
			if [ $old_errs -lt $all_errs ]; then
				restore_snapshot "\n$test_name failed."
			fi
		done
	done
done

testok $0 $all_errs
