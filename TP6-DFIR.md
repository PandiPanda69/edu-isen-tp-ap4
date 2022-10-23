# TP4 - Digital Forensics & Incident Response

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

Durée: 4 hours

Setup The Environment
=====================

This exercice won't rely on [MI-LXC](https://github.com/flesueur/mi-lxc). But before starting, make sure you have the following
requirements:
- A software to read `pcap` files (`tcpdump`, _Wireshark_, ... note that _Wireshark_ is strongly recommanded) ;
- A text editor
- A spreadsheet editor (Excel, Open Office, ...)
- What you learnt during the module ;

This exercise expects a group of 4 students to send a report explaining how you got the result. Do not lose any minute, you have to
send the report at the end of the allocated time. The best strategy is to split the work to address simultaneously both *Forensics*
and *Action Plan* parts.

Good luck & have fun.

Timing
======

In order to help you manage your time, a duration estimation is given for each subpart.

Scenario
========

You are a consultant working in a commercial CERT (_Computer Emergency Response Team_). Your company has been requested by the "Target"
company after they discovered a strange behavior on the laptop of the system administrator. They don't have much more information yet.

Your mission is to make the security incident response in order to:
- Investigate and determine how the company "Target" got compromised ;
- Try to understand what was the goal of the adversary and what has been done ;
- Recover materials that may help identify who is the adversary ;
- Analyze the configuration in place during the attack and propose an action plan to improve the resiliency of the "Target" company
  regarding such attacks.
  
__You are a security expert. As you may know, you should NEVER execute any unknown binary on your computer.__
  
Investigations
==============

_Estimated Duration: 3 hours_

By chance, a network capture is available. The system administrator forgot he has a terminal open with a running `tcpdump` on his
laptop for days.
Another analyst in your team has isolated 500 packets that seems to be interesting and your skills are now required to analyze the
content of the capture. This is the only exploitable trace. The file is using the pcap format and it can be downloaded
[here](https://github.com/PandiPanda69/edu-insa-srs/raw/main/capture.pcap).

The technical team of the "Target" company provided you the network architecture to help you investigate the packet capture.
The packet capture has been done on the system administrator laptop.

| Device            | Description                                         | IP     |
| :-------:         | -----------                                         | :-----: 
| target-router     | Router                                              | Pub: 100.64.0.10 / Priv: 10.87.0.1 |
| target-admin      | System administrator laptop                         | 10.87.0.4 |
| target-commercial | Commercial laptop                                   | 10.87.0.2 |
| target-dev        | Developer laptop                                    | 10.87.0.3 |
| target-dmz        | Company DMZ server hosting a website and email service | 10.87.1.2 |
| target-ldap       | Company LDAP                                        | 10.87.0.10 |
| target-filer      | Internal file share server                          | 10.87.0.6 |
| target-intranet   | Intranet web server                                 | 10.87.0.5 |

> In order to help analyze the capture, you can apply a filter to hide packets that are not relevant. Here is an example that could
> help reduce the amount of packets to analyze by removing both ARP and IPv6: `!arp && ip.version == 4`. 
> Feel free to use filters to help you to find what you are looking for. You can easily filter on protocols, i.e. HTTP protocol with
> `!arp && ip.version == 4 && http` or `!arp && ip.version == 4 && dns` for DNS.
> You can also use the "Follow" feature (right click in the graphical interface on a packet) to have all the related communications
> reassembled in a single window.

> TCP packet type reminder:
> - The _3-way handshake_ established a connection (`SYN`,  `SYNACK`, `ACK`).
> - Data are pushed with `PSH` packets and an acknowledgement `ACK` is sent each time it has been properly received.
> - Connection ends when a `FIN` packet is received or, in case of an issue, when received a `RST` packet.

> __To answer the questions, note all the involved IPs, URLs, passwords and what could become an indicator of compromise afterwards.__

## Packets 8 &rarr; 37 (15min)

1. What is the protocol of the packet 8 ? What is it used for ?
2. Look at the packets 28 to 36. What is this ? What information can you extract from these different packets ?

## Packets 43 &rarr; 63 (45min)

3. What is the packet 43 ? What is the protocol ?
4. What kind of information about the behavior of the sysadmin does this packet bring to you ?
5. What is the reply to packet 43 ?
6. Look at the packets 53 to 63. What is this ? What does it mean ?
7. One of your colleague says the packet 58 is interesting. Recover the content of this packet. What is it ?
8. Explain each line of the content of the packet 58.
9. Decode the encoded content on line 5 and explain what it is supposed to do line by line.

> [Base64](https://en.wikipedia.org/wiki/Base64) encoding is a way to encode data. It is often used in order to obfuscate code and
> make it harder to read. To decode that kind of string, you can use the command `base64 -d` under Linux, `base64 -D` under Mac or 
> an online tool.

10. What is the line 3 of the decoded content ? Recover the clear content and explain how you proceed.
11. Explain line by line this new content.

## Packets 64 &rarr, 105 (15min)

12. Does the packet 64 confirms your analysis on question 11 ? What is it ?
13. What is the content of the packet 69 ? What is this ? To who this packet is sent ? Why ?
14. What is the packet 77 ? Who send this packet ? What is this ?
15. Look at the packet 87. Why is it interesting to send this packet ? What information is valuable ?

## Paquets 106 &rarr; 168 (10min)

16. Explain the packet 124. Why doing this ?
17. Explain what are the packets 129 to 163. 

## Packets 169 &rarr; 207 (10min)

18. Why sending the packet 186 ?
19. What is done in packet 204 ?

## Packets 208 &rarr; 250 (20min)

20. What is packet 208 ?
21. What is the packet 211 ? Are we going to be able to read the communication until now ?
22. In your opinion, why the connection succeed ?
23. What is the packet 243 ?
24. What about the packet 245 ? What is the reponse to this packet ? Explain what is happening from packet 245 to getting the response.

## Packets 251 &rarr; 310 (15min)

25. By inspecting the packets from 251 to 310, explain what kind of data the adversary was interested in.

## Packets 311 &rarr; 349 (15min)

26. By looking at the packets from 311 to 349, have you any indication of what the adversary may have done ?
27. Can you recover any content here ? Why ?

## Packets 350 &rarr; 371 (10min)

28. Both packets 350 and 362 look similar. Why ? Explain what is happening.

## Conclusions (25min)

It is time to report your findings to your customer.

29. Write the timeline of what happened and explain how the adversary succeed in getting into the systems of the company.
30. In such situation, it's still valuable to make sure no backdoor have been put by the adversary on any other system. In order to
    perform a large detection, provide all the IoC you may have identified in a table like this :
| #      | Indicators                          | Type       | Comment |
| :----: | -----------                         | :-----:    | :-----:
| 1      | 1.2.3.4                             | IP         | IP used for... |
| 2      | domain.fr                           | Domain     | Domain name hosting  ... |
| 3      | https://domain.fr/bad               | URL        | Malicious URL used for ... |
| 4      | 39e913e02b0940fea4359cc55d88d6ee    | Hash       | Hash of the malicious file doing ... |
| n      | ...                                 | ...        | ... |


Action Plan
===========

_Estimated Duration: 1 hour 30 minutes_

In order to avoid the "Target" company facing the same situation, you also have to provide recommandations about how the company can
improve its security. To build the action plan, all your cybersecurity knowledge are required as well as the results of the forensics.
A quick audit of the security of the company can also be helpful.

You can download a [zip file](https://github.com/PandiPanda69/edu-insa-srs/raw/main/annexes.zip) containing several `iptables`
configurations found on the network and a quick interview of the system administrator of the "Target" company performed by one of your
colleague.

> The network plan can be found [above](#investigations).

## First Statement (20min)

31. What do you think about the `iptables` configurations ?
32. When reading the interview, make a quick table to sum up the pros & cons. Evaluate the security maturity of the company.

## The Action Plan (70min)

The action plan is going to be presented to the board.

You are going to prepare this action plan with all the actions you think important to improve the company security. You'll have to
present it to the top management of the "Target" company. They would approve or not your plan depending on the relevance of your
proposals and the budget.

The table below shows you a quick example of what is expected (you can adapt it regarding your needs).

| Ref.  | Title                         | Objective                                            | Priority | Complexity | Security Imprvmt | Req. Man Days | Profile       |
| :--:  | ----------------------------- | ---------------------------------------------------- | :-------: | :-------: | :--------------: | :-----------: | :-----------: |
| SEC_R | Rework network architecture   | Imprive the security of the architecture.            | CRITICAL | HIGH       | IMPORTANT        |    N days     | Network expert |
| SEC_X | Deploy a security software    | The tool X is so nice to do security stuff.          | LOW      | LOW        | MEDIUM           |    K days.    | Sys. Admin.   |

33. Make a table of all the actions your think good to (1) trust back the network by cleaning all what need to be cleaned and (2) improve
    the security of the "Target" company with detection capabilities and hardening to avoid this situation happening again. Provide an
    indication of the impact of your measure on the security and how many time is required to implement it. 

34. In taking in consideration the financial elements shown below, make a quick quotation for your action plan (explain your figures).

35. Regroup your actions into batches and schedule how these batches should be implemented. The "Target" top management can then choose
    which batches they want to implement. For each batch, provide financial information.


> Average Daily Rate (ADR - _TJM in french_) : the cost of a resource for a single day.

| Type | € |
| --------- | :---: |
| ADR Dev. | 450€ |
| ADR Sysadmin. | 600€ |
| ADR Sale | 1000€ |
| ADR Network Expert | 600€ |
| ADR Project Manager | 600€ |
| ADR Architect | 800€ |
| ADR Penetration Tester | 1250€ |
| License Fees for Antivirus EDR | 30€ / user / month |
| Training for administrating a secure infrastructure | 6000€ |
| Appliance Cisco Firepower (NIDS Hardware) | 300000€ |
| NordVPN Subscription | 1€ with the code `VPN_ARE_VERY_S3CUR3D_OMG.` |
