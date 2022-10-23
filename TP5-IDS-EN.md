# TP5 - Intrusion Detection Systems

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

_This statement has been partially reworked from ([this one](https://github.com/flesueur/srs/blob/master/tp3-ids.md)) authored by
François Lesueur._

Duration: 4 hours

Setup The Environment
======================

Like the [TP1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM-EN.md), this practical work will be based upon the
educational platform [MI-LXC](https://github.com/flesueur/mi-lxc).

As a reminder, the deployed infrastructure emulated several devices in an enterprise (firewall, firewall, DMZ, intranet, central authentication, file sharing, several internal workstations of the company _Target_), a workstation of an attacker and few other devices useful for running the platform. We won't detail yet the whole network infrastructure.

> For the most curious of you, the MI-LXC code which generate this VM automaticaly, is available with a documented procedure [here](https://github.com/flesueur/mi-lxc)

You should connect to the VM using the credentials `root/root`. MI-LXC is already installed and the infrastructure deployed. To run the infrastructure, open a terminal and go in the golder `/root/mi-lxc`. Then enter the command `./mi-lxc.py start`. Once started, you can put your hands on !

> In the Virtual Machine and the MI-LXC devices, you can install additional softwares. By default, `Mousepad` can help edit files with a UI. The fullscreen mode can be enabled to display the VM. If it does not work, sometimes you have to change the window size manually by dragging the right lower border, so VirtualBox can detect that the automatic resize feature is available. This feature has to be enabled in the `Screen` menu. If it does not work, try to reboot the VM.

Cheat sheet
===========

You can find below a quick summary of the available commands :

| Commande | Description | Utilisation |
| -------- | ----------- | ----------- |
| print    | Display the network emulated by MI-LXC | ./mi-lxc.py print |
| attach   | Open a new shell on a device | ./mi-lxc.py attach root@target-commercial |
| display  | Open a graphical interface on a device | ./mi-lxc.py display target-commercial |
| start    | Start the emulated infrastructure    | ./mi-lxc.py start |
| stop     | Shutdown the infrastructure.       | ./mi-lxc.py stop |

Note: You should be in the directory  `mi-lxc` to run commands.

Kill Chain Analysis
===================

The "target" company needs you aand your team in order to put in place mitigations in order to prevent their worst scenario from
happening : a _ransomware_ attack that may lead to a major dataleak.

The main steps of such an attack are:
1. The adversary sends a fraudulent email to the employees to make them download a malicious file.
2. The user downloads the malicious file by clicking on the link in the email.
3. The user opens the malicious file which setup a backdoor.
4. The adversary uses the backdoor to move around the information system and get access to sensitive data.
5. The adversary exfiltrates data to a remote server.
6. The adversary encrypts the data.

By focusing **only** on steps 2, 3 and 5, tell which technical solutions (HTTP Proxy, NIDS, HIDS) you would recommend and where you
may put them in place. Detail a quick action plan.

**Ask a teacher to validate your action plan before going further.**

HTTP Proxy Configuration
========================

## Installation

A filtering HTTP proxy allows to control what kind of content can be browsed by the users with a fine-grained configuration. This is
easy to put in place and this is what you are going to do right now.

You are going to use a very common proxy called `squid` with its extension `squid-guard` that will allow you to filter the HTTP flow.
First, install these softwares on "target-router".

```bash
apt-get update
apt-get install -y squid squidguard
```
You can check `squid` has been properly installer by crafting a HTTP request using the local proxy on TCP/3128 which should give you
a response similar to this :
```
# curl -I -x localhost:3128 https://www.isen.fr/
HTTP/1.1 200 Connection established

HTTP/2 200 
date: Sun, 02 May 2021 11:43:13 GMT
server: Apache
vary: User-Agent,Accept-Encoding
last-modified: Sun, 02 May 2021 02:01:20 GMT
accept-ranges: bytes
content-length: 40774
x-content-type-options: nosniff
x-frame-options: sameorigin
cache-control: max-age=0, no-cache, no-store, must-revalidate
pragma: no-cache
expires: Mon, 29 Oct 1923 20:30:00 GMT
content-type: text/html; charset=UTF-8
```

You can notice the 2 HTTP codes 200. The first one confirms the connexion to the proxy is ok, the second one is the response to the
remote server hosing `isen.fr`.

## Configuration

By default `squid` is only a proxy and allows to cache resources. It was very convenient back in the years when the Internet bandwidth
was small and you had to share it among a lot of people. Nowadays proxies are mostly used for network security.

To do so, you have to configure `squid` to tell it to use the `squid-guard` module each time a URL is browsed in order to know whether
the user is allowed to visit it or needs to be forwarded somewhere else. You need to add in the configuration `/etc/squid/squid.conf`
[`url_rewrite_program`](http://www.squid-cache.org/Doc/config/url_rewrite_program/):
```
url_rewrite_program /usr/bin/squidGuard -c /etc/squidguard/squidGuard.conf
```

You also need to allow the network IPs to connect to the proxy since by default `squid` only accept _localhost_. At line 1408, change
the configuration to add a directive allowing the "target" subnet(s) to use the proxy:
```
acl allowed_ips src 100.80.0.0/16

http_access allow localhost
http_access allow allowed_ips

# And finally deny all other access to this proxy
http_access deny all
```

Then restart `squid` to take in consideration the changes.

```
# service squid restart
# service squid status
● squid.service - Squid Web Proxy Server
   Loaded: loaded (/lib/systemd/system/squid.service; enabled; vendor preset: en
   Active: active (running) since Sun 2021-05-02 13:00:17 CEST; 10s ago
     Docs: man:squid(8)
  Process: 1798 ExecStartPre=/usr/sbin/squid --foreground -z (code=exited, statu
  Process: 1801 ExecStart=/usr/sbin/squid -sYC (code=exited, status=0/SUCCESS)
 Main PID: 1802 (squid)
    Tasks: 4 (limit: 3556)
   Memory: 16.6M
```

The default configuration of `squid-guard` is not correct and deny all the traffic. Open the file `/etc/squidguard/squidGuard.conf`.
It is composed of 4 major parts:
- Time range definition: you can setup filtering rules based on time ranges to, i.e., deny the web traffic only the week-end.
- Source IPs definition.
- Websites definition.
- ACLs which are a combination of all the previous rules.

You are going to deal with a simple case: deny the access to `example.com` to the developer. If a policy violation is done, (s)he must
be redirected to `perdu.com`. At the opposite the Administrator will be able to do everything he wants.

First a file containing the forbidden domains needs to be created. Create a new file `/etc/squidguard/forbidden-domains.txt`  and in the
first line, add `example.com`. Now edit again the file `/etc/squidguard/squidGuard.conf`. Edit the variable `dbhome` to tell `squid-guard`
to load the file you just created in the good location: `dbhome /etc/squidguard/`.

Change the source IPs definition by configuring 2 groups:
- _admin_ composed of the router and the system administrator workstation
- _users_ composed of the developer and the commercial workstation.

> Note 1: `user` is a reserved keyword. Do not use it to name your groups.

> Note 2: Authentication won't be used in our case so you won't have to deal with users. `squid` allows to setup different rules depending
> on the logged users instead of relying on the network addressing plan.

The destinations have to be reworked as well. Add a new class named _forbidden_ and tell `squid-guard` to read the forbidden domains
in the previously filled file `forbidden-domains.txt` (only give the filename, the path has been configured through the `dbhome` variable).

Finally, configure the ACLs. A default case is mandatory to catch all the unexpected situations. You should have ACLs in 3 parts :
- The _admin_ group has no restriction (`pass any`).
- The _users_ group has no restriction for websites in _good_ but not in _forbidden_, otherwise, redirection to `http://perdu.com`.
- By default, no way to browse the Internet and redirect systematically to `http://perdu.com`.

Once you are done, save the configuration file and restart `squid`. Test the scenarios to make sure you have the expected behavior:
```bash
root@mi-target-router:~# curl -x 100.80.0.1:3128 -i example.com
# Obtention du contenu example.com

root@mi-target-dev:~# curl -x 100.80.0.1:3128 -i example.com
# Obtention du contenu de perdu.com
```

That kind of configuration is called _transparent_. It does mean the users are not directly redirected to `perdu.com` but the proxy
returns the content of `perdu.com` just like it was `example.com`. This is why only HTTP is supported here. If you try using HTTPS,
a 503 error is returned by `squid`. 

## Browser configuration

The proxy is now setup. You are going to use it in a browser. Open a graphical session on the developper workstation 
(`./mi-lxc.py display target-dev`) then open a browser. Try to go on `example.com` and you should see you have no restriction to browse
this website despite the proxy configuration.

Open the Firefox' settings then in the _General_ tab, look at the _Network Settings_ section. Enable _Manuel proxy configuration_ and
fill the HTTP proxy details you just installed : `100.80.0.1 on port 3128`. Save and try to go on `example.com` once again. The response
should be rewritten.

> Do not hestitate to clear Firefox cache.

> In the real life, such configuration is done through a _PAC_ file ([_Proxy Auto-Configuration_](https://developer.mozilla.org/en-US/docs/Web/HTTP/Proxy_servers_and_tunneling/Proxy_Auto-Configuration_PAC_file))
> hosted on the proxy server and deployed by DHCP.
 
This configuration is not secure enough. A user can easily by-pass the security policy by removing the Firefox configuration. What could
you do to make sure the proxy cannot be by-passed ?

NIDS Installation
=================

`Suricata` is an NIDPS and you are going to use it in this part. It is already installed on "target-router". Its configuration can be
found in `/etc/suricata/suricata.yaml` and you are going to use the ruleset in `/etc/suricata/rules/local.rules`. To use it, you need to
edit `suricata.yaml`.
The alerts are displayed in the log file `/var/log/suricata/fast.log` (`tail -f /var/log/suricata/fast.log` can help follow the alerts).

As an example, you can see the following rule in the default ruleset:
```
 alert tcp 10.0.0.1 80 -> 192.168.1.0/24 111 (content:"Waldo"; msg:"Waldo's here";sid:1001;)
```

This ruleset means:
* Only TCP packets from `10.0.0.1:80` to `192.168.1.0/24:111` (__caution, Suricate will only check flows going in this direction__)
* That contains "Waldo" strings in the payload
* The log is going to display "Waldo's here" if there are any match
* `alert` can be replaced by `drop` to drop the packet instead of log it (__IPS__ mode)
* The `sid` is an unique identifier
* The rules can be composed of many other elements (content, length, regexp, ...) : [Suricata Rules](https://suricata.readthedocs.io/en/latest/rules/index.html). [`http_stat_code`](https://suricata.readthedocs.io/en/latest/rules/http-keywords.html#http-stat-code)
  (with a _ and not a .) allows to watch the HTTP status code and [`threshold`](https://suricata.readthedocs.io/en/latest/rules/thresholding.html) to manage thresholds. <!-- \url{http://manual.snort.org/node32.html}) -->

Read the rules in the file `local.rules`. Try to trigger the rule "COMMUNITY WEB-MISC Test Script Access" by sending requests to the 
DMZ server (`http://www.target.milxc`) from  `isp-a-hacker`. Is the request interpreted by the web server despite the alert ?

> Caution: Make sure with the Firewall TP that your DNS entry `http://www.target.milxc` still refers to the DMZ IP `100.80.1.2`.

A lot of malwares use _packers_ to escape antivirus signatures (among other things). The most common packer is [_UPX_](https://upx.github.io/)
and it is very easy to detect with signatures allowing to detect packed file being downloaded. The binaries usually contains the string
`Info: This file is packed with the UPX executable packer http://upx.sf.net`.
Write a rule to detect when a _UPX_ packed file is downloaded by any decive on the "target" network.

When editing the rules, you need to reload the ruleset with `service suricata reload`. You can monitor the Suricata state and the
errors due to the ruleset by looking at the logs `/var/log/suricata/suricata.log`.

> To test your rule, you can find packed malware URLs by using a OSINT feed : https://urlhaus.abuse.ch/browse/tag/mozi/.

> To get an overview of the default Suricate rules, you can download a big ruleset by running `suricata-oinkmaster-updater` that
> will downloads rules in `/etc/suricata/rules/*.rules`.

The instance of Suricata installed on the router only listens to the traffic (IDS mode, not IPS). Other configurations allows Suricata
to catch the traffic :

* `cp /lib/systemd/system/suricata.service  /etc/systemd/system/suricata.service`
* Replace `--af-packet` by `-q0` in `/etc/systemd/system/suricata.service`
* Reload systemd `systemctl daemon-reload`
* Use `drop` instead of `alert` in the rules
* `service suricata restart`

To enable the paquets treatment by Suricata, you need to add a NFQUEUE target instead of ACCEPT in the `iptables` rules. To route all
the forwarded traffic in Suricata, you have to do this :
`iptables -I FORWARD -j NFQUEUE` (be careful, Suricata's decisions are definitve, the other rules are not eveluated. [Some more advanced
module exists](https://docs.mirantis.com/mcp/latest/mcp-security-best-practices/use-cases/idps-vnf/ips-mode/nfq.html))

Download once again the _packed_ malware and notice you are gettint a _timeout_.

HIDS Installation (bonus)
=========================

OSSEC is a HIDS pre-installed on "target-dmz". It allows to monitor the logs, the filesystem, configurations, ... The configuration can
be found in `/var/ossec/etc/ossec.conf`.

The alerts are in `/var/ossec/logs/alerts/alerts.log`. Each alert refers to a rule ID that allow to link the alert to the original rule.
The rules can be found in `/var/ossec/rules/*.xml`.

### syscheck
The `syscheck` module watches the filesystem and detects file modifications and creations (not activated by default). It is configured
in the `<syscheck>` section of `/var/ossec/etc/ossec.conf`. The [documenation](https://ossec.github.io/docs/manual/syscheck/index.html)
and the [FAQ](https://www.ossec.net/docs/faq/syscheck.html#why-aren-t-new-files-creating-an-alert) can be interesting to read.

On "target-dmz" the uploaded files are stored in `/var/lib/dokuwiki/data/media`. Configure a rule in OSSEC (an option and a rule) to
get an alert each time a new file is uploaded on the wiki.

Caution:
* the rule has to be added in a `<group>` (in `/var/ossec/rules/local_rules.xml`)
* `syscheck` relies on regular scans (very slow not to impact the system) and compare the result with the previous scans. Scans can take
  a lot of time then. You can follow the scan in `/var/ossec/logs/ossec.log`
  * scan starts : "INFO: Starting syscheck database (pre-scan)."
  * scan ends (can take few minutes !) : "INFO: Finished creating syscheck database (pre-scan completed)."
* since the process is long, reduce the amount of folders to monitor (disable default folders, add only the dokuwiki folder).

Add a file in the monitored folder to emulate the scenario.

Instead of waiting a scan, you can force a system scan with `/var/ossec/bin/agent_control -r -u 000`, but it still take time since
several minutes between two scans is required.

### Logs
You can also check to the logs : [doc](https://ossec.github.io/docs/manual/monitoring/index.html)

From "isp-a-hacker" (user "debian), run a bruteforce on the wiki administrator's password by running `python3 tp/intrusion/dokuwiki.py www.target.milxc`.
Look at the OSSEC alerts.
