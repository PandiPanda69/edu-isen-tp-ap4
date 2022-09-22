# TP1 - Man in the Middle

_Sébastien Mériot_ ([@smeriot](https://twitter.com/smeriot))

Durée: 2 heures

Préparation de l'environnement
==============================

Comme indiqué, ces TPs se dérouleront en se basant sur l'environnement [MI-LXC](https://github.com/flesueur/mi-lxc).

Pour préparer votre environnement, vous allez avoir besoin de:
- [Virtual Box](https://www.virtualbox.org/wiki/Downloads)
- La VM MI-LXC pré-configurée disponible [ici](https://flesueur.irisa.fr/mi-lxc/images/milxc-debian-amd64-1.4.2.ova)

Une fois le fichier `OVA` téléchargé, ouvrez `Virtual Box`, puis dans le menu `Fichier`, sélectionnez `Importer un appareil virtuel`. Choisissez le fichier `OVA` et patientez quelques minutes le temps de la création de la machine virtuelle.

Avant de lancer la VM, en fonction de votre configuration, il est peut-être nécessaire de diminuer la RAM allouée. Par défaut, la VM a 3GO : si vous avez 4Go sur votre machine physique, il vaut mieux diminuer à 2Go, voire 1.5Go pour la VM (la VM devrait fonctionner de manière correcte toujours).

L'infrastructure déployée simule plusieurs postes dont un SI d'entreprise (firewall, DMZ, intranet, authentification centralisée, serveur de fichiers, quelques postes de travail interne de l'entreprise _Target_), une machine d'attaquant et quelques autres servant à l'intégration de l'ensemble. Nous ne rentrerons pas dans le détail pour le moment de l'intégralité de l'architecture réseau.

> Pour les curieux, le code de MI-LXC, qui sert à générer cette VM automatiquement, est disponible avec une procédure d'installation documentée [ici](https://github.com/flesueur/mi-lxc)

Vous devez vous connecter à la VM en root/root. MI-LXC est déjà installé et l'infrastructure déployée, il faut avec un terminal aller dans le dossier `/root/mi-lxc`. Pour démarrer l'infrastructure, tapez `./mi-lxc.py start`. Une fois l'environnement démarré, vous pouvez commencer le TP !

> Dans la VM et sur les machines MI-LXC, vous pouvez installer des logiciels supplémentaires. Par défaut, vous avez mousepad pour éditer des fichiers de manière graphique. La VM peut être affichée en plein écran. Si cela ne fonctionne pas, il faut parfois changer la taille de fenêtre manuellement, en tirant dans l'angle inférieur droit, pour que VirtualBox détecte que le redimensionnement automatique est disponible. Il y a une case adéquate (taille d'écran automatique) dans le menu écran qui doit être cochée. Si rien ne marche, c'est parfois en redémarrant la VM que cela peut se déclencher. Mais il *faut* la VM en plein écran.

Cheat sheet
===========

Voici un petit résumé des commandes dont vous aurez besoin :

| Commande | Description | Utilisation |
| -------- | ----------- | ----------- |
| print    | Génère la cartographie du réseau | ./mi-lxc.py print |
| attach   | Permet d'avoir un shell sur une machine | ./mi-lxc.py attach root@target-commercial |
| display  | Lance un serveur X sur la machine cible | ./mi-lxc.py display target-commercial |

Rappel: Vous devez être dnas le répertoire `mi-lxc` pour exécuter ces commandes.

Familiarisation
===============

Dans un premier temps, faites un `print` afin d'afficher la topologie du réseau généré par MI-LXC. La cartographie étant vaste, vous pouvez redimensionner l'écran à votre guise.
Nous allons principalement nous concentrer sur le réseau d'une petite entreprise modélisé par les machines préfixées par "target" (target-lan). Ce réseau est composé de :

| Machine           | Description |
| :-------:         | ----------- |
| target-router     | Routeur     |
| target-admin      | Ordinateur de l'administrateur système |
| target-commercial | Ordinateur du commercial |
| target-dev        | Ordinateur du développeur |
| target-dmz        | Zone démilitarisée |
| target-ldap       | LDAP de l'entreprise |
| target-filer      | Serveur de stockage de l'entreprise |
| target-intranet   | Serveur web de l'intranet |

Plan d'Adressage
================

Cette petite entreprise n'a malheureusement aucune documentation concernant le plan d'adressage de leur réseau. Il va vous falloir le réaliser.

1. Récapitulez sous forme de tableau le plan d'adressage du réseau. Indiquez, pour chaque machine, l'adresse IPv4 ainsi que son adresse MAC. Expliquez comment vous avez procédé.

**Faites valider par votre encadrant le plan d'adressage.**

ARP Spoofing
============

Nous allons à présent tenter de mettre en oeuvre une attaque dite `ARP Spoofing`.

2. Rappelez succintement la mise en oeuvre de ce type d'attaque comme vu dans le cours.

Nous allons considérer que pour une raison inconnue, le développeur de l'entreprise souhaite s'attaquer à l'administrateur système afin de lui dérober ses identifiants Intranet. Le but de l'attaque sera donc de faire en sorte que l'administrateur système entre ses identifiants sur un serveur web qui n'est pas l'intranet.

Pour réaliser l'attaque, ouvrez 2 terminaux et connectez-vous sur l'ordinateur du développeur et de l'administrateur système.

3. Sur l'ordinateur de l'administrateur système, affichez la table ARP. Est-ce que le serveur intranet est présent ?

S'il est présent, supprimez-le en utilisant la commande suivante: `arp -d <ip_intranet>` (en remplaçant `<ip_intranet>` par l'IP précédemment identifiée)

Pour réaliser l'attaque, nous allons utiliser l'outil [arpspoof](https://linux.die.net/man/8/arpspoof) déjà installé sur l'ordinateur du développeur.
Afin de voir la magie s'opérer, il est possible de lancer dans le terminal de l'ordinateur de l'administrateur système la commande `watch -n1 arp -a` qui permettra d'actualiser
toutes les secondes la table ARP. 

En parallèle, dans le terminal du développeur, lancez la commande `arpspoof` avec les bons arguments afin de tromper l'ordinateur du sysadmin pour qu'il pense que l'intranet est
la machine du développeur.

4. Voyez-vous la table ARP changer ? A votre avis, pourquoi ne change-t-elle pas ?

Stoppez `arpspoof` à l'aide de CTRL+C (ça peut mettre un peu de temps, l'outil essaie de réannoncer la véritable MAC avant de s'éteindre).

5. Depuis la machine du sysadmin, faites un `curl` vers le serveur de l'intranet puis relancez le `watch`. Une nouvelle entrée doit apparaître dans la table ARP. Laquelle ? Pourquoi ?
6. Relancez `arpspoof` sur la machine du développeur. Est-ce que la table ARP sur la machine du sysadmin a changé ? Expliquez.

Attaque MitM
============

A présent, nous allons réaliser une attaque dite de l'homme du milieu et tenter d'intercepter et d'altérer le trafic sur le réseau.

Relancez l'attaque d'ARP Spoofing comme vu précédemment. En complément, sur la machine du développeur, lancez l'outil [urlsnarf](https://linux.die.net/man/8/urlsnarf)
qui vous affichera les requêtes HTTP entrantes.

7. Depuis la machine du sysadmin, faites un `curl` sur l'intranet. Obtenez-vous le résultat escompté ? Comment le savez-vous ?

Afin de débugger et comprendre l'origine du problème, nous allons capturer le trafic avec `tcpdump`. Sur la machine du développeur, lancez la commande suivante permettant
de capturer uniquement les paquets sur le port HTTP (TCP/80) : `tcpdump 'port http'`. Puis relancez le `curl`. Enfin, faites CTRL+C sur le `tcpdump`.

8. Analysez le résultat du `tcpdump`. Est-ce que des paquets HTTP ont été interceptés sur notre machine ? Quelle est l'IP de destination ? Quelle est l'IP de notre machine ?

Par défaut, le noyau Linux ignore les paquets qui ne lui sont pas adressés. Peut-être que cela pourrait expliquer en partie pourquoi nous n'avons pas le comportement espéré.
A l'aide de `ifconfig`, ajoutez une nouvelle interface réseau afin de résoudre le problème.

> Petit coup de pouce: pour ajouter une nouvelle interface réseau avec `ifconfig`, vous pouvez utiliser la commande suivante:
> `ifconfig eth0:bad <ip> netmask <mask> up` en > remplaçant les champs `ip` et `mask` par les bonnes valeurs.

9. Vérifiez à l'aide de `ifconfig` que votre interface est correctement configurée. Relancez `curl`. Que se passe-t-il ?
10. Tentez d'expliquer pourquoi, malgré l'ARP spoofing, vous aviez quand même une réponse lors de la question 8.

Rogue DNS (bonus)
=================

12. A votre avis, pourquoi est-il intéressant d'usurper un serveur DNS plutôt que le serveur web ?
13. Expliquez comment vous feriez pour mettre en place l'usurpation du serveur DNS dans ce cas de figure ?
14. Pour ne pas éveiller de soupçons concernant les zones DNS internes de l'entreprise, comment feriez-vous pour que le comportement soit transparent ?
