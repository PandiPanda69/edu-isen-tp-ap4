# Etude de cas - Le mini-SMSI

_Sébastien Mériot_

Durée: 3h30

## Contexte

### Scénario 

Vous êtes consultants en société de conseil en cybersécurité avec une approche plutôt gouvernance. Un client, acteur montant de la fintech, vous sollicite pour l'aider à structurer son _Système de Management de la Sécurité de l'Information_.

Ce client, c'est __Fin'invest__, un éditeur de logiciel d'une centaine de personnes qui développe le logiciel __Simulpret__ utilisé par la majorité des courtiers et des assurances françaises pour évaluer la capacité d'emprunt des particuliers.

__Fin'invest__ se voit challenger par ses clients sur la sécurité des données. N'ayant aujourd'hui aucun _SMSI_, la société a recruté un _RSSI_ afin de démarrer une démarche inspirée de _ISO27001_ afin de rassurer ses clients avec une cible de certification d'ici 2 ans. C'est ce _RSSI_ qui vous mandate pour l'aider dans cette mission. 

### Informations sur l'entreprise

Le logiciel traite:
- __des données personnelles__ (identité, revenus, situation familliale, charges, historiques financiers, ...)
- il produit une recommandation utilisée dans un processus bancaire réglementé.

L'infrastructure est hébergée dans le cloud en utilisant les solutions __Public Cloud__ de _Scaleway_ et _OVHcloud_ et est administrée par une équipe de 10 SRE. C'est la seule équipe disposant d'une astreinte.
La solution est développée par une équipe de 25 personnes (développeurs et architectes) utilisant un `gitlab` hébergé chez _OVHcloud_ pour versionner les sources, solution qui a été adoptée afin d'éviter d'avoir à configurer un _VPN_ pour permettre le télétravail.

Les employés bénéficient de 3 jours de télétravail par semaine avec un parc de postes hétérogènes sous __Windows__ et __Linux__ gérés par une petite équipe IT interne de 3 personnes. Le _BYOD_ est également autorisé pour le personnel qui préfère travailler avec son propre matériel.

## Travail demandé

Vous allez tous ensemble construire le SMSI de __Fin'invest__ en vous voyant affecter chacun un périmètre de l'entreprise à étudier. Concrètement, chaque groupe devra produire :

- Une analyse de risques cyber simplifiée en identifiant les 3 plus gros risques  (sous forme de tableau)
- Une politique thématique avec les mesures de contrôle associées (2 pages max)
- Un court paragraphe indiquant en quoi ces mesures répondent aux risques identifiés.

Le format du rendu devra être un fichier au format __PDF__.

### Les thématiques

Chaque groupe doit choisir une thématique. __Il n'est pas possible que plusieurs groupes travaillent sur la même thématique.__

Les thématiques sont les suivantes:
- Sécurité du poste de travail
- Gestion des identités et authentification
- Sécurité du réseau et des accès distants
- Sécurité physique des bureaux et du télétravail
- Gestion des serveurs de production
- Gestion des sources et du déploiement
- Gestion des sauvegardes

### Analyse de risques cyber

Réalisez une analyse de risques cyber simplifiée sous forme de tableau ayant les informations suivantes :
- Actifs (_Assets_)
- Évènements redoutés (scénario)
- Source de menaces
- Impact (échelle de 1 à 3)
- Probabilité d'occurence (échelle de 1 à 3)
- Niveau de risque (calculé en faisant `impact x probabilité`)

Listez jusqu'à 10 risques cyber puis, sélectionnez les 3 risques les plus importants en justifiant votre choix par un paragraphe.

### Les mesures de contrôle associées

À partir des risques précédemment identifiées, et en tenant compte proposez 10 mesures de contrôle (organisationnelles, techniques ou physiques) permettant de diminuer le niveau de risque des risques identifiés précédemment. Votre production devra être sous forme de tableau ayant les entrées suivantes :
- Référence de la mesure de contrôle (M01, M02, ...)
- Intitulé
- Description
- Quel risque/scénario cette mesure permet d'adresser

### Rédaction d'une politique

Rédiger une politique permettant de cadrer les obligations et les responsabilités sur votre thématique en reprenant les mesures de contrôle précédentes. Cette politique doit être structurée de la sorte :
- Objectif
- Périmètre applicable (les actifs adressés)
- Principes généraux (les exigences dans les grandes lignes)
- Rôles et responsabilités (les personnes impliquées et leur rôle)
- Exigences de sécurité (détail des mesures de contrôle, mesure par mesure)
- Sanctions en cas de non-respect  (ce qui est prévu en cas de manquement)
