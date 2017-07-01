Naggregator
======

Helping

Naggregator:  Nagios Aggregator is a tool to aggreagte alerts from Nagios.

It helps to group alerts which have same semantics. It helps to reduce the number of alerts and increases the turnaround to attend to the problem.

For eg, multiple hosts alerting for same service is grouped as single alert. Similarly service alert of same type  from multiple hosts are sent as single alert.

It also has integration to Exotel to call mobiles or send sms.

How it works
------

The tool consists of below two queues:

1) enqueue.pl - This script gathers alerts from nagios to a directory. Nagios calls this script everytime there is a alert to be sent. This is called by nagios command line mentioned in  /etc/nagios3/commands.cfg.

2) dequeue.pl - This script  polls for the alert directory dumped by enqueue. It parses the alerts, adds logic and constructs the new semantic alert. It can alert via sms to mobile or can use Exotel to call mobiles, if you have Extoel account.


How to Setup
------

Please refer "setup/INSTALL" for detailed steps.

