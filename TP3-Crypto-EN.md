# TP3 - Encryption

_Sébastien Mériot_ ([@smeriot](https://twitter.com/smeriot))

Duration: 2 hours

Setup The Environment
=====================

Like the [TP1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM-EN.md), this practical work will be based upon the
educational platform [MI-LXC](https://github.com/flesueur/mi-lxc).

As a reminder, the deployed infrastructure emulated several devices in an enterprise (firewall, firewall, DMZ, intranet, central authentication, file sharing, several internal workstations of the company _Target_), a workstation of an attacker and few other devices useful for running the platform. We won't detail yet the whole network infrastructure.

> For the most curious of you, the MI-LXC code which generate this VM automaticaly, is available with a documented procedure [here](https://github.com/flesueur/mi-lxc)

You should connect to the VM using the credentials `root/root`. MI-LXC is already installed and the infrastructure deployed. To run the infrastructure, open a terminal and go in the golder `/root/mi-lxc`. Then enter the command `./mi-lxc.py start`. Once started, you can put your hands on !

> In the Virtual Machine and the MI-LXC devices, you can install additional softwares. By default, `Mousepad` can help edit files with a UI. The fullscreen mode can be enabled to display the VM. If it does not work, sometimes you have to change the window size manually by dragging the right lower border, so VirtualBox can detect that the automatic resize feature is available. This feature has to be enabled in the `Screen` menu. If it does not work, try to reboot the VM.

Cheat sheet
===========

You can find below a quick summary of the available commands :

| Commande | Description | Utilisation |
| -------- | ----------- | ----------- |
| print    | Display the network emulated by MI-LXC | ./mi-lxc.py print |
| attach   | Open a new shell on a device | ./mi-lxc.py attach root@target-commercial |
| display  | Open a graphical interface on a device | ./mi-lxc.py display target-commercial |
| start    | Start the emulated infrastructure    | ./mi-lxc.py start |
| stop     | Shutdown the infrastructure.       | ./mi-lxc.py stop |

Note: You should be in the directory  `mi-lxc` to run commands.


End-to-End Encryption
=====================

Let's say you are the system administrator and you want to communicate the password of a database to the developer. For sure this
password should not be shared in clear text to avoid any man-in-the-middle attack.
In order to make the scenario more realistic, designate in your team someone who is going to be the sysadmin and someone who is going
to be the developer. Each on should connect to his/her device in the target network, either "target-admin" or "target-dev"
(`./mi-lxc.py attach target-admin`).

1. Before starting, give the differences between symmetric and asymùetric encryption.

OpenSSL (Secure Socket Layer)
-----------------------------

_OpenSSL_ is an OpenSource library implementing general-prupose cryptography. This library provides a command line tool - `openssl` -
you are going to use to encrypt messages.

### Symmetric Encryption

First you are going to encrypt a message the [symmetric](https://en.wikipedia.org/wiki/Symmetric-key_algorithm) way by using the
`openssl` [enc](https://www.openssl.org/docs/man1.1.1/man1/enc.html) module.

The sysadmin has en enter the following command:  `openssl enc -aes-256-ctr -salt -e -pbkdf2`.
A password is required to encrypt the message. Type a password that you'll keep in mind to be able to share it.
Once the password confirmed, the command line expects the message to be entered on `stdin`. This is now that you have to write
the private message you want to send to the developer. Once you are done, do `CTRL+D` (which means _End of File_ in the Unix World).

You should get a binary output prefixed by _Salted_. This is exactly what is expected. As you can see, it does look dirty.
When "humans" share encrypted messages, we usually encode it using the [base64](https://en.wikipedia.org/wiki/Base64) encoding. To
ask `openssl` to encode the output automatically using _base64_, just add the option  `-a` to the previous command.
You can then check that the output is properly encoded and/or similare at what you get previously:

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

You just encrypted your first message ! Here is some explanations about the parameters of the command line:
* aes-256-ctr : Encryption algorithm (AES-256 CounTeR)
* e : Encryption mode
* a : The output should be encoded using _base64_.
* salt : Random cryptographic salt used (more information [here](https://docs.actian.com/ingres/11.0/index.html#page/Security/Understanding_Salt.htm) si vous êtes curieux)
* pbkdf2 : Use the [pbkdf2](https://fr.wikipedia.org/wiki/PBKDF2) algorithm to derivate a fixed-length key from a password.

>Note: This is important to remember the paramters you used for the encryption because your recipient need exactly the same to decrypt
>the message.

2. Try to encrypt once again the same message. Have you the same _base64_ as previously ? Why ? (the `-p` parameter can help display
the value of the salt, the key and the IV).

Send the _base64_ output you got previously to the developer. Give the good indications so (s)he can easily decrypt the message using
`openssl` in the developer prompt.

3. How did you share the password to decrypt the message ? How did you share the _base64_ encoded message ? It is secure ? If no, why ?

### Asymmetric Encryption

Still using `openssl`, you are going to perform [asymmetric encryption](https://en.wikipedia.org/wiki/Public-key_cryptography).

>Hint: Alice encrypts a message with the Bob's public key, Bob decrypts the message with his private key.

The developer will now try to send a secret to the sysadmin. First you have to generate both the private and public key. To generate
the private key, the `openssl` [genpkey](https://www.openssl.org/docs/man1.1.1/man1/genpkey.html) module have to be used. You can
enter the following command: `openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:4096`

Explanations:
* algorithm: The private key is using RSA algorithm
* out: The file containing the private key
* pkeyopt: (Optional) Ask to generate a 4096 bits long key which is recommended by most security agencies World-wide.

You have now a RSA private key. You can look at it to see what it does look like (the _base64_ is used once again).

4. Let's imagine the commercial hacks the developer computer and succeed in getting the private key. Is it an issue ? Why ?

It's strongly recommanded to generate a private key with a passphrase. The key you just generated is then weak.
Remove the tile and redo exactly the same thing but add the parameter `-aes256`. This parameter will encrypt the private key using the
symmetric encryption provided by _AES256_ algorithm. Thus, even if your private key is compromised, the adversary will need your
passphrase to use it. Keep the password in mind, it will be required !

Now you can start derivating public keys from the private key with the command `openssl pkey -pubout -in private_key.pem -out public_key.pem`.
Since you need the private key, the prviously set passphrase is asked. Look at the content of the public key.
Share the public key with the sysadmin.

5. How did you share the public key? Is it risky ?

The sysadmin is now able to encrypt the secret message (s)he wants to share with the developer by using the public key. To do so, run
the command: `openssl rsautl -encrypt -inkey adminsys_pubkey.pem -pubin -out mdp.enc`. Type your secret message on `stdin` then do
`CTRL+D` once you're done.

Explanations of the previous command:
* rsautl: The module _RSA utils_ is invoked.
* encrypt: Encryption mode
* inkey: Use this public key
* pubin: Tell the _inkey_ parameter is a public key
* out: Output file

As you can see, the output is a binary file. Now you can share this file with the developer so (s)he can decrypt the message.

6. When do you think it's more suitable to use symmetric encryption or asymmetric encryption ?

GNU Privacy Guard (GPG)
-----------------------

`openssl` is a very complete tool but may be a bit painful to use daily. It can also be dangerous to use if you don't understand
what you are doing, for instance if you choose weak algorithms.

Mot of the time the [OpenPGP](https://www.openpgp.org/about/) standard is chosen when humans share secrets together. The OpenSource tool
`gpg` provides easy-to-use and safe cryptography features.

As `openssl`, `gpg` supports both symmetric and asymmetric encryption.

### Symmetric Encryption

Such as previously, the sysadmin needs to send an encrypted secret to the developer.
The `gpg` tool is much more intuitive. The command to run is quite simple: `gpg --symmetric --pinentry-mode=loopback -a`.
The parameter `--pinentry-mode` is mandatory and allows to enter password in command line (by default, this is considered as unsecured).
The `-a` parameter encodes the output using the _base64_ encoding just like `openssl`.

>Note: _OpenPGP_ [picks the best algorithm](https://tools.ietf.org/html/rfc4880#section-5.3) if you don't specify any (_AES256_ i.e.).

7. After entering the password, type the secret message to share with the developer then hit `CTRL+D`. What differences do you see with `openssl` ?

Share the encrypted output and the password to the developer so (s)he can decrypt the message. Easy peasy: `gpg --decrypt --pinentry-mode=loopback`
then copy/paste the encrypted message in `stdin` (the `------BEGIN PGP MESSAGE------` header is required).

### Asymmetric Encryption

Just like `openssl`, you need to generate both the private and public keys on the developer computer. While the developer proceeds, the
sysadmin can also generate his/her own private and public keys since it's going to be useful.
Run the command: `gpg --gen-key --pinentry-mode=loopback`.

8. By default, which algorithm is picker and how long is the key ? How many time your key is valid ?


If `gpg` is as popular, this is because it does provide an easy management of the recipients based on a _keyring_. This is why you had
to enter a name and an email address. You can see also that `gpg` ask you to enter a passphrase by default to protect your private key
and that your key expires in 2 years. By default, security best practices are followed.
You can now list all your private keys (`gpg --list-secret-keys`) and public keys (`gpg --list-keys`).
In both cases, you should se your own key with a trust level set to _ultimate_.

To share your keys (both sysadmin and developer have to share their keys), you can export your key using : `gpg -a --export adresse@mail`.
To import the key in your keyring, use: `gpg --import` then paste the public key to import in  `stdin`. Then hit `CTRL+D`. 

List the public keys once again to see the imported key in your keyring :
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

The sysadmin is now ready to encrypt the secret message to be send to the developer: `gpg -a --encrypt --recipient dev@target.lxc`.
The developer's public key is not trusted by default. A message ask you if you're sure you want to trust this key. Accept then type
the secret message on `stdin` then hit `CTRL+D`.

> Protips: If you want to be friendly with your recipient, add some empty lines at the end of your message before hitting `CTRL+D`.
> It's much more convenient to read afterwards.

Send the encrypted message to the developer so (s)he can decrypt it.

9. Compare quickly `openssl` et `gpg`. Do you agree that `gpg` is easier to use than `openssl` ? Why ?
10. Are you able to tell that this is the sysadmin who sent you the secret message ? Take an example to show why.

Sign Message
============

As seen during the course, the confidentiality is not the only matter that cryptography tries to solve. You are going now to prove
a message has been produced by a trusted party and that the message has not been tampered. Let's say the sysadmin and the developer
a good friends and they shared their secret keys so they are sure these keys are trustfull.

To achieve this trust, the sysadmin and the developer need to change the trust associated to the public keys:
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

The signature is going to be used to make sure a message has been written by the sysadmin and is sent to the developer. `gpg` provides
several signature methods:
- Sign & encrypt: the message is encrypted and signed (`--sign`)
- Sign only: the message is only signed, not encrypted. Only check the content has not been tampered (`--clear-sign`)
- Detached signature without encryption: The signature is produced in a separate file (`--detach-sign`)

Use the `--clear-sign` parameter since this is mode the most used. Let's imagine the developer wants to acknowledge (s)he did receive
the secret message. Share the output to the sysadmin.

The sysadmin can check the message has been issued by the developer with the command `gpg --verify` (the date of the signature is
recorded as well as you can see).

11. Let's imagine the message has been intercepted and tampered by Charly. To fake this case, change the message by hands and re-run the command. What happen ?

**Take few minutes with your teacher to sum-up this part.**

SSH Connection Encryption
=========================

Humans share their secret using the techniques seen previously. In this part, you are going to see how machine-to-machine connections
are secured, especially the _SSH_ protocol.

>Reminder: _SSH_, or _Secure SHell_, is a protocol and a tool providing a way to connect remotely and securely to devices. This is the
>most common way to administrate remote devices.

The _Target_ system administrator job is to maintain all the machines of the company. To achieve his/her mission, remote connections
are often required. In this part, you are going to help the sysadmin to improve the security of the configuration of SSH.

Connect on the sysadmin computer with the _admin_ user (`./mi-lxc.py attach admin@target-admin`).

Try to connect to the sale computer. In the [previous work](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP2-Firewall-EN.md),
you have probably implemented _iptables_ rules as well as subnets. Take your notes to find which IP is assigned to this machines and try
to connect to it using SSH (`ssh commercial@ip`). A first question asks you if you trust the machine havind a ECDSA fingerprint. Then
a password is required (which is _commercial_).

12. What is ECDSA ?
13. What this fingerprint refers to ?
14. What is this password ? Are there any link between this password and the cryptography to make the connection secure ?
15. In your opinion, is it a good idea to leave the password authentication with such passwords ?

Unfortunatly, sometimes you can't do anything you want. In this case, the password cannot be change because the CEO ask you to leave
the commercial password as it is. You need to find another way.

> The biggest risk when performing remote actions on a device is to lose permanently the access by changing the configuration and
> block your remote access. Think twice before committing your changes.

As seen in course, the public key authentication is prefered rather than using passwords. Denying the connection to the  _root_ user
and using a _admin_ user granted in _[sudoers](https://www.digitalocean.com/community/tutorials/how-to-edit-the-sudoers-file-fr)_ is
also a good practice you are going to implement.

16. Define an action plan to put in place on the commercial computer. ***Ask your teacher***

> Note 1: The configuration of _sshd_ daemon is done in `/etc/ssh/sshd_config`.

> Note 2: If you want to use RSA keys, take care of the minimal length of the key (>= 3072 bits).

> Note 3: You may need some useful tools such as [`ssh-keygen`](https://linux.die.net/man/1/ssh-keygen) or [`ssh-copy-id`](https://linux.die.net/man/1/ssh-copy-id)

> Note 4: You may need to edit you public key and/or the file [`authorized_keys`](https://manpages.debian.org/experimental/openssh-server/authorized_keys.5.en.html#from=_pattern-list_) 
> to apply restrictions.

