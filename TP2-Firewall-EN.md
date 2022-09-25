# TP2 - Firewall (English version)

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

_This statement is based on the work of François Lesueur ([original work](https://github.com/flesueur/srs/blob/master/tp2-firewall.md))._

Duration: 4 hours

Setup The Environment
=====================

Like the [TP1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md), this practical work will be based upon the
educational platform [MI-LXC](https://github.com/flesueur/mi-lxc).

As a reminder, the deployed infrastructure emulated several devices in an enterprise (firewall, firewall, DMZ, intranet, central authentication, file sharing, several internal workstations of the company _Target_), a workstation of an attacker and few other devices useful for running the platform. We won't detail yet the whole network infrastructure.

> For the most curious of you, the MI-LXC code which generate this VM automaticaly, is available with a documented procedure [here](https://github.com/flesueur/mi-lxc)

You should connect to the VM using the credentials `root/root`. MI-LXC is already installed and the infrastructure deployed. To run the infrastructure, open a terminal and go in the golder `/root/mi-lxc`. Then enter the command `./mi-lxc.py start`. Once started, you can put your hands on !

> In the Virtual Machine and the MI-LXC devices, you can install additional softwares. By default, `Mousepad` can help edit files with a UI. The fullscreen mode can be enabled to display the VM. If it does not work, sometimes you have to change the window size manually by dragging the right lower border, so VirtualBox can detect that the automatic resize feature is available. This feature has to be enabled in the `Screen` menu. If it does not work, try to reboot the VM.

Before starting working, and even if `iptables` and `netfilter` have been stated during the course, you should consider to read the chapter
[Netfilter](https://en.wikibooks.org/wiki/Communication_Networks/IP_Tables) of Wikibook.

>Note 1 : If you want to explore new paths, you can use nftables, the descendant of iptables. Some interesting things can help start
>working with it [here](https://wiki.nftables.org/wiki-nftables/index.php/Simple_rule_management)

>Note 2 : Only IPv4 is going to be seen, but the infrastructure also supports IPv6. So you can also work with IPv6 if wanted.


Cheat Sheet
===========

You can find below a quick summary of the available commands :

| Commande | Description | Utilisation |
| -------- | ----------- | ----------- |
| print    | Display the network emulated by MI-LXC | ./mi-lxc.py print |
| attach   | Open a new shell on a device | ./mi-lxc.py attach root@target-commercial |
| display  | Open a graphical interface on a device | ./mi-lxc.py display target-commercial |
| start    | Start the emulated infrastructure    | ./mi-lxc.py start |
| stop     | Shutdown the infrastructure.       | ./mi-lxc.py stop |
| renet    | Rebuilt the network from the json configuration | ./mi-lxc.py stop && ./mi-lxc.py renet |

Note: You should be in the directory  `mi-lxc` to run commands.

Router Topology
===============

Connect on "target-router":  `./mi-lxc.py attach target-router`

Look at the network configuration, both interfaces `eth0` and `eth1`, with `ipconfig` or `ip addr`.

1. Identify which one is the LAN interface and which one is the WAN interface. Note the IP address of each one.

Protecting The Device
=====================

We are going now to configure the firewall on "target-router". By using the manual page of `iptables`, display all the active rules.
You should have some like this:

```
Chain FORWARD (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 ACCEPT     all  --  eth0   eth1    0.0.0.0/0            100.80.1.2          
    0     0 ACCEPT     all  --  eth0   eth1    0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
    0     0 ACCEPT     all  --  eth1   eth0    0.0.0.0/0            0.0.0.0/0           

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
```

You should see for each chain :

* the "policy" (default behavior) ;
* the packet count that matched the rules of the chain ;
* the according bytes.

Very few rules are setup yet ; this command should allow you to list all the active rules in the "filter" table.

First iptables Rule
-------------------

During this exercise, the "isp-a-hacker" machine will help simulate an attacker that would like to exploit the _Target_'s network.

Check that you can connect to "target-router" using SSH with the machine "isp-a-hacker" (`./mi-lxc.py attach isp-a-hacker`) :

`ssh root@100.64.0.10`

> The IP _100.64.0.10_ is the public IP if "target-router". You can see it using `./mi-lxc.py print`)

Now, let deny all the connections on TCP/22 (SSH). To do this, deny all the packets on port 22 in the INPUT chain with the target `DROP`.

Apply the rule with the `iptables` command on "target-router". Try to connect using SSH on "target-router" from "isp-a-hacker".

Here, the target `DROP` has been used. You can see that the connection is properly denied but the SSH client is hanging for a while.

2. Write the rule you applied and explain it.
3. Why does the SSH client takes time to state the connection has been refused ?

Remove the previously added rule.
Apply the same rule but replace the target `DROP` by `REJECT` then try again to connect using SSH.

4. What kind of change do you observe ? Why ? (you can use `tcpdump` to understand what is happening)


Rule Order & Priority
---------------------

A same packet can match several filtering rules, that can be inconsistent : Netfilter applies the rules in sequence and chooses the
first matching rule (caution, some firewalls process the rules in the other way and some of them - like Windows Firewall - do not care
about the order...). This is what we call masking.

In order to show this behavior, we are going to use the filtering parameters in the [section "Specifications" of the Wikibook](https://en.wikibooks.org/wiki/Communication_Networks/IP_Tables#Rule-specifications).

5. Show on an example that the rule order counts. To change the filtering, you'll need to remove rules and add new ones at a specific position : read the manual.
6. Put in place a rule set allowing SSH on the router only from the LAN of _Target_ (you can use "target-admin" to test them for example).

In practice, the masking is often use to define a general case with a low priority or - at the opposite - a specific case with a high priority.
In the later one, it can be confusing.

Modules Of iptables
==================

iptables is extended with a module system. A description of the modules dans be found in the manual of "iptables-extensions".

Comment
-------

The `comment` module, as its name mention it, allows to add a comment to a rule in order to make sure the rule is understandables.
To use this module: 
`iptables -A INPUT -m comment --comment "Ceci est un commentaire" -j...`

Multiport
---------

The multiport module allows to create a single rule matching several ports (instead of several rules) : 
`iptables -A INPUT -m multiport -p tcp --dports port1,port2,port3 -j...`

Add a rule using multiport allowing ports 22 and 53. Feel free to add a comment to understand better what is doing this rule (several
modules can be used in a row).

Connection Tracking ("state")
----------------------------

Netfilter allows to track connecion states using the module `state` (firewall _stateful_). This module allows to detect new flows,
established ones and flows relying on another ones. This connection tracking allows to filter more precisely some protocols.

The `state` module defines several stats for the network flows :

* NEW : new connection
* ESTABLISHED : this connection is already known (the connection was in NEW recently)
* RELATED : this connection is linked or relying on an ESTABLISHED one. Only the first packet of a connection can be RELATED, the next ones are ESTABLISHED. This is mostly used for FTP connections.

For instance the existing rule in the FORWARD chain :
`    0     0 ACCEPT     all  --  eth0   eth1    0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED`
means that only the packets in state `RELATED` OR `ESTABLISHED` are authorized from `eth0` to `eth1`, ie, only the "replies" can go in this direction.

To see the effect of the following question, first try to block everything in egress using this policy : `iptables -P OUTPUT DROP`
Then add a rule to allow in output only the replies to incoming SSH connections (towards SSH service of the router).

7. Explain the rule you just wrote.

Design The Network Security Policy
==================================

Specifications
--------------

The goal of a network security policy is to reduce the amount of service that can be reached from the outside (historical approach) and
to seggregate the internal network in distinct zones (with restricted authorizations between these zones, in order to reduce the risk of
latelarization/propagation of a threat). Such policy is defined in 3 steps :

1. Creation of logical network zones based upon sub-networks ;
2. Identification of network services hosted on each device and who access to these services ;
3. Definition of the authorized network flows allowed between each zone depending and the previously identified needs (by default, the rule
of the least privilege should be applied). This is the "flow matrix".

> Below is a sample of a flow matrix that could match the 2 initial zones (definitely insufficient, in addition this is not what is
> implemented by iptables by default)
>
> |   src\dst  |      ext           |     int                      |
> |:----------:|:------------------:|:----------------------------:|
> |    ext     |      X             | SMTP(S),IMAP(S),HTTP(S),DNS  |
> |    int     |    tout            |        X                     |


8. By using the [Addressing Plan from the TP1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md#addressing-plan),
explain with a table a network security policy for the whole network of the _Target_ company.

As a reminder, the network is composed of :

| Machine           | Description |
| :-------:         | ----------- |
| target-router     | Router     |
| target-admin      | Workstation of the system administrator. Administration of all the devices. |
| target-commercial | Workstation of the salesman. Use the intranet. |
| target-dev        | Workstation of the developer. Update the intranet. |
| target-dmz        | Demilitarized Zone : all the services exposed to the Internet used by _Target_ |
| target-ldap       | Central Authentication, required by all the devices of _Target_ (including the DMZ) |
| target-filer      | File sharing server, required by all the workstations |
| target-intranet   | Web server for the intranet, not exposed publicly |

The command `./mi-lxc.py print` can help to display the mapping of whole network (LAN and WAN).

You can use both the commands `netstat -laptn` or `ss -lnptu` to display currently binded ports, and thus the services that are running
on a server.

Your description (flow matrix as a table with source machines in rows, destination machines in columns and authorized services in the cells)
has to be self explanatory : another student, with only this table, should be able to implement the **very same** iptables rules than you.

**__Ask your teacher to validate your flow matrix (not the iptables rules).__**

Implementation
--------------
Once the network policy has been designed, the implementation can be done on the router (subnets) and on the firewall (filtering rules).

Implement your flow matrix on the machine "target-router". You'll need to proceed in 2 steps :

* Seggregate the network "target" : (you shall look at the [following video][vidéo explicative](https://tube.ac-lyon.fr/videos/watch/c03fe09e-cef6-4f31-9bd1-0453d160eb85))
  * Edit `global.json` (in the folder `mi-lxc` of the VM) to specify the new interfaces on the router, in the "target" section.
  You have to add new bridges (the name should be suffixed by "target-") and split the network space 100.80.0.1/16. Then, you shall add the interfaces
  eth2, eth3, ... newly created in the list `asdev` defined above (with the ';' delimiter between the interface)
  * Edit `groups/target/local.json` to edit the interface addresses and the bridges of the internal machines (caution: for a bridged previously named
  "target-dmz", you only have to write "dmz" here, the suffix "target-" is automatically added). In the same file, you'll have to update
  the servers mentioned in the templates parameters "ldapclient", "sshfs", "nodhcp", or by replacing the server name with their new IP addresses, or
  by updating the DNS records (`/etc/nsd/target.milxc.zone` on "target-dmz")
  * Run `./mi-lxc.py print` to have a preview of the new network.
	* Run `./mi-lxc.py stop && ./mi-lxc.py renet && ./mi-lxc.py start` to upgrade the new infrastructure.
* Implement the iptables rules on "target-router" (chain FORWARD). You can use the commands `iptables-save` and `iptables-apply` to write a script.

9. Detail each operation you are doing.

> The MI-LXC json files are explained [here](https://github.com/flesueur/mi-lxc#how-to-extend).

Policy By-Pass
--------------

Let's imagine you are the developer (once again) and you would like to provide an access to the Intranet ("target-intranet") to an
external friend, despite the fact the Intranet is not publicly available. You'll create a tunnel to by-pass the security policy.
By using "target-dev" (your workstation) and "isp-a-home" (an external machine, at home), try to by-pass the security policy.

We are going to use the tool `netcat` to setup a simple tunnel.

Connect to the machine "isp-a-home". There is a _Apache_ service that is running on TCP/80. Since we need TCP/80, stop the _Apache_ service
then run `netcat` to bind on TCP/80 (HTTP):
```bash
service apache2 stop
while true; do nc -v -l -p 80 -c "nc -l -p 8080"; done
```

Then, on "target-dev", setup an outgoing connection to the remote machine, "isp-a-home"
```bash
while true; do nc -v 100.120.0.3 80 -c "nc 100.80.0.5 80"; sleep 2; done
```

>As a reminder :
>* 100.120.0.3 = isp-a-home
>* 100.80.0.5 = target-intranet

Check you can connect to the intranet using "isp-a-home" using the URL `http://100.120.0.3:8080`

10. Explain what is happening with a schema.

It's very difficult to block or to detect a tunnel (let's imagine an encrypted tunnel with SSH or HTTPS).

Bonus
=====

FTP
---

FTP, as some of other protocols, is a challenge for firewalls. Indeed, the control part of FTP is performed on a different connection (and
a different port) from the data connection. The modern firewalls know how to link both connections and know how to deal with it.

A FTP server is installed on "target-dmz", configure the firewall to allow the file sharing from a machine outside the network of _Target_.
FTP requires a valid Linux user (debian/debian for instance).

Shorewall
---------
You have figured out how complex it is to configure a firewall. Especially when you have to read existing rules or to check their
consistence. Maintaining these rules is a complex duty in production : they change regularly and need a periodic review.

Several softwares have been released to help `iptables` rules management. _Shorewall_ is one of them. This is not a daemon and relies
on `iptables`. It simplifies the configuration by defining the "zone" concept. On "target-router", install _Shorewall_ (`apt-get install shorewall`)
then implement the security policy once again with this tool.

_Note: You can also experiment `firewalld` which is more modern_
