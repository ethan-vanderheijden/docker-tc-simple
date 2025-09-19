#!/usr/bin/env bash
QDISC_ID=
QDISC_HANDLE=
tc_init() {
    QDISC_ID=1
    QDISC_HANDLE="root handle $QDISC_ID:"
}
qdisc_del() {
    tc qdisc del dev "$1" root
}
qdisc_next() {
    QDISC_HANDLE="parent $QDISC_ID: handle $((QDISC_ID+1)):"
    ((QDISC_ID++))
}
# Following calls to qdisc_netm and qdisc_tbf are chained together
# http://man7.org/linux/man-pages/man8/tc-netem.8.html
qdisc_netm() {
    IF="$1"
    shift
    tc qdisc add dev "$IF" $QDISC_HANDLE netem $@
    qdisc_next
}
# http://man7.org/linux/man-pages/man8/tc-tbf.8.html
qdisc_tbf_ingress() {
    IF="$1"
    shift
    tc qdisc add dev "$IF" $QDISC_HANDLE tbf burst 50kb latency 50ms $@
    qdisc_next
}
qdisc_tbf_egress() {
    PID="$1"
    shift
    nsenter --target $PID --net  -- tc qdisc add dev eth0 root tbf burst 50kb latency 50ms $@
}
