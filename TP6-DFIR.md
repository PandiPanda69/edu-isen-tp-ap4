# TP6 - Digital Forensics & Incident Response

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

Durée: 4 hours

Setup The Environment
=====================

This exercice won't rely on [MI-LXC](https://github.com/flesueur/mi-lxc). But before starting, make sure you have the following
requirements:
- A software to read `pcap` files (`tcpdump`, _Wireshark_, ... note that _Wireshark_ is strongly recommended) ;
- A text editor
- A spreadsheet editor (Excel, Open Office, ...)
- A software to deal with `gpg`
- What you learnt during the module ;

This exercise expects a group of 5-6 students to send a report explaining how you got the results. The format of the report is `PDF` only.

Good luck & have fun.

Timing
======

In order to help you manage your time, a duration estimation is given for each subpart.

Scenario
========

You are a consultant working for _TechMaster_, a commercial CERT (_Computer Emergency Response Team_). Your boss just sent you
an email to give you an important mission : be in charge of the incident response of the company _CandyRiver_.

Read carefully the email before going further: [the email](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/Mail.pdf)

The email came with [an attachment](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/MeetingNotes.pdf.gpg) that you should also read carefully since there are valuable information in it.

Disclaimer
==========

__You are a security expert. As you may know, you should NEVER execute any unknown binary on your computer.__
  
Before starting...
==================

1. Identify in your group the role of the different people and what each of you is going to do:
- the coordinator (aka the person who received the email from the boss and is coordinating both the investigations and the remediation plan)
- the report manager
- the security experts
- ...

2. Recall briefly what is an NIDS and what is a SIEM.

The work can be split between the different people of your group to be more efficient. During the [investigations](#investigations) performed by the experts, you can also work on the [remediation plan](#remediation-plan).

Investigations
==============

_Estimated Duration: 3 hours_

## Context of the alert

3. As explained, the alert has been triggered by a NIDS rule. The SOC team shared with you the rule. Explain what it is supposed to detect and why this alert is relevant.
```
alert tcp any any -> any any (msg: "Suspicious HTTP POST request"; flow:to_server; content:"POST"; http_method; content:"system($_"; http_client_body; classtype:web-application-attack; sid:283; rev:3;)
```

4. According to the meeting your boss had with the Chief Information Security Officer, where is deployed the NIDS ? Explain whether this is a good choice or not.

## Hands on

When the NIDS detected the bad behavior, a full network capture has been automatically triggered. You can download the [pcap file](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/capture.pcap.gpg) now in order to start investigating. The questions will try to guide you in the process so don't be too fast, you may miss important things.

The password to decrypt the file will be provided at the beggining of the course.

> In order to help analyze the capture, you can apply a filter to hide packets that are not relevant. Here is an example that could
> help reduce the amount of packets to analyze by removing both ARP and IPv6: `!arp && ip.version == 4`. 
> Feel free to use filters to help you to find what you are looking for. You can easily filter on protocols, i.e. HTTP protocol with
> `!arp && ip.version == 4 && http` or `!arp && ip.version == 4 && dns` for DNS.
> You can also use the "Follow" feature (right click in the graphical interface on a packet) to have all the related communications
> reassembled in a single window.

> __To answer the questions, the report manager should note all the involved IPs, URLs, passwords and what could become an indicator of compromise afterwards.__

### Packets 1 &rarr; 25

5. What are the packets 4, 5, 6 corresponding to ?
6. Considering packet 7 and packet 9, what caused the NIDS to trigger an alert ? Still by considering these 2 packets, is the attack successful ?
7. Describe what happened in packets 17 and 19. Does it work ? Describe the content of the packet 17.
8. What happened in packet 21 ? Considering the description you made of the packet 17 previously, could you explain what's going on ?
9. Confirm your explanation with the packets 24 and 25 and explain what is happening.

### Packets 37  &rarr; 64

10. Describe the packets 37 and 39 and the purpose of doing so.
11. By dissecting the packet 37, extract the name and the content of the file.

> [Base64](https://en.wikipedia.org/wiki/Base64) encoding is a way to encode data. It is often used in order to obfuscate code and
> make it harder to read. To decode that kind of string, you can use the command `base64 -d` under Linux, `base64 -D` under Mac or 
> an online tool.

13. Try to decode the content of the file. What is the result ?
14. Comment **each** line of the result you got.
15. Try to decode the content of line 3 and comment **each** line of the result you got.

16. By analyzing the packets 55 and 57, explain what changed compared to packet 24 and 25.
17. Explain what is happening in packet 63.

### Packets 65 &rarr; 78

18. Does the packet 65 confirm the analysis you made previously and is it related to packet 63 ?
19. Describe the packet 71.
20. Look at the packet 78. What is the adversary doing and why ? Which packets are returning the response ?
21. Look at the packet 102. What does it mean ? Is it linked with the packet 78 somehow ?

### Packets 143 &rarr; 180

23. Look at the packet 143. What did the adversary ? What is his/her next action and which packet is it ?
24. Look at the next packets and try to explain what found the adversary and how interesting it could be for him/her ? (don't go after packet 180)

### Packets 189 &rarr; 228

25. What the adversary is doing at packet 189 ? What can of information is he/she leveraging to do so ?
26. Analyze the packets 196, 200 and 201. Do you think the action succeed ? Explain why it did work or why it did not work.
27. Make a quick **diagram** to explain the network interactions involved between the packet 200 and its reply. **(a diagram please)**
28. Once you have done a **diagram** on the previous question, list the different command you can recover until packet 228 and explain what is the purpose of **each** of them.

### Packets 229 &rarr; 241

29. What is doing the adversary at packet 229 ? What is the reply ? Is it an issue for him/her ?
30. Look at packet 232 and 234. Explain the strategy the adversary is using.
31. What is the result of packet 234 and what do you learn from it ?
32. Explain why the packets 240 and 241 is a bad news ?

### Packets 243 &rarr; 282

33. The packet 243 provides an important information. Explain what it means including the next packets up to 277.
34. Does the packet 282 explain your analysis ? Why ?
35. Improve the diagram you made for question 28 and explain in this diagram why we can see this packet 282. (provide a **diagram**)

### Packets 284 &rarr; 806
	
36. Recover all the data you can to be able to provide proofs to your customer (don't attach it in the report if it is too big).
37. What are the packets 793 and 797? Do they do the same thing?

### Conclusions

38. What do you think about the network architecture of the victim? Take in consideration your observations in the action plan.
39. Write the timeline of what happened and explain how the adversary succeed in getting into the systems of the company.
40. In such situation, it's still valuable to make sure no backdoor have been put by the adversary on any other system. In order to
    perform a large detection, provide all the IoC you may have identified in a table like this :
    
| #      | Indicators                          | Type       | Comment |
| :----: | :-----------:                       | :-----:    | :-----: |
| 1      | 1.2.3.4                             | IP         | IP used for... |
| 2      | domain.fr                           | Domain     | Domain name hosting  ... |
| 3      | https://domain.fr/bad               | URL        | Malicious URL used for ... |
| 4      | 39e913e02b0940fea4359cc55d88d6ee    | Hash       | Hash of the malicious file doing ... |
| n      | ...                                 | ...        | ... |

Severity assessment
==================

_Estimated Duration: 30 minutes_

41. Given the data recovered in question 36, are you able to recover sensitive data? Explain how and give the information you have been able to recover at line 566.
42. Assess the severity of these information and detail what are the risks associated to this security incident as well as the legal implications.

Remediation Plan
================

_Estimated Duration: 3 hours_

>[!NOTE]
>Please avoid using IA tools for this assessment. The tools often produce inaccurate or misleading results for this kind of work expected here,
>and relying on them may lead to outcomes that won't meet our expectations. We strongly encourage you to think though the problems yourself :)

The meeting with the CISO provided a lot of valuable information you can start with to draft a remediation plan. The investigations will also provide a lot of valuable information on what happened and what you can do in order to secure the infrastructure and make sure this situation never happens again.

## First Statement (20min)

43. What do you think about the security of _CandyRiver_ ? Make a quick table to sum up the pros & cons and evaluate the security maturity of the company.

## The Plan (2h30)

The remediation plan is going to be presented to the board of your customer by the incident coordinator. This is a very important document and we need to be pro to quote the boss.

You are going to prepare this remediation plan with all the actions you think important to improve the company security. The board may
approve or not your plan depending on the relevance of your proposals and the budget. Even if they are not technical, they can easily
challenge your propositions so be sure to provide enough information to help them in their decision.

The _CandyRiver_ company is employing 640 people approximatly in France, the Netherlands, Belgium and Poland. The revenue in 2024 of the company was 180M€ and they expect a growth of 5% of their revenue for 2025. The EBITDA is around 12.5% with 19M€.

44. Make a first table of all the actions you think required to trust back the network of the company by cleaning all what need to be cleaned.
    The table below shows you a quick example of what is expected (you can adapt it regarding your needs).

| Ref.  | Title                         | Objective                                            | Priority | Complexity | Security Imprvmt | Req. Man Days | Profile       |
| :--:  | ----------------------------- | ---------------------------------------------------- | :-------: | :-------: | :--------------: | :-----------: | :-----------: |
| SEC_R | Rework network architecture   | Imprive the security of the architecture.            | CRITICAL | HIGH       | IMPORTANT        |    N days     | Network expert |
| SEC_X | Deploy a security software    | The tool X is so nice to do security stuff.          | LOW      | LOW        | MEDIUM           |    K days.    | Sys. Admin.   |

45. Make a second table with the short & long term actions to improve the security of the company with detection capabilities and
    hardening to avoid this situation happening again. Provide an indication of the impact of each of your measure on the security and how many
    time is required to implement it. 

46. In taking in consideration the financial elements shown below, upgrade the tables to have a quick overview of the cost to restore the
    trust in the network, then to make a quick quotation for your short & long term action plan (explain your figures).

47. Prepare a few slides in the format of an executive summary to support your presentation to _Candyriver_’s management.


> Average Daily Rate (ADR - _TJM in french_) : the cost of a resource for a single day.

| Type | € |
| --------- | :---: |
| ADR Dev. | 450€ |
| ADR Sysadmin. | 600€ |
| ADR Sale | 800€ |
| ADR Network Expert | 600€ |
| ADR Project Manager | 600€ |
| ADR Architect | 800€ |
| ADR Penetration Tester | 1250€ |
| License Fees for Antivirus EDR | 30€ / user / month |
| Training for administrating a secure infrastructure | 6000€ |
| Appliance Cisco Firepower (NIDS Hardware) | 300000€ |
| NordVPN Subscription | 1€ with the code `VPN_ARE_VERY_S3CUR3D_OMG.` |
