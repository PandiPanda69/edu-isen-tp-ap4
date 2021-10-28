# TP5 - Intrusion Detection Systems

_Sébastien Mériot ([@smeriot](https://twitter.com/smeriot))_

_Cet énoncé est en partie inspiré d'un TP créé par François Lesueur ([énoncé original](https://github.com/flesueur/srs/blob/master/tp3-ids.md)) et que nous avons co-animé à l'INSA Lyon il y a quelques mois._

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

En se concentrant **uniquement** sur les points 2, 3 et 5, indiquez quelles solutions techniques (proxy HTTP sortant filtrant, NIDS, HIDS) vous mettriez en place et à quel endroit.
Rédigez rapidement un plan de bataille pour détecter ce type de scénario.

**Faites valider votre plan de bataille par l'encadrant avant d'aller plus loin.**

Mise en place d'un proxy HTTP
=============================

## Installation

Un proxy HTTP filtrant a l'intérêt de permettre de contrôler de manière fine le contenu accessible par les utilisateurs d'un réseau. Cette technique a l'avantage d'être relativement facile à mettre en place et c'est ce que nous allons voir durant ce TP.

Nous allons utiliser un proxy très connu du nom de `squid` avec son extension `squid-guard` afin de mettre en place un contrôle du flux HTTP. Pour commencer, nous allons les installer sur la machine "target-router".

```bash
apt-get update
apt-get install -y squid squidguard
```

Vous pouvez vérifier la bonne installation de `squid` en forgeant une requête HTTP en utilisant le proxy local sur le port TCP/3128 ce qui vous donnera une réponse similaire à celle-ci :
```
# curl -I -x localhost:3128 https://www.isen.fr/
HTTP/1.1 200 Connection established

HTTP/2 200 
date: Sun, 02 May 2021 11:43:13 GMT
server: Apache
vary: User-Agent,Accept-Encoding
last-modified: Sun, 02 May 2021 02:01:20 GMT
accept-ranges: bytes
content-length: 40774
x-content-type-options: nosniff
x-frame-options: sameorigin
cache-control: max-age=0, no-cache, no-store, must-revalidate
pragma: no-cache
expires: Mon, 29 Oct 1923 20:30:00 GMT
content-type: text/html; charset=UTF-8
```

Vous pouvez remarquez les 2 codes HTTP 200 qui sont remontés, le premier indiquant la bonne connexion au proxy, la seconde étant la réponse du serveur distant interrogé (isen.fr).

## Configuration du proxy

Par défaut, `squid` joue uniquement le rôle de proxy et permet notamment de mettre en cache des ressources. C'était notamment très utile lorsqu'une entreprise disposait d'une connectivité limitée afin de réduire la bande passante consacrée à la navigation Internet. De nos jours, les proxies ont plutôt un rôle destiné à la sécurité des réseaux. Pour cela, nous allons devons indiquer à `squid` d'utiliser le module `squid-guard` dès lors qu'une URL est visitée afin de savoir s'il faut rediriger l'utilisateur quelque part. Pour ce faire, nous allons ajouter le paramètre de configuration [`url_rewrite_program`](http://www.squid-cache.org/Doc/config/url_rewrite_program/) dans la configuration située dans `/etc/squid/squid.conf` tel que :
```
url_rewrite_program /usr/bin/squidGuard -c /etc/squidguard/squidGuard.conf
```

Il faut également autoriser les IPs du réseau à se connecter car, par défaut, `squid` n'autorise que _localhost_. A la ligne 1408, modifiez la configuration pour ajouter une directive autorisant la sous-réseau de l'entreprise "target" à utiliser le proxy afin d'avoir quelque chose ressemblant à ceci:
```
acl allowed_ips src 100.80.0.0/16

http_access allow localhost
http_access allow allowed_ips

# And finally deny all other access to this proxy
http_access deny all
```

Puis on relance squid pour prendre en compte les modifications.

```
# service squid restart
# service squid status
● squid.service - Squid Web Proxy Server
   Loaded: loaded (/lib/systemd/system/squid.service; enabled; vendor preset: en
   Active: active (running) since Sun 2021-05-02 13:00:17 CEST; 10s ago
     Docs: man:squid(8)
  Process: 1798 ExecStartPre=/usr/sbin/squid --foreground -z (code=exited, statu
  Process: 1801 ExecStart=/usr/sbin/squid -sYC (code=exited, status=0/SUCCESS)
 Main PID: 1802 (squid)
    Tasks: 4 (limit: 3556)
   Memory: 16.6M
```


La configuration par défaut de `squid-guard` n'est pas correcte et interdit tout trafic. Ouvrez le fichier `/etc/squidguard/squidGuard.conf`. Celui-ci est organisé en 4 grandes catégories:
- Définition d'horaires d'activité: il est possible d'autoriser le trafic uniquement sur des plages horaires configurées par exemple pour interdire le trafic web le week-end lorsque personne n'est au bureau.
- Définition de règles en fonction des IPs sources.
- Définition de règles en fonction des sites de destination.
- Les ACLs qui sont une combinaison de toutes les règles précédemment définies.

Nous allons nous limiter à un cas simple: interdire l'accès au site `example.com` au développeur et lui interdire de naviguer sur le web le week-end. Lorsqu'il enfreindra cette politique, il sera redirigé sur `perdu.com`. L'admin au contraire pourra faire tout ce qu'il souhaite quand il le souhaite.

Dans un premier temps, nous allons créer un fichier contenant les domaines que nous souhaitons interdire. Créez un nouveau fichier `/etc/squidguard/interdit-domains.txt` et sur la première ligne, ajoutez `example.com`. Maintenant, reprenez le fichier `/etc/squidguard/squidGuard.conf`. Modifiez la variable `dbhome` afin d'indiquer à `squid-guard` de charger le fichier que nous venons de créer au bon endroit: `dbhome /etc/squidguard/`.

Au niveau de la définition des IPs sources, nous allons configurer uniquement 2 groupes:
- _admin_ composé du routeur et de la machine de l'administrateur réseau
- _users_ composé des machines du développeur et du commercial. Puisque nous souhaitons contraindre les plages horaires, n'oubliez pas la directive `within`. (attention, _user_ est un mot-clef réservé et ne doit pas être utilisé comme nom de groupe)

> Nous n'utilisons pas ici d'utilisateur. Sachez que `squid` peut demander à ce que les utilisateurs s'authentifient afin de mieux contrôler ce que font les utilisateurs et de définir des politiques en se basant sur les rôles fonctionnels de chacun plutôt qu'en se basant sur le plan d'adressage.

Concernant les destinations, nous allons créer une nouvelle classe intitulée _interdit_ en indiquant à `squid-guard` de lire la liste des domaines dans le fichier "interdit-domains.txt" précédemment créé.

Pour finir, nous devons configurer les ACLs. Celles-ci sont toujours composées d'un cas par défault. Nous aurons donc des ACLs en 3 parties:
- Le groupe _admin_ n'a aucune restriction (`pass any`)
- Le groupe _users_, s'il consulte des sites identifiés dans _good_, mais pas dans _interdit_, alors pas de restriction. Sinon, redirection vers `http://perdu.com`.
- Par défault, interdiction de naviguer sur internet et redirection systématique vers `http://perdu.com`.

Quand vous avez terminé, sauvegardez le fichier et redémarrez `squid`. Pour tester, vous pouvez tester ces scénarios et voir si vous obtenez le comportement attendu:
```bash
root@mi-target-router:~# curl -x 100.80.0.1:3128 -i example.com
# Obtention du contenu example.com

root@mi-target-dev:~# curl -x 100.80.0.1:3128 -i example.com
# Obtention du contenu de perdu.com
```

La configuration que nous utilisons est dite _transparente_. Cela signifie que nous ne sommes pas redirigé vers `perdu.com` mais bien que le proxy nous retourne le contenu de `perdu.com` comme s'il s'agissant du contenu de `example.com`. C'est pourquoi nous travaillons uniquement en HTTP. Vous pouvez remarquer qu'en requêtant des sites en HTTPS, `squid` génère une erreur 503. Je vous laisse deviner pourquoi.

## Configuration du navigateur

Notre proxy est en place, nous allons maintenant l'utiliser dans un navigateur. Connectez-vous en mode graphique sur la machine du développeur (`./mi-lxc.py display target-dev`) puis ouvrez le navigateur. Tentez de vous rendre sur `example.com` et constatez qu'aucun filtrage ne vous interdit de vous rendre sur le site.

A présent, ouvrez les préférences de Firefox puis dans l'onglet _General_, cherchez la section _Network Settings_. Cochez _Manuel proxy configuration_ et entrez les informations du proxy HTTP que nous venons d'installer: `100.80.0.1 sur le port 3128`. Sauvegardez puis raffraîchissez la page. Le contenu devrait être réécrit.

> Il se peut que le cache de Firefox vous joue des tours. N'hésitez pas à raffraichir plusieurs fois.

> Généralement, cette configuration s'opère via un fichier _PAC_ ([_Proxy Auto-Configuration_](https://developer.mozilla.org/en-US/docs/Web/HTTP/Proxy_servers_and_tunneling/Proxy_Auto-Configuration_PAC_file)) qui est stocké sur le serveur proxy et qui est configuré au travers du DHCP.
 
Cette configuration n'est pas très sécurisée. En effet, un utilisateur peut décider facilement de contourner la politique de sécurité en supprimant l'utilisation du proxy. Comment feriez-vous pour que l'utilisation de ce proxy ne soit pas contournable ?

Mise en place d'un NIDS
=======================

`Suricata` est un IDPS réseau et nous allons l'utiliser pour illustrer son utilité. Il est installé sur "target-router". Sa configuration est dans `/etc/suricata/suricata.yaml` et nous allons utiliser le fichier de règles `/etc/suricata/rules/local.rules`. Vous pourrez visualiser les alertes dans le fichier de log `/var/log/suricata/fast.log` (`tail -f /var/log/suricata/fast.log` permet de suivre l'évolution des alertes).

La règle
```
 alert tcp 10.0.0.1 80 -> 192.168.1.0/24 111 (content:"Waldo"; msg:"Waldo's here";sid:1001;)
```

signifie par exemple que :

* On étudie les paquets TCP allant de `10.0.0.1:80` vers le sous-réseau:port `192.168.1.0/24:111` (__attention, les règles sont orientées et Suricata regarde uniquement les paquets allant de la partie gauche de la règle à la partie droite !__)
* Contenant la chaîne "Waldo"
* Le log affichera "Waldo's here" s'il y a une correspondance
* `alert` peut être remplacé par `drop` pour jeter le paquet au lieu de le journaliser (mode __IPS__)
* Le `sid` est un identifiant de règle, _il doit être unique_
* Les règles peuvent être composées de nombreux éléments (contenu, taille, expressions régulières, etc.). Tout est ici : [Règles Suricata](https://suricata.readthedocs.io/en/latest/rules/index.html). [`http_stat_code`](https://suricata.readthedocs.io/en/latest/rules/http-keywords.html#http-stat-code) (avec un _ et non un ., attention) permet par exemple de surveiller le code de retour HTTP et [`threshold`](https://suricata.readthedocs.io/en/latest/rules/thresholding.html) de gérér des seuils. <!-- \url{http://manual.snort.org/node32.html}) -->

Lisez les règles présentes dans le fichier `local.rules`. Déclenchez la règle "COMMUNITY WEB-MISC Test Script Access" en accédant au serveur web de la DMZ (`http://www.target.milxc`), par ex. depuis la machine `isp-a-hacker`. La requête est-elle exécutée par le serveur DMZ, malgré l'alerte ?

> Attention: Suite au précédent TP, assurez-vous que l'entrée DNS de `http://www.target.milxc` est correcte et pointe bien vers `100.80.1.2`.


De nombreux logiciels malveillants utilisent des _packers_ pour échapper aux signatures des antivirus (entre autre). Le plus connu se nomme [_UPX_](https://upx.github.io/) et il est très facile de faire des signatures permettant de détecter des fichiers en cours de téléchargement ayant été préalablement _packé_ avec _UPX_ : les binaires contiennent la chaîne `Info: This file is packed with the UPX executable packer http://upx.sf.net`.
Ecrivez une règle afin de détecter quand un fichier packé avec _UPX_ est téléchargé sur le réseau de l'entreprise _target_.

Lorsque vous modifiez les règles, il faut recharger le fichier avec `service suricata reload`. Vous pouvez suivre l'activité de Suricata et l'absence d'erreur à l'intégration des règles dans `/var/log/suricata/suricata.log`.

> Pour tester votre règle, vous pouvez trouver des URLs de malwares packés avec _UPX_ ici :  https://urlhaus.abuse.ch/browse/tag/mozi/.

> Pour avoir un aperçu du type de règles fournies par défaut avec Suricata, vous pouvez exécuter `suricata-oinkmaster-updater` qui téléchargera des listes de règles dans `/etc/suricata/rules/*.rules`.

Dans la configuration préinstallée, Suricata est en écoute seulement (donc "IDS" mais pas "IPS"). D'autres configurations de Suricata permettent de le mettre en interception. Voici les étapes :

* `cp /lib/systemd/system/suricata.service  /etc/systemd/system/suricata.service`
* Remplacer `--af-packet` par `-q0` dans `/etc/systemd/system/suricata.service`
* Recharger systemd `systemctl daemon-reload`
* Utiliser `drop` au lieu de `alert` dans les règles
* `service suricata restart`

Pour ensuite activer le passage des paquets par Suricata, il faut ajouter une décision NFQUEUE au lieu des décision ACCEPT dans les règles IPTables. Par exemple, pour faire passer par Suricata tout le trafic forwardé :
`iptables -I FORWARD -j NFQUEUE` (attention, suricata prend des décisions définitives, le reste des règles n'est pas appelé ensuite ! [Une solution plus évoluée utilisant les marques et le mode repeat de Suricata existe.](https://docs.mirantis.com/mcp/latest/mcp-security-best-practices/use-cases/idps-vnf/ips-mode/nfq.html))

Relancez le téléchargement du fichier _packé_, et constatez que votre tentative est tombe bien en _timeout_.


Mise en place d'un HIDS (bonus)
===============================

OSSEC est un HIDS installé sur la machine "target-dmz". Il permet notamment de surveiller les logs (dont accès/refus d'accès du serveur web) et les fichiers présents sur la machine. Sa configuration se trouve dans `/var/ossec/etc/ossec.conf`.

Les alertes sont dans `/var/ossec/logs/alerts/alerts.log`. Chaque alerte contient un identifiant de règle, qui permet de retrouver la règle originale dans les fichiers `/var/ossec/rules/*.xml`.

### syscheck
Le module `syscheck` est responsable de surveiller les fichiers présents pour détecter leurs modifications ou même les apparitions de nouveaux fichiers (pas activé par défaut). Il se configure dans la section `<syscheck>` de `/var/ossec/etc/ossec.conf`. Lire la [doc](https://ossec.github.io/docs/manual/syscheck/index.html) et cette réponse de [FAQ](https://www.ossec.net/docs/faq/syscheck.html#why-aren-t-new-files-creating-an-alert).

Sur la machine "target-dmz" les fichiers uploadés sur dokuwiki sont stockés dans `/var/lib/dokuwiki/data/media`. Configurez ce qu'il faut comme indiqué précédemment (une option et une règle) pour obtenir une alerte à chaque nouveau fichier sur le wiki.

Attention :
* la règle est à ajouter impérativement dans un `<group>` (dans `/var/ossec/rules/local_rules.xml`)
* `syscheck` fonctionne grâce à des scans réguliers (très lents pour ne pas impacter le système) et compare les résultats avec la base du précédent scan. Il faut donc attendre que le scan soit passé et cela prend un certain temps... On peut le surveiller dans `/var/ossec/logs/ossec.log`
  * début du scan : "INFO: Starting syscheck database (pre-scan)."
  * fin du scan (peut prendre plusieurs minutes !) : "INFO: Finished creating syscheck database (pre-scan completed)."
* comme le processus est long, limitez les dossiers à surveiller au strict minimum (désactivez les dossiers par défaut, mettez juste le dossier dokuwiki)

Pour tester, simulez le dépôt d'un fichier vous même dans le dossier surveillé.

Plutôt qu'attendre on peut déclencher un re-scan du système avec `/var/ossec/bin/agent_control -r -u 000`, mais attention il s'écoule toujours plusieurs (5 ?) minutes entre les scans.

### logs
Il est aussi possible d'analyser les logs : [doc](https://ossec.github.io/docs/manual/monitoring/index.html)

Lancez depuis la machine "isp-a-hacker" (user "debian) un bruteforce sur le mot de passe de l'admin du wiki avec la commande : `python3 tp/intrusion/dokuwiki.py www.target.milxc` et observez les alertes OSSEC.

