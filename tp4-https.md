# TP4 - HTTPS & les Certificats

_Sébastien Mériot_ ([@smeriot](https://twitter.com/smeriot))
_Ce TP est très inspiré d'un TD écrit par François Lesueur ([énoncé original](https://github.com/flesueur/csc/blob/master/tp1-https.md)) et retouché pour les besoins du TP._

Durée: 2 heures

Préparation de l'environnement
==============================

Tout comme les précédents [TP](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md), ce TP sera réalisé en s'appuyant sur la plateforme [MI-LXC](https://github.com/flesueur/mi-lxc).

Pour rappel, l'infrastructure déployée simule plusieurs postes dont un SI d'entreprise (firewall, DMZ, intranet, authentification centralisée, serveur de fichiers, quelques postes de travail internes de l'entreprise _Target_),
une machine d'attaquant "isp-a-hacker" et quelques autres servant à l'intégration de l'ensemble.

> Pour les curieux, le code de MI-LXC, qui sert à générer cette VM automatiquement, est disponible avec une procédure d'installation documentée [ici](https://github.com/flesueur/mi-lxc)

Vous devez vous connecter à la VM en root/root. MI-LXC est déjà installé et l'infrastructure déployée, il faut avec un terminal aller dans le dossier `/root/mi-lxc`.
Pour démarrer l'infrastructure, tapez `./mi-lxc.py start`. 

> Dans la VM et sur les machines MI-LXC, vous pouvez installer des logiciels supplémentaires. Par défaut, vous avez mousepad pour éditer des fichiers de manière graphique.
> La VM peut être affichée en plein écran. Si cela ne fonctionne pas, il faut parfois changer la taille de fenêtre manuellement, en tirant dans l'angle inférieur droit, pour
> que VirtualBox détecte que le redimensionnement automatique est disponible. Il y a une case adéquate (taille d'écran automatique) dans le menu écran qui doit être cochée.
> Si rien ne marche, c'est parfois en redémarrant la VM que cela peut se déclencher. Mais il *faut* la VM en plein écran.

__L'objectif de ce TP est de permettre à la machine "isp-a-home" de naviguer de manière sécurisée sur le site `www.target.milxc` (hébergé sur la machine "target-dmz").__

Cheat sheet
===========

Voici un petit résumé des commandes dont vous aurez besoin :

| Commande | Description | Utilisation |
| -------- | ----------- | ----------- |
| print    | Génère la cartographie du réseau | ./mi-lxc.py print |
| attach   | Permet d'avoir un shell sur une machine | ./mi-lxc.py attach root@target-commercial |
| display  | Lance un serveur X sur la machine cible | ./mi-lxc.py display target-commercial |

Rappel: Vous devez être dans le répertoire `mi-lxc` pour exécuter ces commandes.


Connexion en clair
==================

Comme vu en cours, le protocole HTTPS a plusieurs buts. Le premier est le chiffrement, ce qui fait qu'une attaque de type _Man in the Middle_ est bien plus difficile puisque le contenu entre le client et le serveur est chiffré. Le second, que nous allons étudier dans ce TP, est la capacité d'attester que le site web visité est le bon.

Depuis la machine "isp-a-home", ouvrez un navigateur pour vous connecter à `http://www.target.milxc` (`./mi-lxc.py display isp-a-home`). Vous accédez à une page Dokuwiki, qui est bien la page attendue.

Imaginons que votre résolveur DNS ait été compromis et que l'entrée DNS pour `www.target.milxc` ait été modifiée pour vous envoyer sur un site frauduleux ! Nous allons simuler cette action en ayant pour objectif que le navigateur, lorsqu'il souhaite se connecter à l'URL `http://www.target.milxc`, arrive en fait sur la machine "ecorp-infra".

Pour simuler la compromission, vous allez altérer l'enregistrement DNS pour `target.milxc` dans la zone du TLD .milxc. Sur la machine "milxc-ns" :
	* Altération de `/etc/nsd/milxc.zone` pour diriger les requêtes DNS pour `target.milxc` vers 100.81.0.2 (appartenant à ecorp)
	* Puis `service nsd restart` (le DNS de ecorp est déjà configuré pour répondre aux requêtes pour `target.milxc`)
	
1. Tentez à nouveau de vous rendre sur `www.target.milxc` à l'aide votre navigateur. Que se passe-t-il ? Est-ce transparent ?

> Nous aurions pu également simuler une attaque BGP en [simulant un BGP hijacking](https://radar.qrator.net/blog/as1221-hijacking-266asns)) mais vous n'avons pas assez de temps en cours pour voir la théorie sous-jacente afin de le faire en TP.

Nous constatons ainsi le cas d'attaque que nous souhaiterions détecter : un utilisateur sur "isp-a-home" qui, en tapant l'URL `www.target.milxc`, arrive en fait sur un autre service que celui attendu. Remettez le système en bon ordre de marche pour continuer (remettre la bonne IP 100.80.1.2 dans la zone DNS).

Création d'une Autorité de Certification (CA)
=============================================

2. Rappelez ce qu'est une Autorité de Certification.

Pour sécuriser les communications vers `www.target.milxc`, nous allons créer, déployer et utiliser une CA. Cette CA sera hébergée dans le réseau "mica" et manipulée sur la machine "mica-infra" (son nom DNS dans l'infra sera `www.mica.milxc`). Nous utiliserons le protocole [ACME](https://fr.wikipedia.org/wiki/ACME_(protocole)) (celui de Let's Encrypt) pour l'opération de la CA (challenges, émission des certificats) via la suite d'outils de _Smallstep_.

Dans un premier temps, il faut initialiser une nouvelle CA en tant que root (création d'une paire de clés, d'un certificat racine, etc.) ([doc](https://smallstep.com/docs/step-ca/getting-started)) :

	# step ca init                  <- le # dénote une commande shell à taper en root

Pour cette initialisation, les paramètres ont peu d'importance (l'essentiel est la création du matériel cryptographique) et les choix suggérés par défaut à chaque question seront suffisants. Il faut juste faire attention aux questions :
* "What DNS names or IP addresses would you like to add to your new CA?", à laquelle il faut répondre "www.mica.milxc"
* "What address will your new CA listen at?", à laquelle il faut bien répondre ":443" (comme suggéré par défaut) et non "127.0.0.1:8443" (comme suggéré dans la doc liée précédemment). La CA doit, dans notre cas, écouter sur l'interface réseau externe et non sur localhost pour permettre l'émission du certificat de 'target-dmz' dans la partie suivante.
* "What do you want your password to be?", à laquelle il est préférable de choisir un mot de passe vous-mêmes

Dans un second temps, il faut activer le protocole ACME pour cette CA ([doc](https://smallstep.com/docs/tutorials/acme-challenge), le protocole ACME est responsable des défis/réponse pour la génération automatique des certificats) : <!-- (https://smallstep.com/blog/private-acme-server/)-->

	# step ca provisioner add acme --type ACME

Il faut démarrer le serveur de la CA (il doit rester actif pour la suite du TP) :

	# step-ca .step/config/ca.json

> La commande step-ca est bloquante, soit vous la mettez en arrière plan avec `CTRL+Z` puis `bg`, soit vous ouvrez ensuite un autre terminal. __Ne la lancez pas avec un &, elle doit en effet demander au lancement le mot de passe de la clé privée, ce qu'elle ne pourrait pas faire lancée avec un &.__

Vous aurez besoin du certificat public de la racine par la suite. Le plus simple est de le diffuser par le site web de la CA comme suit. Extrayez-le grâce à la commande suivante :

	# step ca root root.crt         <- ceci extrait le certificat racine vers le fichier root.crt

Puis copiez-le vers `/var/www/html` (avec les droits permettant sa lecture par le serveur web, donc `chmod 644 /var/www/html/root.crt`). Il sera ainsi accessible depuis toutes les autres machines par l'URL `http://www.mica.milxc/root.crt`.

> Si, après avoir affiché à l'écran un document chiffré (par exemple avec la commande `cat`), votre terminal affiche de mauvais caractères, utilisez la combinaison de touches `Ctrl+v, Ctrl+o` pour retrouver un affichage fonctionnel (ou tapez `reset`).

> Pour reprendre la configuration à 0, il faut supprimer le dossier `/root/.step` sur la machine "mica-infra".

Intégration de la CA à l'écosystème HTTPS
=========================================

Pour que la CA soit opérationnelle, il faut qu'elle soit reconnue par les clients HTTPS, ie, les navigateurs web (Firefox ici). Cette reconnaissance, dans le cas d'une CA globale, passe par l'intégration du certificat racine dans le magasin de certificats fourni avec le navigateur, donc par l'éditeur de ce navigateur.

> En entreprise, on rencontre souvent une CA locale qui est ajoutée localement au magasin de certificats. Dans ce TP, nous étudions le fonctionnement général de HTTPS global à travers le monde et non un déploiement à l'échelle locale.

Vous devez pour cela :
* Passer le filtre des éditeurs de navigateurs et les convaincre de reconnaître votre CA. Il s'agit bien évidemment d'une opération complexe, longue, coûteuse et rare. Ici, nous la simulerons chez l'éditeur de navigateur Gozilla. La machine `gozilla-infra` peut intégrer un certificat préalablement téléchargé au trousseau par défaut avec la commande `addcatofox.sh <certificate>` . Une fois cette commande exécutée, la distribution du navigateur (ou de ses mises à jour) intégrera ce nouveau certificat.
* Déclencher la mise à jour du navigateur par le client, en exécutant `updatefox.sh` en tant que root sur la machine `isp-a-home`

La nouvelle CA est ainsi devenue une CA par défaut, reconnue globalement. Vérifiez, après avoir redémarré Firefox, que vous la retrouvez bien dans le magasin de certiticats de Firefox. (Menu _Privacy & Security_, puis _View Certificates_)
