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

**Pour ce TP, vous conservez les mêmes groupes que lors des TP précédents. Il vous est fortement conseillé de vous répartir les tâches en 2 de façon à avoir un stream travaillant sur les investigations et un stream travaillant sur le plan d'action.**

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

_Durée estimée: 2 heures 35 minutes_

Par chance, il semblerait qu'une capture réseau de l'attaque soit disponible car un administrateur système avait laissé `tcpdump` tourner tout le week-end suite à un debug qu'il avait fait jeudi dernier. En effet, le commercial avait des problèmes réseaux et l'administrateur système avait lancer un `tcpdump` pour tenter d'identifier le problème. C'est la seule trace réseau à notre disposition et elle devrait être téléchargeable [ici](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/capture.pcap) au format `pcap`.

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
> Vous pouvez également utiliser la fonctionnalité de "Suivi" en faisant un clique droit dans l'interface graphique sur un paquet ce qui peut se réveler très utile pour avoir toutes les communications dans une seule fenêtre.

> Rappel des types de paquets TCP:
> - La connexion s'établit suite à un _handshake_ (`SYN`, `SYNACK`, `ACK`).
> - Les données sont échangées au travers de paquet `PSH` et un accusé de réception `ACK` est émis à chaque réception.
> - La connexion se termine correctement avec un paquet `FIN` ou suite à un problème avec un paquet `RST`.

> __Pour répondre aux questions, notez scrupuleusement toutes les IPs impliquées, les mots de passe que vous identifiez, ou autres moyens d'authentification.__

## Paquets 22 à 81 (10min)

1. A quoi correspondent les paquets 22, 23, 24 et 25 ? Pourquoi ce type de paquet est émis sur le réseau ?
2. Quel est le procotole identifié pour le paquet 45 ? A quoi sert ce protocole ?
3. Jetez un oeil aux paquets de 45 à 81. De quoi s'agit-il ? Pouvez-vous extraire une information importante de ces différents paquets ?

## Paquets 82 à 111 (20min)

4. A quoi correspondent les paquets 82 à 85 ? De quel protocole s'agit-il et que nous apprennent-ils ?
5. A quoi correspondent les paquets de 86 à 96 ? Quelle est cette adresse IP ? Quel est le contenu des échanges ?
6. Vos collègues semblent affirmer que le paquet 94 est très intéressant. Récupérez le contenu du paquet 94. De quoi s'agit-il ?
7. Expliquer dans le détail ce que fait le contenu du paquet 94 ?
8. Décodez le contenu et, de même, indiquez de quoi il s'agit et ce qui est supposé être fait.

> Le [Base64](https://fr.wikipedia.org/wiki/Base64) est un mécanisme pour encoder des données. Il est souvent utilisé pour obfusquer du code et le rendre plus difficile à analyser. Pour décoder ce type de chaîne, vous pouvez utiliser la commande `base64 -d` sous Linux, `base64 -D` sous Mac ou bien un outil en ligne.

9. Formulez une hypothèse qui expliquerait pourquoi la machine du commercial a effectué ces communications.

## Paquets 141 à 162 (15min)

10. Est-ce que le paquet 141 tend à confirmer vos analyses précédentes ? De quoi s'agit-il ?
11. Quel est le contenu du paquet 146 ? A quoi cela correspond ? A qui est-ce envoyé ? Pourquoi ?
12. A quoi correspond le paquet 154 ?
13. Quelle est la réponse au paquet 154 ? Donnez le numéro du paquet correspondant.

## Paquets 164 à 190 (5min)

14. En ignorant les paquets DNS de 179 à 182, expliquez les paquets de 164 à 190.

## Paquet 215 (5min)

15. Expliquez le paquet 215.

## Paquets 220 à 260 (10min)

16. A quoi correspondent ces paquets ? Détaillez le comportement en faisant le parallèle avec le paquet 215.
17. Pourquoi faire une telle action ? Quel type d'information cela permet-il d'obtenir ?

## Paquet 277 (5min)

18. Expliquez ce que fait le paquet 277 en vous aidant du commentaire ci-dessous.

> La commande `sshpass` permet de simuler un véritable clavier pour saisir un mot de passe. En effet, certaines commandes telles que `ssh` demandant de saisir des mots de passe, nécessitent d'avoir un véritable clavier attaché au terminal ce qui n'est pas possible dans les scripts.

## Paquets 287 à 315 (10min)

19. A quoi correspond le paquet 287 ? Quel est le lien avec le paquet 277 ?
20. En considérant le paquet 287, nous sera-t-il possible de voir ce qui se passe désormais ?
21. Que pensez-vous du paquet 315 ? Nous sera-t-il possible de voir la suite des échanges ? Pourquoi ?

## Paquets 323 à 328 (5min)

22. A quoi correspond le paquet 323 ?
23. Quel paquet vient en réponse au paquet 323 ? Qu'apprenons-nous ?

## Paquets 333 à 350 (5min)

24. Expliquez les échanges qui ont lieu entre les paquets 333 et 350.

## Paquet 378 à 393 (5min)

25. Décrivez ce que fait le paquet 378.
26. Voyons-nous des traces réseau témoignant de l'execution du paquet 378 ? Si oui, lesquelles ? Si non, pourquoi ?
27. Mettez de côté le contenu du paquet 378, nous l'examinerons plus tard.

## Paquets 394 à 411 (10min)

28. Analysez les paquets 394 à 401.
29. Comparez votre analyse avec celle que vous avez faites à la question 24. Quelles différences faites-vous ?
30. Emettez une supposition sur l'action supposée du paquet 378.

## Paquets 412 et 424 (10min)

31. A quoi correspond le paquet 412 ?
32. En regardant les paquets de 413 à 423, confirmez votre analyse.
33. A quoi correspond le paquet 424 ?

## Retour sur le paquet 378 (20min)

Maintenant que toute la capture réseau a été analysée, nous pouvons nous pencher d'un peu plus près sur le paquet 378. Nous allons tenter de confirmer (ou pas) la supposition émise à la question 30.

34. Est-ce que la ressource est toujours disponible ? Comment le savez-vous ?

> Dans la réalité, les analystes évitent d'exécuter ou de manipuler des éléments potentiellement malveillants sur leur poste de travail. Veillez donc à être vigilents au cas où...

35. Téléchargez cette ressource sur votre ordinateur. De quel type de fichier s'agit-il ?
36. Ouvrez ce fichier avec un éditeur de texte. Expliquez ce que fait la ligne 3. (Le commentaire de la question 8 peut vous être utile)
37. Décodez dans un fichier les données encodées. Quel type de fichier obtenez-vous ?
38. Détaillez chaque ligne du fichier obtenu.

## Conclusions (20min)

Il est l'heure de fournir les conclusions de votre analyse de la capture réseau.

39. En rassemblant les réponses aux questions précédentes, détaillez la chronologie des faits en expliquant comment l'attaquant a fait pour s'introduire dans les systèmes jusqu'au chiffrement des données.
40. Récapitulez les différents _indicateurs de compromission_ que vous avez pu identifier lors de vos investigations. Voici un exemple de tableau vous montrant ce qui est attendu :

| #      | Indicateurs                         | Type.      | Commentaire |
| :----: | -----------                         | :-----:    | :-----:
| 1      | 1.2.3.4                             | IP         | IP de l'attaquant |
| 2      | domaine.fr                          | Domaine    | Nom de domaine hébergeant  ... |
| 3      | https://domaine.fr/bad              | URL        | URL malveillante qui fait ... |
| 4      | 39e913e02b0940fea4359cc55d88d6ee    | Hash       | Hash du fichier malveillant qui fait ... |
| n      | ...                                 | ...        | ... |


Récupération des données
========================

_Durée estimée: 30min_

Nous allons à présent tenter de récupérer les données de l'entreprise "Target". Le fichier [suivant](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/database.CRYPTED) contient la base de données qui a été chiffrée. l'objectif est donc de déchiffrer ce fichier.

## Analyse du chiffrement (10min)

41. En analysant le fichier _database.CRYPTED_, déduisez la méthodologie utilisée par l'attaque pour chiffrer les données. Est-ce que cela corrèle vos analyses issues de la question 38 ?
42. Savez-vous dire s'il s'agit d'un chiffrement symétrique ou à l'inverse, asymétrique ? Pourquoi ?
43. De quoi avons-vous besoin pour déchiffrer ce fichier ?

## Déchiffrer le fichier (ou pas) (20min)

44. Dans le fichier obtenu lors de la question 37, la ligne 3 est très intéressante selon vos collègues experts en cryptographie. Pourquoi ?
45. En faisant preuve d'imagination et en utilisant la technique du [Directory Listing](https://tecadmin.net/disable-directory-listing-apache/), essayez de récupérer ce qui a été identifié à la question 43. pour déchiffrer le fichier _database.CRYPTED_ ? Comment procédez-vous ?
46. Déchiffrez les données en expliquant la manipulation.

47. (bonus) Connaissez-vous le nom (potentiel) de l'attaquant ?

Plan d'action
==============

_Durée estimée: 1 heure 10 minutes_

Afin que l'entreprise "Target" ne revive pas cette situation, votre mission est également de leur suggérer des préconisations afin de renforcer la sécurité de leurs systèmes. Pour effectuer ces recommandations, vous allez devoir mobiliser vos connaissances, les analyses que vous avez pu mener, mais aussi faire un rapide audit de la configuration existante.

Une archive au format zip se trouve [ici](https://github.com/PandiPanda69/edu-isen-tp-ap4/raw/main/annexes.zip). Elle contient les différentes configurations `iptables` des machines du réseau, et un fichier retranscrivant un court interview de l'administrateur système de l'entreprise "Target" avec votre collègue architecte sécurité.

> Vous pouvez retrouver le plan d'adressage [plus haut](#investigations).

## Le premier bilan (10min)

48. Quel(s) commentaire(s) pouvez-vous faire en regardant la configuration `iptables` actuelle ?
49. A la lecture de l'interview, faites un tableau récapitulatif des éléments qui vont semblent positifs, et les éléments négatifs. Faites une appréciation globale du niveau de maturité de l'entreprise sur l'aspect sécurité de l'information.

## Le plan d'action (50min)

Un plan d'action a pour vocation d'être présenté aux décisionnaires. Vous allez donc devoir préparer un plan d'action que vous présenterez aux responsables de l'entreprise "Target" afin qu'ils valident, ou non, les mesures que vous recommandez.

50. En vous inspirant du tableau présenté ci-dessous (vous pouvez l'adaptez à vos besoins), listez les actions que vous recommanderiez de mettre en place, évaluez (à la louche) le temps d'implémentation, ainsi que le gain en sécurité. L'objectif est de (1) retrouver confiance dans le système actuel en nettoyant ce qui doit être nettoyé et (2) donner la capacité à l'entreprise "Target" de détecter plus rapidement et/ou d'empêcher ce type d'attaque à l'avenir.

| Réf.  | Titre                         | Objectifs                                                | Priorité | Complexité d'implém. | Gain en sécurité | Jrs/H estimés | Profil        |
| :--:  | ----------------------------- | -------------------------------------------------------- | :-------: | :------------------: | :--------------: | :-----------: | :-----------: |
| SEC_R | Revoir l'architecture réseau  | Mettre en place une architecture réseau plus sécurisée.  | CRITIQUE | ELEVEE               | IMPORTANT        |    N jours    | Expert réseau |
| SEC_X | Déployer un outil de sécurité | L'outil X est vraiment génial pour faire de la sécurité. | MOYEN | FAIBLE               | MOYEN            |    K jours    | Admin. Sys.   |

51. En prenant un compte les éléments financiers présentés dans le tableau suivant, déterminez le coût financier approximatif de l'attaque pour l'entreprise "Target". Puis déterminez le coût de la mise en place des recommandations que vous préconisez (en détaillant vos calculs).

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
| Prix de licence Antivirus EDR | 30€ / utilisateur / mois |
| Formation à l'administration d'une infrastructure sécurisée | 5000€ |
| Boîter Cisco Firepower (NIDS Hardware) | 300000€ |
| Abonnement NordVPN | 1€ avec le code promo `LES_VPN_C_EST_TROP_SUPAYR.` |


52. Proposez une implémentation des recommandations de votre tableau en _lot_ en développant une ébauche de calendrier que vous pourriez communiquer à l'entreprise "Target" avec, le coût associé à chaque lot. Exemple: _Lot 1 - Sécurisation du système, en commençant maintenant, fin estimée du chantier en juin 2024_, etc...
