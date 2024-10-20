# TP6 - Digital Forensics & Incident Response

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
company after their data got encrypted. It looks like a ransomware attack.

Your mission is to make the security incident response in order to:
- Investigate and determine how the company "Target" got compromised ;
- Try to understand what was the goal of the adversary and what has been done ;
- Recover the database of the company so they can get back to work ;
- Analyze the configuration in place during the attack and propose an action plan to improve the resiliency of the "Target" company
  regarding such attacks.
  
__You are a security expert. As you may know, you should NEVER execute any unknown binary on your computer.__
  
Investigations
==============

_Estimated Duration: 3 hours_

By chance, a network capture is available. The system administrator was debugging a network issue on the laptop of Jean-Michel and
ran a `tcpdump` which recorded unusual tings. Another analysts in your team have isolated the most interesting packets and your
skills are now required to analyze the content of the capture. This is the only exploitable trace. The file is using the pcap format
and it can be downloaded [here](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/ransom.pcap).

The technical team of the "Target" company provided you the network architecture to help you investigate the packet capture.
The packet capture has been done on the commercial laptop.

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

## Packets 1 &rarr; 24 (15min)

1. What is the protocol of the packet 1 ? What is it used for ?
2. Look at the packets 4 to 23. What is this ? What information can you extract from these different packets ?

## Packets 28 &rarr; 41 (45min)

3. What is the packet 28 ? What is the reply to packet 28 ?
4. What kind of information about the behavior of the commercial does this packet bring to you ?
5. What is the packet 33 ? What does it mean ?
6. One of your colleague says the packet 36 is interesting. Why ? What is the response ?
7. Recover the content of the reponse. What is it ?
8. Explain each line of the body of the response.
9. Decode the encoded content on line 5 and explain what it is supposed to do line by line.

> [Base64](https://en.wikipedia.org/wiki/Base64) encoding is a way to encode data. It is often used in order to obfuscate code and
> make it harder to read. To decode that kind of string, you can use the command `base64 -d` under Linux, `base64 -D` under Mac or 
> an online tool.

10. What is the line 3 of the decoded content ? Recover the clear content and explain how you proceed.
11. Explain line by line this new content.

## Packets 62 &rarr; 130 (20min)

12. Does the packet 62, 63 and 64 confirms your analysis on question 11 ? What mean these packets ?
13. What is the content of the packet 67 ? What is this ? To who this packet is sent ? Why ?
14. What is the packet 80 ? Who send this packet ? What is this ?
15. Look at the packet 100. What is the reply ? What does the reply display ?
16. Look at the packet 112. Why is it interesting to send this packet ? What information is valuable ?

## Paquets 130 &rarr; 186 (10min)

17. Explain the packet 133. Why doing this ? What is the reply ?
18. Explain the packet 142. What is the purpose of this packet ?
19. Explain what are the packets 147 to 186.

## Packets 192 &rarr; 298 (20min)

20. Explain the packet 192 (read the hint below). What is the reply and what does it mean ?

> `ssh-keygen` has a many usages as you may see in the documentation. This tool is indeed used to generate SSH keys but it can
> be used also to check the fingerprints of keys and many other purposes. When using `ssh-keygen -l -F <hostname>`, the tool
> will check if the hostname has been registered in the `known_hosts` file.

21. What means the packet 203 ? According to packet 241, is it a success ? Why ?

> `sshpass` is a tool that allows to emulate a real keyboard in order to enter a password. Indeed several commands such as `ssh`
> are requiring password to be entered with a real keyboard for security purposes. This tool helps bypass the security measures.

22. Could you explain what is happening by look at packet 203, 252 and 293 ?

## Packets 300 &rarr; 384 (20min)

23. Does the attempt succeed ? What is the good password ? How do you know ?
24. What is the packet 335? Are we going to be able to read the communication until now ?
25. Explain the packet 361 as well as the reply to this packet. What does it mean ?
26. Explain the packet 374. Did it work ? Give the packet that tells whether it worked or not.
27. In your opinion why did it work ?

## Packets 389 &rarr; 455 (20min)

28. By taking the example of packet 389 and 393, make a quick drawing to explain the network interactions involved.
29. What is happening at packet 409 ?
30. Why are there no more packets after packet 455 ?

## Conclusions (25min)

It is time to report your findings to your customer.

31. Write the timeline of what happened and explain how the adversary succeed in getting into the systems of the company.
32. In such situation, it's still valuable to make sure no backdoor have been put by the adversary on any other system. In order to
    perform a large detection, provide all the IoC you may have identified in a table like this :
    
| #      | Indicators                          | Type       | Comment |
| :----: | :-----------:                       | :-----:    | :-----: |
| 1      | 1.2.3.4                             | IP         | IP used for... |
| 2      | domain.fr                           | Domain     | Domain name hosting  ... |
| 3      | https://domain.fr/bad               | URL        | Malicious URL used for ... |
| 4      | 39e913e02b0940fea4359cc55d88d6ee    | Hash       | Hash of the malicious file doing ... |
| n      | ...                                 | ...        | ... |

Unlock the file
==============

_Estimated Duration: 30 minutes_

Your customer lost very critical files in the attack. These files have been encrypted obviously and maybe you could get a way to
recover the content of the files at some point. Both the ransom note and the encrypted file have been provided to you:
- [Ransom note](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/NOTE.txt)
- [Encrypted file](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/database.RECKD)

## Encryption analysis

33. By analyzing `database.RECKD` tell how the data got encrypted.
34. Can you tell whether this is a symmetric or asymmetric encryption ? How ?
35. Explain what you need to decrypt the data.

## Payment website

36. Inspect the website. What do you need to get access to the decryption key ?
37. In your previous missions you discovered criminals are not very good developers. Maybe some vulnerabilities could be exploited.
Try to find a vulnerability you can exploit to get access to the decryption key.
38. How many victims have been affected by the ransomware ?
39. How many victims paid the ransom ?
40. What is the decryption key ? What can you say about the decryption key ?

## Recover the content

41. What is the content of the encrypted file ?

Action Plan
===========

_Estimated Duration: 1 hour 30 minutes_

In order to avoid the "Target" company facing the same situation, you also have to provide recommandations about how the company can
improve its security. To build the action plan, all your cybersecurity knowledge are required as well as the results of the forensics.
A quick audit of the security of the company can also be helpful.

You can download a [zip file](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/annexes.zip) containing several `iptables`
configurations found on the network and a quick interview of the system administrator of the "Target" company performed by one of your
colleague.

> The network plan can be found [above](#investigations).

## First Statement (20min)

42. What do you think about the `iptables` configurations ?
43. When reading the interview, make a quick table to sum up the pros & cons. Evaluate the security maturity of the company.

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

44. Make a table of all the actions your think good to (1) trust back the network by cleaning all what need to be cleaned and (2) improve
    the security of the "Target" company with detection capabilities and hardening to avoid this situation happening again. Provide an
    indication of the impact of your measure on the security and how many time is required to implement it. 

45. In taking in consideration the financial elements shown below, make a quick quotation for your action plan (explain your figures).

46. Regroup your actions into batches and schedule how these batches should be implemented. The "Target" top management can then choose
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
