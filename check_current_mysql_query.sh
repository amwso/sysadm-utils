#!/bin/bash
set -e
set -o pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH=/usr/local/mysql/bin:$PATH
MYSQL_BIN_PATH=mysql
MYSQL_DEFAULTS_FILE=/usr/local/vhost/tools/.my.cnf
OVERTIME=10
DO_KILL=yes
KILL_LOG=/var/log/mysql_killed.log

# | Id | User | Host | db | Command | Time | State | Info |
# | 21900447 | root | localhost | NULL | Query | 0 | NULL  | show processlist |
readarray PROC_LIST < <($MYSQL_BIN_PATH --defaults-file=$MYSQL_DEFAULTS_FILE -s -e "show processlist;"  | awk -v overtime=$OVERTIME -F'\t' 'BEGIN {OFS="|";} $5 ~ /Query/ && $2 !~ /root/ && $6 >= overtime {print $1, $2, $5, $6, $8}')

# 21908595|root|Query|0|show processlist
if [ "$DO_KILL" == "yes" ] && [ ! -z "${PROC_LIST[0]}" ] ; then
	for PROC in "${PROC_LIST[@]}" ; do
		$MYSQL_BIN_PATH --defaults-file=$MYSQL_DEFAULTS_FILE -s -e "kill `awk -F'|' '{print $1}' <<< $PROC`;" >/dev/null 2>&1
		echo "`date +'%Y-%m-%d %H:%M:%S -- '``awk -F'|' '{print $2, $4, $5}' <<< $PROC`" >> $KILL_LOG
	done
fi
