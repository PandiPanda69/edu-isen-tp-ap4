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

Scénario
========

Vous êtes consultant. Votre société a été sollicitée par l'entreprise "target" à la suite d'une cyberattaque qui a complètement paralysé leur infrastructure survenue dimanche soir. D'après les premières informations récoltées, un _ransomware_ aurait été déployé pendant le week-end et toutes les données ont été chiffrées.

Vous avez été choisi pour procéder à la réponse à incident de sécurité, notamment pour:
- Identifier comment les cybervilains ont réussi à s'introduire sur le système : quelles vulnérabilités ont été utilisées ? quelles étaient les adresses IPs impliquées dans la cyberattaque afin d'alimenter le dépôt de plainte ? quelle est la timeline avec les différents évènements que vous arrivez à tracer ? etc.
- Tenter de récupérer les données les plus critiques de l'entreprise "target" si cela est possible
- Analyser la configuration qui était en place lors de la cyberattaque et proposer un vaste plan d'action permettant de rendre l'entreprise "target" plus résiliente à l'avenir face aux menaces cyber

Identification de l'origine de l'attaque
========================================

_Durée estimée: 2 heures_

Par chance, il semblerait qu'une capture réseau de l'attaque soit disponible. Elle devrait vous avoir été remise au format `pcap`.

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

1. Expliquez succintement l'intérêt de savoir que la capture a été réalisée sur l'interface publique.

> Pour répondre aux questions, notez scrupuleusement toutes les IPs impliquées, les mots de passe que vous identifiez, ou autres moyens d'authentification.

## Paquets de 1 à 520

2. Quel comportement pouvous-nous observer ?
3. Est-ce que cela débouche sur un évènement intéressant ? Si oui, pouvez-vous le décrire ?

## Paquets de 521 à 552

4. Décrivez le trafic que vous observez.
5. Est-ce qu'il y a un lien avec ce que vous avez observé précédemment ?
6. Est-ce que quelque chose semble différer ?

## Le paquet 821

Les paquets 821 et 823 ont attiré l'attention des experts avec qui vous travaillez. En effet, la requête HTTP POST est volumineuse ce qui traduit un comportement intriguant. 

7. Prenez un peu de temps pour expliquer à quoi correspond le paquet 821 et en quoi il se révèle intéressant.

## Paquets 828 à 884

8. Quel est le lien avec le paquet 821 ?
9. Pourriez-vous lister les actions que vous observez ?

## Le paquet 861

Le paquet 861 suscite un vif intérêt pour les experts qui vous assistent.

10. Pourquoi un tel intérêt ?
11. Qu'est ce qu'il vous apprend ?

## Paquets 886 à 1078

Ces communications ne sont pas conventionnelles et ne s'appuient vraisemblablement pas sur un protocole connu.

12. Pouvez-vous établir un lien entre ces communications et le paquet 861 ?
13. Quelle est la nature de ces communications ? Que pouvez-vous en conclure ?

## Paquets 1092 à 1110

14. A quoi correspondent ces paquets ?
15. Pouvez-vous faire un lien avec les communications précédentes ?
16. Est-il possible de savoir ce qu'il se passe à partir de cet instant ?

## Paquets 1823 et 1829

17. A quoi correspondent ces 2 paquets ?
18. Est-ce normal de trouver ces 2 paquets un dimanche soir alors qu'aucun salarié n'est au bureau ? Pourquoi ?

## Paquets 1908 et 1910 vs 2381 et 2383

19. Est-il possible de faire un parallèle entre ces paquets et les 2 paquets analysés précédemment ?
20. D'où sont émis les paquets ?
21. Quelles différences notez-vous entre les 2 premiers et les 2 suivants ?
22. A quoi correspond le paquet 2383 ? Essayez d'extrapoler à quoi cela peut bien servir.


> Cette [ressource](https://en.wikipedia.org/wiki/Basic_access_authentication) vous sera d'une aide précieuse.

## Conclusion

23. Pour conclure vos observations, retracez la chronologie des évènements sous la forme d'un tableau telle que celui-ci:

| #      | Action                              | Source     | Cible |
| :----: | -----------                         | :-----:    | :-----:
| 1      | Un scan de port est effectué.       | IP X.X.X.X | Machine Y.Y.Y.Y |
| 2      | La vulnérabilité  X est exploitée.  | IP X.X.X.X | Machine Y.Y.Y.Y |
| n      | ...                                 | ...        | ... |

24. Quelle(s) serai(en)t la/les IP(s) utilisée(s) par l'attaquant ?
25. Notez les mots de passe et autres moyens d'authentification récupérés.


Récupération des données
========================

_Durée estimée: 30 minutes_

L'entreprise "Target" est en grande difficulté car un fichier qui était présent sur le poste du commercial était d'une importance capitale. Malheureusement, il est dorénavant chiffré. Afin de ne pas payer la rançon, l'entreprise "Target" s'en remet à vous et vous demande s'il est possible de récupérer le fichier original.

Plan d'action
==============

_Durée estimée: 1 heure 15 minutes_
