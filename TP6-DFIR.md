# TP6 - Digital Forensics & Incident Response

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

Durée: 4 heures

Préparation de l'environnement
==============================

Pour ce TP, contrairement aux précédents, nous n'utiliserons pas la plateforme [MI-LXC](https://github.com/flesueur/mi-lxc). Voici les outils dont vous aurez besoin:
- De quoi lire un fichier au format `pcap` (`tcpdump`, _Wireshark_, ... mais _Wireshark_ est vivement recommandé) ;
- Un éditeur de texte
- Un tableur (Excel, Open Office, ou autre ...)
- GPG (vous pouvez utiliser une machine virtuelle sous Linux, la plateforme _MI-LXC_ ou autre);
- Ce que vous aurez appris pendant les cours et les TPs ;

Ce TP représente l'évaluation finale du module. Un compte-rendu vous est demandé expliquant votre raisonnement et comment vous êtes parvenus au résultat. Ne perdez pas de temps, vous devrez rendre le compte-rendu à la fin du TP.

**Pour ce TP, vous conservez les mêmes groupes que lors des TP précédents.**

Bon courage.

Timing
======

Afin de vous aider à gérer votre temps, une estimation du temps à passer sur chaque question est indiquée.

Scénario
========

Vous êtes consultant. Votre société a été sollicitée par l'entreprise "Target" à la suite d'une cyberattaque qui a complètement paralysé leur infrastructure survenue dimanche 31 octobre au soir. D'après les premières informations récoltées, un _ransomware_ aurait été déployé pendant le week-end et toutes les données ont été chiffrées.

Vous avez été choisi pour procéder à la réponse à incident de sécurité, notamment pour:
- Investiguer et déterminer comment l'entreprise "Target" a pu être compromise ;
- Tenter de récupérer les données les plus critiques de l'entreprise "Target" si cela est possible ;
- Récolter les éléments permettant d'identifier les attaquants ;
- Analyser la configuration qui était en place lors de la cyberattaque et proposer un vaste plan d'action permettant de rendre l'entreprise "Target" plus résiliente à l'avenir face aux menaces cyber

Investigations
==============

_Durée estimée: 2 heures 15 minutes_

Par chance, il semblerait qu'une capture réseau de l'attaque soit disponible car un administrateur système avait laissé `tcpdump` tourner tout le week-end suite à un debug qu'il avait fait jeudi dernier. Elle devrait être téléchargeable [ici](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/capture.pcap) au format `pcap`.

Les équipes techniques de l'entreprise "Target" nous ont transmis l'architecture de leur réseau afin de mieux interpréter les traces réseau. D'ailleurs, il est précisé que la capture a été réalisée sur l'interface publique.

| Machine           | Description                                         | IP     |
| :-------:         | -----------                                         | :-----: 
| target-router     | Routeur                                             | Pub: 100.64.0.10 / Priv: 100.80.0.1 |
| target-admin      | Ordinateur de l'administrateur système              | 100.80.0.4 |
| target-commercial | Ordinateur du commercial                            | 100.80.0.2 |
| target-dev        | Ordinateur du développeur                           | 100.80.0.3 |
| target-dmz        | Serveur dans la DMZ, exposant notamment un extranet | 100.80.1.2 |
| target-ldap       | LDAP de l'entreprise                                | 100.80.0.10 |
| target-filer      | Serveur de stockage de l'entreprise                 | 100.80.0.6 |
| target-intranet   | Serveur web de l'intranet                           | 100.80.0.5 |

> Afin de faciliter la lecture de la capture, vous pouvez apppliquer un filtre pour masquer certains paquets qui ne nous serons pas utiles. Voici un exemple de filtre qui vous permettra de réduire un peu le nombre de paquets à analyser en éliminant l'ARP et l'IPv6 : `!arp && ip.version == 4`. N'hésitez pas à utiliser les filtres pour vous aider à trouver ce que vous cherchez (vous pouvez facilement filtrer sur les protocoles notamment en rajoutant `!arp && ip.version == 4 && http` pour HTTP ou encore `!arp && ip.version == 4 && dns` par exemple.
> Vous pouvez également utiliser la fonctionnalité de "Suivi" en faisant un clique droit dans l'interface graphique sur un paquet ce qui peut se

> Rappel des types de paquets TCP:
> - La connexion s'établit suite à un _handshake_ (`SYN`, `SYNACK`, `ACK`).
> - Les données sont échangées au travers de paquet `PSH` et un accusé de réception `ACK` est émis à chaque réception.
> - La connexion se termine correctement avec un paquet `FIN` ou suite à un problème avec un paquet `RST`.

> __Pour répondre aux questions, notez scrupuleusement toutes les IPs impliquées, les mots de passe que vous identifiez, ou autres moyens d'authentification.__


