# TP3 - Chiffrement et Certificats

_Sébastien Mériot_ ([@smeriot](https://twitter.com/smeriot))

Durée: 4 heures

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

Cheat sheet
===========

Voici un petit résumé des commandes dont vous aurez besoin :

| Commande | Description | Utilisation |
| -------- | ----------- | ----------- |
| print    | Génère la cartographie du réseau | ./mi-lxc.py print |
| attach   | Permet d'avoir un shell sur une machine | ./mi-lxc.py attach root@target-commercial |
| display  | Lance un serveur X sur la machine cible | ./mi-lxc.py display target-commercial |

Rappel: Vous devez être dans le répertoire `mi-lxc` pour exécuter ces commandes.

Rappel important
================

Comme le dit ce [compte Twitter](https://twitter.com/onditchiffrer?lang=fr), en français nous parlons de chiffrement.
Pour les curieux, vous trouverez vos réponses à vos questions sur le site suivant: https://chiffrer.info/

Chiffrement de correspondances privées
======================================

Afin de commencer en douceur, nous allons nous placer dans la situation où l'administrateur système souhaite communiquer le mot de passe d'une base de données au développeur.
Pour que le scénario soit encore plus réaliste, dans chaque groupe, vous allez désigner la personne qui incarnera l'administrateur système et la personne qui incarnera le
développeur. Chacun se connectera à sa machine, soit "target-admin" ou "target-dev" (`./mi-lxc.py attach target-admin`).

1. Avant de commenrcer, rappelez la différence entre chiffrement symétrique et chiffrement assymétrique.

OpenSSL (Secure Socket Layer)
-----------------------------

_OpenSSL_ est le nom d'une librairie libre fournissant différents outils implémentant des algorithmes cryptographiques. Cette librairie propose un utilitaire en ligne de
commande du même nom, `openssl` que nous allons découvrir et utiliser pour chiffrer des messages.

### Chiffrement symétrique

Pour débuter, nous allons tout d'abord chiffrer un message de façon [symétrique](https://openclassrooms.com/fr/courses/1757741-securisez-vos-donnees-avec-la-cryptographie/6031865-utilisez-le-chiffrement-symetrique-pour-proteger-vos-informations)
en utilisant le module [enc](https://www.openssl.org/docs/man1.1.1/man1/enc.html) de `openssl`.


Sur la machine de l'administrateur système, saisissez la commande suivante: `openssl enc -aes-256-ctr -salt -e -pbkdf2`.
Un mot de passe vous est demandé. Saisissez un mot de passe aléatoire que vous mémoriserez et que vous pourrez communiquer.
Une fois le mot de passe confirmé, cette commande s'attend à ce que vous tapiez le message à chiffrer sur `stdin`. Tapez le mot de passe de la base de données, et quand vous
avez terminé, faites `CTRL+D` (caractère signifiant _End of File_).

Vous devriez obtenir du binaire préfixé par _Salted_. C'est parfaitement normal. Lorsqu'on s'échange des messages chiffrés entre "humains", nous avons pour habitude d'encoder
le résultat en [base64](https://fr.wikipedia.org/wiki/Base64). Pour demander à `openssl` de procéder à l'encodage tout seul, rajoutez l'option `-a` à la commande précédente.
Vous pouvez ensuite vérifier que la chaîne encodée est bien similaire à ce que vous avez obtenu précédemment:

```
root@mi-target-admin:~# openssl enc -aes-256-ctr -salt -e -pbkdf2 -a
enter aes-256-ctr encryption password:
Verifying - enter aes-256-ctr encryption password:
POUET
U2FsdGVkX1/ETxGqhqc2oP9eeygTmw==
root@mi-target-admin:~# base64 -d && echo
U2FsdGVkX1/ETxGqhqc2oP9eeygTmw==
Salted__�O���6��^{(�
```

Vous avez chiffré votre premier secret de façon symétrique. Voici une explication plus détaillée des paramètres de la ligne de commande:
* aes-256-ctr : L'algorithme utilisé, à savoir AES-256 CounTeR
* e : Mode Chiffrement
* a : La sortie doit être encodée en base64
* salt : Utilisation d'un sel cryptographique aléatoire (plus d'information [ici](https://docs.actian.com/ingres/11.0/index.html#page/Security/Understanding_Salt.htm) si vous êtes curieux)
* pbkdf2 : Utilisation de l'algorithme [pbkdf2](https://fr.wikipedia.org/wiki/PBKDF2) pour dériver une clef à partir d'un mot de passe

>Note: Il est important de mémoriser les paramètres que vous avez saisis car votre correspondant aura scrupuleusement besoin des mêmes.

2. Essayez de relancer le chiffrement. Obtenez-vous le même _base64_ que précédemment ? Pourquoi selon vous ? (Vous pouvez utiliser le paramètre `-p` pour afficher la valeur
du sel, de la clef et de l'IV)


Passons au déchiffrement. Envoyez le _base64_ obtenu à l'un de vos camarades dans votre groupe. Communiquez lui les bonnes informations pour qu'il puisse déchiffrer le message
dans la machine du développeur à l'aide de `openssl`.

3. Comment avez-vous transmis le mot de passe et le _base64_ ? Pensez-vous que c'est sécurisé ? Si non, pourquoi ?

### Chiffrement asymétrique

Toujours en utilisant `openssl`, nous allons maintenant procéder au [chiffrement asymétrique](https://fr.wikipedia.org/wiki/Cryptographie_asym%C3%A9trique) de notre mot de
passe.

>Rappel: Alice chiffre avec la clef publique de Bob, et Bob déchiffre avec sa clef privée.

C'est au tour de la personne désignée en tant que le développeur de manipuler ! Dans un premier temps, il faut générer le couple clef privée et clef publique. Nous allons générer la clef privée à l'aide du module [genpkey](https://www.openssl.org/docs/man1.1.1/man1/genpkey.html). L'algorithme utilisé sera RSA (nous utiliserons les courbes elliptiques dans un second temps). Vous pouvez utiliser la commande suivante: `openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:4096`

Explication des paramètres:
* algorithm: Nous demandons à générer une clef privée utilisant RSA
* out: Le fichier où sera écrit la clef
* pkeyopt: Option additionnelle, ici nous demandons de créer une clef de 4096 bits comme recommandé par l'[ANSSI](https://www.ssi.gouv.fr/uploads/2021/03/anssi-guide-selection_crypto-1.0.pdf) (par défaut, la clef fait 2048 bits)

Vous avez à présent une clef privée RSA. Vous pouvez consulter le fichier pour voir à quoi ça ressemble (ici encore, l'encodage _base64_ est utilisé).

4. Imaginons que le Commercial pirate l'ordinateur du développeur et réussit à obtenir le fichier contenant la clef privée. Est-ce problématique ? Pourquoi ?

Il est fortement recommandé de ne pas générer des clefs privées sans mot de passe. Autrement dit, vous pouvez supprimer cette clef et la recréer en ajoutant le paramètre `-aes256`. Ce paramètre va demander de chiffrer la clef privée de façon symétrique en utilisant _AES256_. Ainsi, même si votre clef privée est compromise, il sera nécessaire à l'attaquant de disposer également de votre mot de passe. Notez le mot de passe, vous en aurez besoin !

A présent, nous allons dériver une clef publique de la clef privée avec la commande `openssl pkey -pubout -in private_key.pem -out public_key.pem`. Puisque vous avez besoin du contenu de la clef privée, le mot de passe de celle-ci vous est demandé. Comparez le contenu des 2 clefs. Partagez la clef publique avec la personne jouant le rôle de l'administrateur système.

5. Comment avez-vous partagé la clef publique ? Est-ce que cela représente un danger quelconque ?

A présent, l'administrateur système va pouvoir chiffrer le mot de passe de la base de données avec la clef publique du développeur. Pour ce faire, exécutez la commande suivante: `openssl rsautl -encrypt -inkey adminsys_pubkey.pem -pubin -out mdp.enc`. Vous serez alors invitez à entrer le message à chiffrer sur `stdin` puis faire `CTRL+D` une fois terminé.

Description de la commande précédente:
* rsautl: Module utilitaire pour utiliser les algorithmes RSA
* encrypt: Nous chiffrons un message
* inkey: Nous utilisons cette clef publique
* pubin: Indication que la clef `inkey` est une clef publique
* out: Fichier contenant le résultat

Vous pouvez constater que le fichier écrit est un fichier binaire. A présent, envoyez ce fichier binaire au développeur afin qu'il puisse déchiffrer le contenu et obtenir le mot de passe, en s'inspirant de la commande prédécemment écrite.

6. Dans quelle situation pensez vous privilégiez le chiffrement symétrique à l'asymétrique et vice versa ?

GNU Privacy Guard (GPG)
-----------------------

`openssl` est un outil très complet et de ce fait, parfois il peut s'avérer pénible à utiliser au quotidien (et surtout, il est source d'erreur si jamais on a le malheur de ne pas comprendre entièrement ce que nous faisons).

Lorsqu'il s'agit de chiffrement pour échanger des messages en êtres humains, dans la grande majorité des cas, nous utilisons le standard [OpenPGP](https://www.openpgp.org/about/) avec l'outil libre `gpg` qui a l'avantage d'être plus intuitif et moins sujet aux erreurs de manipulation qui pourraient représenter un risque pour la confidentialité des données échangées.

### Chiffrement symétrique

### Chiffrement asymétrique

Signature d'un message
======================


Chiffrement d'une connexion
===========================

Secure SHell (SSH)
------------------


HTTPS
-----


Certificats
===========

