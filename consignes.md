# Analyse de données RNA-seq

*Pour cette activité, travaillez en trinôme.*


## 1. Connexion au serveur

Avec votre identifiant, votre mot de passe et l'adresse IP du serveur, connectez-vous au serveur avec la commande :
```
$ ssh login@adresse-serveur
```

où `login` et `adresse-serveur` sont à adapter.

On rappelle que le caractère `$` en début de ligne représente l'invite de commande et n'est pas à taper.

À l'invite `login@adresse-serveur's password:` entrez le mot de passe. Attention, vous entrez le mot de passe en aveugle, c'est-à-dire sans voir les carctères que vous tapez.

Si tout se passe bien, votre nouvelle invite de commande devrait être :
```
(base) login@babyplasma:~$
```


## 1. Préparation des données

Votre répertoire utilisateur contient un répertoire `project` avec les données initiales.

Il manque cependant le script qui va automatiser l'analyse RNA-seq.

Déplacez-vous dans le répertoire `project` puis téléchargez le script d'analyse avec la commande :

```
$ wget https://raw.githubusercontent.com/pierrepo/MEG-UE5-rnaseq/master/workflow.sh
```

Vérifiez que la somme de contrôle MD5 du fichier que vous venez de téléchargez est bien :
```
b9b03aea7774909bbd1664bd18b6142a
```


## 2. Préparation des logiciels

Les outils trimmomatic, hisat2 et samtools nécessaires pour cette analyse RNA-seq ont été installés avec le gestionnaire conda, qui est désormais un standard en bioinformatique.

Pour que ces outils soient disponibles, entrez la commande :
```
$ conda activate rnaseq
```

Vérifiez par exemple que samtools est bien disponible en tapant la commande :
```
$ samtools --version
```

Quelle est la version de samtools ?


## 3. Lancement de l'analyse RNA-seq

Toujours depuis le répertoire `project`, entrez la commande :
```
$ bash workflow.sh
```

Nomalement l'analyse est lancée ! 


## 4. Rapport

Remplissez le fichier `report.txt`  avec les informations suivantes :

- Prénoms et noms des étudiants du trinôme.
- Identifiant de connexion attribué.
- Sommes de contrôle MD5 des fichiers .fastq.gz.
- Nombre de reads dans chaque fichier .fastq.gz.
- Somme de contrôle MD5 du fichier de résultats .log généré.

Téléchargez le fichier de rapport sur votre machine locale. Pour cela, lancez la commande suivante depuis un terminal de votre machine locale (vous n'êtes plus connectés au serveur) :
```
$ scp login@adresse-serveur:~/project/*.log ./
```





Déposez sur Moodle :
- le fichier `report.txt` complété,
- le fichier de résultats .log.




