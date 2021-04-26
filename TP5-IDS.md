# TP5 - Intrusion Detection Systems

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

_Cet énoncé est très fortement inspiré d'un TP créé par François Lesueur ([énoncé original](https://github.com/flesueur/srs/blob/master/tp3-ids.md)) et que nous avons co-animé à l'INSA
Lyon il y a quelques mois._

Durée: 4 heures

Préparation de l'environnement
==============================

Tout comme les [TPs précédents](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md), ce TP sera réalisé en s'appuyant sur la plateforme [MI-LXC](https://github.com/flesueur/mi-lxc).

Pour rappel, l'infrastructure déployée simule plusieurs postes dont un SI d'entreprise (firewall, DMZ, intranet, authentification centralisée, serveur de fichiers, quelques postes de travail internes de l'entreprise _Target_),
une machine d'attaquant "isp-a-hacker" et quelques autres servant à l'intégration de l'ensemble.

> Pour les curieux, le code de MI-LXC, qui sert à générer cette VM automatiquement, est disponible avec une procédure d'installation documentée [ici](https://github.com/flesueur/mi-lxc)

Vous devez vous connecter à la VM en root/root. MI-LXC est déjà installé et l'infrastructure déployée, il faut avec un terminal aller dans le dossier `/root/mi-lxc`.
Pour démarrer l'infrastructure, tapez `./mi-lxc.py start`. Durant ce TP, vous allez analyser un scénario d'attaque et travailler à sa détection par NIDS (Network IDS), Proxy filtrant et HIDS (Host IDS) . Les outils utilisés seront Suricata (NIDS), OSSEC (HIDS), et Squid (Proxy).

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

Etude d'un scénario d'attaque
=============================

L'entreprise "target" fait appel à votre équipe afin de l'aider à se prémunir d'un scénario qu'ils redoutent : le déploiement d'un _ransomware_ et notamment la fuite de toute leur donnée.

Rappelons sommairement les différentes étapes d'une attaque de ce type:
1. Les attaquants envoient un mail frauduleux aux employés leur demandant de télécharger un fichier douteux.
2. L'utilisateur télécharge le fichier douteux en cliquant sur le lien du mail.
3. L'utilisateur exécute le fichier qui installe une porte dérobée.
4. Les attaquants utilisent la porte dérobée pour se déplacer sur le SI et atteindre les données.
5. Les attaquants exfiltrent les informations vers un serveur distant.
6. Les attaquants procèdent au chiffrement des données.

En se concentrant **uniquement** sur les points 2, 3 et 5, indiquez quelles solutions techniques (proxy, NIDS, HIDS) vous mettriez en place et à quel endroit.
Rédigez rapidement un plan de bataille pour détecter ce type de scénario.

**Faites valider votre plan de bataille par l'encadrant avant d'aller plus loin.**

Mise en place d'un proxy
========================


Mise en place d'un NIDS
=======================


Mise en place d'un HIDS (bonus)
===============================


