# TP3 - Chiffrements

_Sébastien Mériot_ ([@smeriot](https://twitter.com/smeriot))

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

Tout comme `openssl`, `gpg` permet de faire du chiffrement symétrique et asymétrique.

### Chiffrement symétrique

Tout comme précédemment, l'administrateur système va devoir chiffrer un mot de passe qu'il enverra au développeur (répartissez les rôles dans votre groupe).

Comme évoqué précédemment, `gpg` a le mérite d'être plus intuitif. La commande à saisir est donc relativement simple: `gpg --symmetric --pinentry-mode=loopback -a`. Le paramètre `--pinentry-mode` permet d'autoriser la saisie d'un mot de passe en ligne de commande (par défaut, c'est considéré comme non sécurisé). Comme précédemment, le `-a` permet d'encoder le résultat en _base64_.

>Note: _OpenPGP_ [choisira le meilleur algorithme](https://tools.ietf.org/html/rfc4880#section-5.3) à utiliser si vous ne lui en indiquez pas (AES256 par exemple).

7. Après avoir saisi votre mot de passe, saisissez le message à chiffrer et terminé par `CTRL+D`. Quelle différence constatez-vous avec `openssl` ?

Transmettez le message chiffré et le mot de passe à la personne jouant le rôle du développeur à présent afin que celui-ci déchiffre le message. Rien de plus simple: `gpg --decrypt --pinentry-mode=loopback` puis insérez dans `stdin` le message à déchiffrer.

### Chiffrement asymétrique

Tout comme `openssl`, nous allons commencer par générer notre _bi-clef_ côté développeur. Afin d'anticiper les prochaines manipulations, la personne jouant le rôle de l'administrateur système peut également générer sa _bi-clef_ car ce sera utile. Tapez la commande suivante: `gpg --gen-key --pinentry-mode=loopback`.

8. Par défaut, quel algorithme et quelle longueur de clef ont été sélectionnés par `gpg` pour générer la clef privée ? Combien de temps votre clef est-elle valide ?

Si `gpg` est aussi plébiscité, c'est parcequ'il offre une gestion bien plus facile des correspondances, notamment en maintenant un _trousseau de clef_. C'est pourquoi il vous a été demandé de saisir votre nom et une adresse e-mail. Vous remarquerez aussi que par défaut, `gpg` privilégie la sécurité et vous demande une _passphrase_ et fera expirer votre clef dans 2 ans. Vous pouvez à présent lister les clefs privées de votre trousseau (`gpg --list-secret-keys`) ainsi que les clefs publiques (`gpg --list-keys`). Dans les deux cas, vous devriez voir votre propre clef avec un niveau de confiance positionné par défaut à _ultimate_.

Afin de procéder à l'échange des clefs (l'administrateur système partage sa clef publique au développeur, et vice-versa), vous pouvez exporter votre clef publique de la sorte: `gpg -a --export adresse@mail`. Pour importer la clef, rien de plus simple: `gpg --import` puis collez la clef dans `stdin` en terminant si nécessaire par `CTRL+D`. 

Vous pouvez alors lister à notre les clefs publiques dans votre trousseau et voir la nouvelle clef apparaître:
```bash
admin@mi-target-admin:~$ gpg --import
gpg: key 8C24EB0963C8EDF8: public key "Developper <dev@target.lxc>" imported
gpg: Total number processed: 1
gpg:               imported: 1
admin@mi-target-admin:~$ gpg --symmetric --decrypt --pinentry-mode=loopback^C
admin@mi-target-admin:~$ gpg --list-keys
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: next trustdb check due at 2023-04-09
/home/admin/.gnupg/pubring.kbx
------------------------
pub   rsa3072 2021-04-09 [SC] [expires: 2023-04-09]
      72D0C8EDD1CECA95B80E794A3DE32DF2C67F97B8
uid           [ultimate] Admin <admin@target.lxc>
sub   rsa3072 2021-04-09 [E] [expires: 2023-04-09]

pub   rsa3072 2021-04-09 [SC] [expires: 2023-04-09]
      EF209DD69A5E1DC678C69B2F8C24EB0963C8EDF8
uid           [ unknown] Developper <dev@target.lxc>
sub   rsa3072 2021-04-09 [E] [expires: 2023-04-09]
```

L'administrateur est alors prêt pour chiffrer le mot de passe à envoyer au développeur: `gpg -a --encrypt --recipient dev@target.lxc`. La confiance accordée à la clef du développeur étant _inconnue_ (confiance par défaut), un message vous demandera si vous êtes certain de lui faire confiance. Saisissez alors le message sur `stdin` en terminant par `CTRL+D`.

> Protips: Si vous souhaitez être sympa avec votre destinataire, n'hésitez pas à mettre un retour à la ligne avant de saisir `CTRL+D`. Cela sera plus élégant lors du déchiffrement dans ton terminal.

Transmettez le message chiffré au développeur pour qu'il puisse le déchiffrer

9. Comparez rapidement `openssl` et `gpg`. Seriez-vous d'accord pour dire que `gpg` est plus facile d'utilisation au quotidien que `openssl` ? Pourquoi ?
10. Seriez-vous capable de dire qu'il s'agit bien de l'administrateur système qui vous a fait parvenir ce mot de passe ? Prenez un exemple pour illustrer votre réponse.

Signature d'un message
======================

Comme abordé lors du cours, la confidentialité n'est pas la seule problématique que la cryptographie tente d'adresser (en définitive, il y a beaucoup de problématiques). Nous allons maintenant nous pencher sur la capacité d'attester qu'un message a été produit par une personne de confiance et que celui-ci n'a pas été altéré. Pour cela, nous allons devoir considérer que le développeur et l'administrateur système se connaissent bien, et qu'ils ont échangé leur clef publique en sachant qu'il s'agissait bien de la clef de l'un et de l'autre.

Pour concrétiser cette confiance, l'administrateur système et le développeur vont mutuellement changer la confiance des clefs publiques:
```bash
dev@mi-target-dev:~$ gpg --edit-key admin@target.lxc
gpg (GnuPG) 2.2.12; Copyright (C) 2018 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

pub  rsa3072/3DE32DF2C67F97B8
     created: 2021-04-09  expires: 2023-04-09  usage: SC  
     trust: unknown       validity: unknown
sub  rsa3072/3AEF626563676AA7
     created: 2021-04-09  expires: 2023-04-09  usage: E   
[ unknown] (1). Admin <admin@target.lxc>

gpg> trust
pub  rsa3072/3DE32DF2C67F97B8
     created: 2021-04-09  expires: 2023-04-09  usage: SC  
     trust: unknown       validity: unknown
sub  rsa3072/3AEF626563676AA7
     created: 2021-04-09  expires: 2023-04-09  usage: E   
[ unknown] (1). Admin <admin@target.lxc>

Please decide how far you trust this user to correctly verify other users' keys
(by looking at passports, checking fingerprints from different sources, etc.)

  1 = I don't know or won't say
  2 = I do NOT trust
  3 = I trust marginally
  4 = I trust fully
  5 = I trust ultimately
  m = back to the main menu

Your decision? 5
Do you really want to set this key to ultimate trust? (y/N) y

pub  rsa3072/3DE32DF2C67F97B8
     created: 2021-04-09  expires: 2023-04-09  usage: SC  
     trust: ultimate      validity: unknown
sub  rsa3072/3AEF626563676AA7
     created: 2021-04-09  expires: 2023-04-09  usage: E   
[ unknown] (1). Admin <admin@target.lxc>
```

Nous allons maintenant utiliser la signature pour attester qu'un message a été écrit par l'administrateur système, et qu'il est bien destiné au développeur. `gpg` propose plusieurs formes de signatures:
- Signature & chiffrement, c'est-à-dire que le message sera chiffré et signé (`--sign`)
- Signature sans chiffrement avec formattage, c'est-à-dire que le message ne sera pas chiffré mais qu'un format sera imposé par `gpg` pour faciliter la vérification (`--clear-sign`)
- Signature détachée sans chiffrement, la signature sera générée à part et la vérification de la signature devra se faire manuellement (`--detach-sign`)

Nous allons utiliser le paramètre `--clear-sign` qui est le plus couramment utiliser par les plugins de clients mail. Imaginons que le développeur souhaite indiquer à l'administrateur système qu'il a bien reçu le mot de passe. Transmettez le résultat à l'administrateur système.

L'administrateur système peut alors vérifier que le message provient bien du développeur via la commande `gpg --verify` (notez la date à laquelle le message a été signé est également indiquée).

11. Imaginons maintenant que le message a été intercepté et altéré par le méchant Charlie ! Pour simuler ce cas, modifiez le message à la main puis relancez la vérification. Que constatez-vous ?

**Prenez quelques minutes avec votre encadrant pour faire le bilan de cette partie.**

Chiffrement d'une connexion SSH
===============================

Maintenant que nous avons globalement vu les mécanismes mis en oeuvre dans le chiffrement de correspondance (échange de secrets, échange de clefs, signature, ...), nous allons nous attarder sur la sécurisation d'une connexion entre machines, notamment en s'appuyant sur le protocole _SSH_ (puis nous parlerons de _HTTPS_ lors du prochain TP).

> Rappel: _SSH_, ou _Secure SHell_, est un protocole et un outil permettant la connexion à distance à des systèmes. C'est le moyen le plus utilisé pour administrer des serveurs distants.

Comme évoqué dans le TP précédent, l'administrateur système de la société _Target_ a pour mission d'administrer l'ensemble du parc informatique. Dans le cadre de sa mission, il n'est pas exclu qu'il doive se connecter à distance aux différents systèmes. Nous allons dans cette partie accompagner l'administrateur système à sécuriser la façon qu'il a de gérer le parc informatique (et il y a du boulot !).

Connectez-vous sur la machine de l'administrateur système avec le user _admin_ (`./mi-lxc.py attach admin@target-admin`).

Nous allons tenter de nous connecter à la machine du commercial. Dans le [TP précédent](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP2-Firewall.md), vous avez potentiellement implémenté des règles _iptables_ ainsi qu'un découpage réseau en sous-réseau. Reprenez vos notes et retrouvez l'IP que vous aviez assigné à la machine du commercial et tentez de vous y connecter (`ssh commercial@ip`). Une première question vous est posée, vous demandant si vous faites confiance à cette machine possédant une emprunte ECDSA. Puis un mot de passe vous est alors demandé (il s'agit de _commercial_).

12. Qu'est ce que ECDSA ?
13. A quoi correspond cette emprunte ?
14. A quoi correspondant le mot de passe ? A-t-il un lien avec le procédé cryptographique mis en oeuvre pour sécuriser la connexion ?
15. A votre avis, est-ce une bonne idée de laisser l'authentification par mot de passe en considérant la robustesse de ces mots de passe ?

Malheureusement, nous ne pouvons pas forcément toujours tout maîtriser. Ici, les mots de passe de la machine ont été définis par le _commercial_ lui-même qui ne souhaite pas en changer et votre direction vous a demandé d'arrêter de le déranger pour des "broutilles". Nous allons devoir composer avec.

> Le plus gros risque lorsqu'on intervient sur une machine à distance est de _se couper la patte_, c'est-à-dire appliquer un changement de configuration qui coupe votre accès et vous empêche de vous reconnecter. Il est impératif d'avoir les idées claires et de procéder méthodiquement.

Comme vu en cours, nous allons favoriser l'utilisation d'une authentification par clef publique plutôt que par mot de passe, restreindre l'utilisation de la clef publique, et interdire la connexion à l'utilisateur _root_ en favorisant à la connexion à un compte _admin_ sur la machine du commercial faisant parti des _[sudoers](https://www.digitalocean.com/community/tutorials/how-to-edit-the-sudoers-file-fr)_

16. Définissez les étapes à mettre en oeuvre pour réaliser toutes ces actions sur la machine du commercial. ***Faites valider votre plan de bataille par votre encadrant.***

> Note 1: La configuration du démon _sshd_ se fait par l'intermédiaire du fichier `/etc/ssh/sshd_config`.

> Note 2: Si vous souhaitez utiliser des clefs RSA, prenez garde à la longueur minimale de votre clef (>= 3072 bits).

> Note 3: Vous pourriez avoir besoin de quelques outils pratiques tels que [`ssh-keygen`](https://linux.die.net/man/1/ssh-keygen) ou encore [`ssh-copy-id`](https://linux.die.net/man/1/ssh-copy-id)

> Note 4: Vous pourriez avoir besoin d'éditer votre clef publique et/ou le fichier [`authorized_keys`](https://manpages.debian.org/experimental/openssh-server/authorized_keys.5.en.html#from=_pattern-list_) afin d'y apposer des restrictions


