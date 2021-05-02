# TP6 - Digital Forensics & Incident Response

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

Durée: 4 heures

Préparation de l'environnement
==============================

Pour ce TP, contrairement aux précédents, nous n'utiliserons pas la plateforme [MI-LXC](https://github.com/flesueur/mi-lxc). Voici les outils dont vous aurez besoin:
- De quoi lire un fichier au format `pcap` (`tcpdump`, _Wireshark_, ...) ;
- GPG ;
- Keepass ;
- Ce que vous aurez appris pendant les cours et les TPs ;

Ce TP représente l'évaluation finale du module, un compte-rendu vous est demandé expliquant votre raisonnement et comment vous êtes parvenus au résultat.

Bon courage.

Scénario
========

Vous êtes consultant. Votre société a été sollicitée par l'entreprise "target" à la suite d'une cyberattaque qui a complètement paralysé leur infrastructure. D'après les premières informations récoltées, un _ransomware_ aurait été déployé pendant le week-end et toutes les données ont été chiffrées.

Vous avez été choisi pour procéder à la réponse à incident de sécurité, notamment pour:
- Identifier comment les cybervilains ont réussi à s'introduire sur le système : quelles vulnérabilités ont été utilisées ? quelles étaient les adresses IPs impliquées dans la cyberattaque afin d'alimenter le dépôt de plainte ? quelle est la timeline avec les différents évènements que vous arrivez à tracer ? etc.
- Tenter de récupérer les données les plus critiques de l'entreprise "target" si cela est possible
- Analyser la configuration qui était en place lors de la cyberattaque et proposer un vaste plan d'action permettant de rendre l'entreprise "target" plus résiliente à l'avenir face aux menaces cyber


Identification de l'origine de l'attaque
========================================

Par chance, il semblerait qu'une capture réseau de l'attaque soit disponible.

Récupération des données
========================

Plan d'action
==============

