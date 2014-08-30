#!/bin/bash
a=$(grep enable_notif /etc/nagios3/nagios.cfg  |grep 1 |wc -l)
b=$( ps aux |grep nagios3 |grep -v grep | wc -l )
c=$( ps aux |grep dequeue.pl  |grep -v grep |wc -l )
if [[ $a -gt 0 && $b -gt 0 && $c -gt 0 ]];then
echo -n
else
echo "pls fix asap" | mail -s "Nagios/aggregator down" email@domain.com
/usr/local/bin/send_sms "nagios/aggregator down" 112233445
fi
