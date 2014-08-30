#!/bin/bash

exec 2>&1
sleep 2
exec setuidgid  nagios  /etc/init.d/naggregator start
