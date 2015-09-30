#!/bin/bash

D=${1:-/etc/fwgen/rules}
[ -d $D ] && cd $D || { echo "Rules directory $D not found."; exit 1; }

process_dir() {
    DIR=$1
    [ ! -d $DIR ] && return
    RULES="$(ls -1d $DIR/* 2> /dev/null)"
    for rule in $RULES; do

        if [ -f $rule ]; then
            RULE_NAME=$( basename $(dirname $rule ) )
            RULE_NAME=$( echo $RULE_NAME|sed -e 's/[0-9]*_//' )
            process_rule $rule $RULE_NAME
        elif [ -d $rule ]; then
            RULE_NAME=$( basename $rule )
            RULE_NAME=$( echo $RULE_NAME|sed -e 's/[0-9]*_//' )
            echo "-A INPUT -j $RULE_NAME"
            process_dir $rule $RULE_NAME
        fi
    done
}

process_rule() {
    FILE=$1
    RULE_NAME=$2
    eval $( cat $FILE | grep GENERATOR=  )
    GENERATOR=${GENERATOR:-simple_input}
    #echo processing $FILE $RULE_NAME with $GENERATOR
    generators/$GENERATOR $FILE $RULE_NAME
}

echo "# Generated by fwgen on `date`"

echo "*filter"
cat rules/default_filter
process_dir rules/filter/INPUT
process_dir rules/filter/FORWARD
process_dir rules/filter/OUTPUT
echo "COMMIT"

echo "*nat"
cat rules/default_nat
process_dir rules/nat/PREROUTING
process_dir rules/nat/POSTROUTING
process_dir rules/nat/OUTPUT
echo "COMMIT"

echo "*mangle"
cat rules/default_mangle
process_dir rules/mangle/PREROUTING
process_dir rules/mangle/POSTROUTING
process_dir rules/mangle/OUTPUT
process_dir rules/mangle/INPUT
process_dir rules/mangle/FORWARD
echo "COMMIT"
