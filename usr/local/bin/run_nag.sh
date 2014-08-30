#!/bin/bash

exec 2>&1
sleep 2 
exec /usr/local/bin/nagios_mon.sh
