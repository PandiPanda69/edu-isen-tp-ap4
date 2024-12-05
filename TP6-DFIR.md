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
- What you learnt during the module ;

This exercise expects a group of 5 students to send a report explaining how you got the results.

Good luck & have fun.

Timing
======

In order to help you manage your time, a duration estimation is given for each subpart.

Scenario
========

You are a consultant working for _TechMaster_, a commercial CERT (_Computer Emergency Response Team_). Your boss just sent you
an email to give you an important mission : be in charge of the incident response of the company _CandyRiver_.

Read carefully the email before going further: [the email](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/Mail.pdf)

Your boss just sent you a message on Signal:
```
The passphrase is: OoghaisiT7oap1queequis
```

The email came with [an attachment](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/MeetingNotes.pdf.asc) that you should also read carefully since there are valuable information in it.

__Warm up question:__
Why did your boss sent you this message ? Explain what you had to do to go through this.

Disclaimer
==========

__You are a security expert. As you may know, you should NEVER execute any unknown binary on your computer.__
  
Before starting...
==================

1. Identify in your group the role of the different people and what each of you is going to do:
- the coordinator (aka the person who received the email from the boss)
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

When the NIDS detected the bad behavior, a full network capture has been automatically triggered. You can download the [pcap file](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/capture.pcap) now in order to start investigating. The questions will try to guide you in the process so don't be too fast, you may miss important things.

> In order to help analyze the capture, you can apply a filter to hide packets that are not relevant. Here is an example that could
> help reduce the amount of packets to analyze by removing both ARP and IPv6: `!arp && ip.version == 4`. 
> Feel free to use filters to help you to find what you are looking for. You can easily filter on protocols, i.e. HTTP protocol with
> `!arp && ip.version == 4 && http` or `!arp && ip.version == 4 && dns` for DNS.
> You can also use the "Follow" feature (right click in the graphical interface on a packet) to have all the related communications
> reassembled in a single window.

> __To answer the questions, the report manager should note all the involved IPs, URLs, passwords and what could become an indicator of compromise afterwards.__

## Packets 1 &rarr; 22

5. What are the packets 1, 2, 3 corresponding to ?
6. Considering packet 4 and packet 6, what caused the NIDS to trigger an alert ? Still by considering these 2 packets, is the attack successful ?
7. Describe what happened in packets 14 and 16. Does it work ? Describe the content of the packet 14.
8. What happened in packet 18 ? Considering the description you made of the packet 14 previously, could you explain what is going on ?
9. Confirm your explanation by describing packets 21 and 22. What is the point to do so ?

## Packets 30 &rarr; 32

10. What happens in packet 30 ? What kind of information the packet 32 gives ?
11. Explain why the adversary did this.
12. By dissecting the packet 30, extract the name and the content of the file.

> [Base64](https://en.wikipedia.org/wiki/Base64) encoding is a way to encode data. It is often used in order to obfuscate code and
> make it harder to read. To decode that kind of string, you can use the command `base64 -d` under Linux, `base64 -D` under Mac or 
> an online tool.

13. Try to decode the content of the file. What is the result ?
14. Comment **each** line of the result you got.
15. Try to decode the content of line 3 and comment **each** line of the result you got.

## Packets 40 &rarr; 55

16. What can you observe on packets 44 and 45? How is it connected to packet 30?
17. What does the packet 55 means?

## Packets 57 &rarr; 75

18. What are the packets 57, 58 and 59 and how they are linked to the previous questions?
19. Describe what could be the packet 64.
20. According to the question 19, what does mean the packet 68 and what is the reply to this packet?

## Packets 76 &rarr; 150

21. What means the packet 82? Why doing this?
22. Confirm your analysis by looking at the packet 113. What is this and explain what kind of valuable information the reply provides?

_One of your colleagues - a network expert - came to check if you were ok since you were working on something very important. He looked on your screen while you were displaying the packet 113 then told you :_
>_"Have you seen there are no SYN packet? What kind of network architecture this customer setup ?!"_

23. By considering the remark of your colleague, could you explain what he meant by _no SYN packets_ and what kind of information it gives about the network architecture ?

## Packets 152 &rarr; 270

>`sshpass` is a tool that allows to emulate a real keyboard in order to enter a password. Indeed several commands such as `ssh`
> are requiring password to be entered with a real keyboard for security purposes. This tool helps bypass the security measures.

24. Explain the packet 156. What is the reply?
25. How many time can you see the same behaviour? What is the name of this behaviour?
26. What kind of information the packet 270 gives you?

## Packets 274 &rarr; 322

27. What is packet 274 and which packet does contains the reply?
28. Make a quick diagram to explain the network interactions involved between the packet 274 and its reply. (a diagram please)
29. Once you have done a **diagram** on the previous question, list the different command you can recover until packet 321 and explain what is the purpose of **each** of them.
30. What does the packet 321 mean? Is it an issue for the adversary?

## Packets 327 &rarr; 335

31. Explain the packet 327. What's the goal to do this? Is it helpful for the adversary? Why? (you can look at the packet 328)
32. What kind of information the packets 334 and 335 provides? What can you say about this user?

## Packets 341 &rarr; 966

33. The packet 341 provides an important information. Explain what it means including the next packets up to 413.
34. Does the packet 415 confirm your previous analysis? Why?
35. Improve the diagram you made for question 28 and explain in this diagram why we can see this packet 415. (provide a **diagram**)
36. Recover all the data you can to be able to provide proofs to your customer (don't attach it in the report if it is too big).
37. What are the packets 954 and 957? Do they do the same thing?

## Conclusions

38. Are you able to tell whether the tools used by the adversary are already known by the security community ? Tell how you proceed.
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

_Estimated Duration: 2 hours_

The meeting with the CISO provided a lot of valuable information you can start with to draft a remediation plan. The investigations will also provide a lot of valuable information on what happened and what you can do in order to secure the infrastructure and make sure this situation never happens again.

## First Statement (20min)

43. What do you think about the security of _CandyRiver_ ? Make a quick table to sum up the pros & cons and evaluate the security maturity of the company.

## The Plan (100min)

The remediation plan is going to be presented to the board of your customer by the incident coordinator. This is a very important document and we need to be pro to quote the boss.

You are going to prepare this remediation plan with all the actions you think important to improve the company security. The board may
approve or not your plan depending on the relevance of your proposals and the budget. Even if they are not technical, they can easily
challenge your propositions so be sure to provide enough information to help them in their decision.

The _CandyRiver_ company is employing 125 people approximatly in France and the Netherlands. The revenue in 2023 of the company was 26M€ and they expect a growth of 5% of their revenue for 2024. The EBITDA is around 6% with 7M€.

The table below shows you a quick example of what is expected (you can adapt it regarding your needs).

| Ref.  | Title                         | Objective                                            | Priority | Complexity | Security Imprvmt | Req. Man Days | Profile       |
| :--:  | ----------------------------- | ---------------------------------------------------- | :-------: | :-------: | :--------------: | :-----------: | :-----------: |
| SEC_R | Rework network architecture   | Imprive the security of the architecture.            | CRITICAL | HIGH       | IMPORTANT        |    N days     | Network expert |
| SEC_X | Deploy a security software    | The tool X is so nice to do security stuff.          | LOW      | LOW        | MEDIUM           |    K days.    | Sys. Admin.   |

44. Make a table of all the actions your think good to (1) trust back the network by cleaning all what need to be cleaned and (2) improve
    the security of the company with detection capabilities and hardening to avoid this situation happening again. Provide an
    indication of the impact of your measure on the security and how many time is required to implement it. 

45. In taking in consideration the financial elements shown below, make a quick quotation for your action plan (explain your figures).

46. Regroup your actions into batches and schedule how these batches should be implemented. The top management can then choose
    which batches they want to implement. For each batch, provide financial information.


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
| Appliance Cisco Firepower | 300000€ |
| NordVPN Subscription | 1€ with the code `VPN_ARE_VERY_S3CUR3D_OMG.` |
