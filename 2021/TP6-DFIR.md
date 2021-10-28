# TP6 - Digital Forensics & Incident Response

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

Durée: 4 heures

Préparation de l'environnement
==============================

Pour ce TP, contrairement aux précédents, nous n'utiliserons pas la plateforme [MI-LXC](https://github.com/flesueur/mi-lxc). Voici les outils dont vous aurez besoin:
- De quoi lire un fichier au format `pcap` (`tcpdump`, _Wireshark_, ... mais _Wireshark_ est vivement recommandé) ;
- GPG ;
- Keepass ;
- Ce que vous aurez appris pendant les cours et les TPs ;

Ce TP représente l'évaluation finale du module, un compte-rendu vous est demandé expliquant votre raisonnement et comment vous êtes parvenus au résultat. Ne perdez pas de temps, vous devrez rendre le compte-rendu à la fin du TP.

Bon courage.

Timing
======

Afin de vous aider à gérer votre temps, une estimation du temps à passer sur chaque question est indiquée.

Scénario
========

Vous êtes consultant. Votre société a été sollicitée par l'entreprise "target" à la suite d'une cyberattaque qui a complètement paralysé leur infrastructure survenue dimanche soir. D'après les premières informations récoltées, un _ransomware_ aurait été déployé pendant le week-end et toutes les données ont été chiffrées.

Vous avez été choisi pour procéder à la réponse à incident de sécurité, notamment pour:
- Identifier comment les cybervilains ont réussi à s'introduire sur le système : quelles vulnérabilités ont été utilisées ? quelles étaient les adresses IPs impliquées dans la cyberattaque afin d'alimenter le dépôt de plainte ? quelle est la timeline avec les différents évènements que vous arrivez à tracer ? etc.
- Tenter de récupérer les données les plus critiques de l'entreprise "target" si cela est possible
- Analyser la configuration qui était en place lors de la cyberattaque et proposer un vaste plan d'action permettant de rendre l'entreprise "target" plus résiliente à l'avenir face aux menaces cyber

Identification de l'origine de l'attaque
========================================

_Durée estimée: 2 heures 15 minutes_

Par chance, il semblerait qu'une capture réseau de l'attaque soit disponible car un adiministrateur système avait laissé `tcpdump` tourner tout le week-end suite à un debug qu'il avait fait jeudi dernier. Elle devrait être téléchargeable [ici](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/2021/capture.pcap) au format `pcap`.

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
> - Les données sont échangés au travers de paquet `PSH` et un accusé de réception `ACK` est émis à chaque réception.
> - La connexion se termine correctement avec un paquet `FIN` ou suite à un problème avec un paquet `RST`.

> __Pour répondre aux questions, notez scrupuleusement toutes les IPs impliquées, les mots de passe que vous identifiez, ou autres moyens d'authentification.__

## Paquets de 1 à 520 (15min)

1. Quel comportement pouvous-nous observer ?
2. Est-ce que cela débouche sur un évènement intéressant ? Si oui, pouvez-vous le décrire ?

## Paquets de 521 à 552 (5min)

3. Décrivez le trafic que vous observez.
4. Est-ce qu'il y a un lien avec ce que vous avez observé précédemment ?
5. Est-ce que quelque chose semble différer ?

## Le paquet 821 (15min)

Les paquets 821 et 823 ont attiré l'attention des experts avec qui vous travaillez. En effet, la requête HTTP POST est volumineuse ce qui traduit un comportement intriguant. 

6. Prenez un peu de temps pour expliquer à quoi correspond le paquet 821 et en quoi il se révèle intéressant.

## Paquets 828 à 884 (15min)

7. Quel est le lien avec le paquet 821 ?
8. Pourriez-vous lister les actions que vous observez ?

## Le paquet 861 (25min)

Le paquet 861 suscite un vif intérêt pour les experts qui vous assistent.

9. Pourquoi un tel intérêt ?
10. Qu'est ce qu'il vous apprend ?

## Paquets 886 à 1078 (15min)

Ces communications ne sont pas conventionnelles et ne s'appuient vraisemblablement pas sur un protocole connu.

11. Pouvez-vous établir un lien entre ces communications et le paquet 861 ?
12. Quelle est la nature de ces communications ? Que pouvez-vous en conclure ?

## Paquets 1092 à 1110 (5min)

13. A quoi correspondent ces paquets ?
14. Pouvez-vous faire un lien avec les communications précédentes ?
15. Est-il possible de savoir ce qu'il se passe à partir de cet instant ?

## Paquets 1823 et 1829 (10min)

16. A quoi correspondent ces 2 paquets ?
17. Est-ce normal de trouver ces 2 paquets un dimanche soir alors qu'aucun salarié n'est au bureau ? Pourquoi ?

## Paquets 1908 et 1910 vs 2381 et 2383 (15min)

18. Est-il possible de faire un parallèle entre ces paquets et les 2 paquets analysés précédemment ?
19. D'où sont émis les paquets ?
20. Quelles différences notez-vous entre les 2 premiers et les 2 suivants ?
21. A quoi correspond le paquet 2383 ? Essayez d'extrapoler à quoi cela peut bien servir.


> Historiquement, l'authentification web utilisait un mécanisme connu sous le nom de _Basic Auth_, ou plus précisément l'emploi de l'entête [`Authorization`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication). Les identifiants sont alors transmis en étant encodés en `base64`.

## Conclusion (15min)

22. Pour conclure vos observations, retracez la chronologie des évènements sous la forme d'un tableau telle que celui-ci:

| #      | Action                              | Source     | Cible |
| :----: | -----------                         | :-----:    | :-----:
| 1      | Un scan de port est effectué.       | IP X.X.X.X | Machine Y.Y.Y.Y |
| 2      | La vulnérabilité  X est exploitée.  | IP X.X.X.X | Machine Y.Y.Y.Y |
| n      | ...                                 | ...        | ... |

23. Quelle(s) serai(en)t la/les IP(s) utilisée(s) par l'attaquant ?
24. Notez les mots de passe et autres moyens d'authentification récupérés.
25. (bonus) Connaissez-vous l'identité précise de l'attaquant ?


Récupération des données
========================

_Durée estimée: 30 minutes_

L'entreprise "Target" est en grande difficulté car un fichier qui était présent sur le poste du commercial était d'une importance capitale. Malheureusement, il est dorénavant chiffré. Afin de ne pas payer la rançon, l'entreprise "Target" s'en remet à vous et vous demande s'il est possible de récupérer le fichier original.

Le fichier en question se trouve [ici](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/2021/fichier_client.csv.CRYPTED). (SHA1: 75e3bfbcd7f5b79bc4c0d07a86dab0ce2be4e31e)

## Analyse du moyen cryptographique employé (2min)

26. Que pouvez-vous dire de ce fichier de prime abord ?
27. En s'appuyant sur vos connaissances et la capture réseau précédemment analysée, que vous faut-il pour déchiffrer ce fichier ?

## Actionner les analyses

Lors des analyses précédentes, vous avez documenté un certains nombre d'actions. Notamment, vous avez du identifier une connexion à un site web distant afin de télécharger un fichier.

28. Connectez-vous au site web identifié précédemment. Quels sont les identifiants ? (2min)
29. Décrivez les 3 liens que vous voyez. (3min)
30. Qu'est-ce qu'un fichier `kdbx` ? Qu'avez-vous besoin pour l'ouvrir ? (3min)
31. Trouvez l'email de l'attaquant en exploitant les 3 liens mis à disposition. (10min)
32. Que contient le second lien ? (5min)

## Déchiffrement

33. Indiquez le résultat obtenu une fois le fichier déchiffré. (5min)

Plan d'action
==============

_Durée estimée: 1 heure 15 minutes_

Afin que l'entreprise "Target" ne revive pas cette situation, votre mission est également de leur suggérer des préconisations afin de renforcer la sécurité de leurs systèmes. Pour effectuer ces recommandations, vous allez devoir mobiliser vos connaissances, les analyses que vous avez pu mener, mais aussi faire un rapide audit de la configuration existante.

Une archive au format zip se trouve [ici](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/2021/annexes.zip). Elle contient les différentes configurations `iptables` des machines du réseau, et un fichier retranscrivant un court interview de l'administrateur système de l'entreprise "Target" avec votre collègue architecte sécurité.

> Vous pouvez retrouver le plan d'adressage [plus haut](#identification-de-lorigine-de-lattaque).

## Le premier bilan (15min)

34. Quel(s) commentaire(s) pouvez-vous faire en regardant la configuration `iptables` actuelle ?
35. A la lecture de l'interview, notez les éléments qui vont semblent positifs, et les éléments négatifs. Faites une appréciation globale du niveau de maturité de l'entreprise sur l'aspect sécurité de l'information.

## Le plan d'action (1h)

Un plan d'action a pour vocation d'être présenté aux décisionnaires. Vous allez donc devoir préparer un plan d'action que vous présenterez aux responsables de l'entreprise "Target" afin qu'ils valident, ou non, les mesures que vous recommandez.

37. À partir de toutes ces informations, faites une recommandation sur l'architecture du réseau qui devrait être mise en place par l'entreprise "Target".
38. En vous inspirant du tableau présenté ci-dessous (vous pouvez l'adaptez à vos besoins), listez les actions que vous recommanderiez de mettre en place, évaluez (à la louche) le temps d'implémentation, ainsi que le gain en sécurité. L'objectif est de (1) retrouver confiance dans le système actuel en nettoyant ce qui doit être nettoyé et (2) donner la capacité à l'entreprise "Target" de détecter plus rapidement et/ou d'empêcher ce type d'attaque à l'avenir.

| Réf.  | Titre                         | Objectifs                                                | Priorité | Complexité d'implém. | Gain en sécurité | Jrs/H estimés | Profil        |
| :--:  | ----------------------------- | -------------------------------------------------------- | :-------: | :------------------: | :--------------: | :-----------: | :-----------: |
| SEC_R | Revoir l'architecture réseau  | Mettre en place une architecture réseau plus sécurisée.  | CRITIQUE | ELEVEE               | IMPORTANT        |    N jours    | Expert réseau |
| SEC_X | Déployer un outil de sécurité | L'outil X est vraiment génial pour faire de la sécurité. | MOYEN | FAIBLE               | MOYEN            |    K jours    | Admin. Sys.   |

39. En prenant un compte les éléments financiers présentés dans le tableau suivant, déterminez le coût financier approximatif de l'attaque pour l'entreprise "Target". Puis déterminez le coup de la mise en place des recommandations que vous préconisez (en détaillant vos calculs).

| Type | € |
| --------- | :---: |
| Durée pendant laquelle "Target" n'a pas pu fonctionner jusqu'à maintenant | 4 jours |
| Durée restante avant que "Target" ne retrouve un fonctionnement normal | à vous de l'estimer |
| Perte de chiffre d'affaire estimée par jour | 20k€ |
| Estimation coût masse salariale de "Target" par jour | 4k€ |
| Tarif Journalier Moyen Dev. | 450€ |
| Tarif Journalier Moyen Admin. Sys. | 600€ |
| Tarif Journalier Moyen Commercial | 1000€ |
| Tarif Journalier Moyen Expert Réseau | 600€ |
| Tarif Journalier Moyen Chef de Projet | 600€ |
| Tarif Journalier Moyen Architecte | 1000€ |
| Tarif Journalier Moyen Pentesteur | 1250€ |
| Abonnement NordVPN | 1€ avec le code promo `ProtonVPN` |



40. Proposez une implémentation des recommandations de votre tableau en _lot_ en développant une ébauche de calendrier que vous pourriez communiquer à l'entreprise "Target" avec, le coût associé à chaque lot. Exemple: _Lot 1 - Sécurisation du système, en commençant maintenant, fin estimée du chantier en juin 2024_, etc...
