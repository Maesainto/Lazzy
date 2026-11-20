# Lazzy — Marche ou Honte

Application iOS de la SAÉ 3, ISA NUM. Objectif : encourager la marche et contribuer à l’ODD 3.

## Lancer le projet

Ouvrir `Lazzy.xcodeproj`, choisir le schéma **Lazzy**, puis lancer avec **⌘R**. Le projet conserve sa cible iOS 27 et son équipe de signature existantes. Les nouveaux fichiers Swift et les images sont inclus automatiquement par les dossiers synchronisés Xcode.

Les configurations **Debug** et **Release** utilisent le nom **Lazzy** et l’identifiant déjà validé `fr.simon.salefranque.lazzy.test`, avec l’équipe Simon Salefranque. Le suffixe technique `.test` est conservé pour mettre à jour l’ancienne Lazzy Test et préserver ses données. L’ancienne installation `Simon.Lazzy` reste distincte et n’est pas remplacée.

Pour la migration locale depuis l’ancienne app, `LegacyDataImport` lit au lancement un manifeste `Documents/lazzy-legacy-import.plist` préparé depuis sa sauvegarde. Les images doivent être transférées avant ce manifeste. L’import conserve les préférences déjà renseignées, fusionne les preuves par nom de fichier sans doublon et conserve leurs dates d’expiration. Il retire le manifeste après traitement ; l’ancienne app n’est pas modifiée.

Sur iPhone physique, autoriser la lecture des pas, de la distance marche/course et de l’énergie active dans Santé. Dans le simulateur, le compteur reste à zéro et les autres mesures sont indisponibles. Aucun serveur ni VPN n’est nécessaire pour examiner les vues.

## Navigation

À la première ouverture, **Créer un compte** enregistre un profil local avec le pseudo choisi. Pour un profil déjà enregistré ou importé, **Continuer** conserve les données et ouvre l’accueil. Une fois cette étape validée, les prochains lancements ouvrent directement l’accueil. **Se connecter** indique que la connexion en ligne attend l’API.

- **Accueil** : nom du profil, bouton de profil, pas du jour, jauge animée et objectif personnel. L’encadré **Activité du jour** affiche la distance à pied en kilomètres, les calories actives en kilocalories et l’heure de lecture. Première lecture au chargement, puis actualisation en tirant vers le bas.
- **Le mur** : fond de pierre répété sur toute la page, photos épinglées et tomates réversibles uniquement. Le bouton rond « + » reste en bas au centre pendant le défilement et permet l’ajout par appareil photo ou sélecteur de photos iOS. Les noms et gages restent consultables en ouvrant une photo.
- **Groupes** : listes Groupes / Amis et classement sur une page dédiée. La roue dentée ouvre les paramètres (nom, photo et minimum de pas). Le « + » en bas ajoute un ami au groupe ; le bouton de retrait permet de retirer un membre après confirmation. Tous les membres peuvent effectuer ces actions pour le moment. Les groupes, leurs membres, leurs paramètres et les amis sont enregistrés localement et conservés après relancement, sans connexion à l’API.

La photo de profil en haut de l’accueil ouvre l’écran **Paramètre**. Le pseudo, la bio, l’objectif personnel et la photo de profil sont enregistrés localement. Changer l’objectif personnel ne modifie pas ceux des groupes.

Les preuves locales sont conservées sur l’iPhone et retirées après 24 h lors du prochain affichage du mur ou lancement. Aucune photo ni donnée de pas n’est envoyée sur le réseau. Les réactions sont conservées en mémoire pour la session. Les photos de démonstration sont générées ; elles ne représentent pas les étudiants du projet.

## Organisation MVC / UIKit

`SceneDelegate` ouvre l’écran de bienvenue jusqu’à sa validation, puis le contrôleur d’onglets de `Base.lproj/Main.storyboard`. Le storyboard définit les quatre scènes principales, leurs zones défilantes, les contraintes adaptatives et les liaisons `IBOutlet`. Les contenus de ces scènes sont assemblés en Swift avec UIKit et Auto Layout : ils s’affichent à l’exécution, pas entièrement dans l’aperçu Interface Builder.

- `ViewController.swift` : accueil et liaison à `HealthManager`.
- `Controllers/` : mur, groupes, classement et paramètres.
- `Views/` : palette et composants communs, sélection de photos.
- `Models/MockDataManager.swift` : modèles et exemples sociaux ; profil et preuves locales.
- `HealthManager.swift` : autorisation de lecture et totaux journaliers via `HKStatisticsCollectionQueryDescriptor` (échantillons chevauchant minuit inclus).
- `CircularProgressView.swift` : calques de jauge redimensionnés dans `layoutSubviews` et progression bornée.

`HealthKit` ne permet pas de distinguer un refus de lecture de l’absence de données : l’interface indique donc « aucun pas accessible » lorsque le résultat est nul.

L’encadré affiche « — » pour les mesures indisponibles. Les calories actives proviennent des mesures d’activité enregistrées dans Santé.

## Trophées et profils

En bas de l’accueil, **Mes trophées** affiche les 20 trophées et leurs conditions. Les trophées à débloquer sont grisés. Dans **Paramètre → Mes trophées**, on peut consulter sa progression et toucher la ligne d’un trophée obtenu pour équiper ou retirer son badge. Un seul badge est affiché à côté du pseudo, notamment sur l’accueil et le profil.

Le catalogue comprend 12 seuils journaliers (100 à 30 000 pas), 4 cumuls (25 000, 50 000, 100 000 et 250 000 pas enregistrés) et 4 nombres de journées validées (1, 3, 7 et 30, non nécessairement consécutives). Les pas sont enregistrés après une lecture Santé réussie : plusieurs lectures du même jour remplacent son total, sans le compter plusieurs fois. Une journée déjà validée le reste même si le minimum change. Les trophées acquis et le badge équipé sont conservés localement ; l’historique antérieur à cette fonctionnalité n’est pas reconstruit.

Dans **Amis**, toucher un profil affiche sa bio, son minimum personnel, ses pas et les trophées qu’il a obtenus. Les anciennes données restent compatibles : en l’absence de bio, l’écran affiche « Aucune bio ». Les données des amis restent locales en attendant l’API et n’attribuent aucun trophée au compte personnel.

## Vérification

Le projet Xcode contient une seule cible et un seul schéma **Lazzy**. Les sources de tests et la configuration Xcode permettant de les réactiver ont été déplacées dans le dossier voisin `Sauvegardes Lazzy/configuration-avec-tests-61b47bf7/`. Elles ne figurent plus dans le projet actif ; ⌘U n’est donc plus configuré. **⌘B** vérifie la compilation et **⌘R** lance l’app.

À vérifier sur iPhone : autorisation Santé, variation des pas après une marche, prise de photo avec la caméra physique.

## Suite : connexion à l’API

Gaël développe l’API Node.js / MySQL sur le réseau EVA, à l’adresse privée `10.3.16.176` (campus ou VPN). Aucun endpoint, port ou format de réponse n’est inventé dans cette version. La prochaine étape est de remplacer les exemples du `MockDataManager` par les réponses d’un service `URLSession`, quand le contrat de l’API sera disponible. Les règles de gage, l’expiration côté serveur et les invitations devront alors être gérées avec le backend.

Les documents de cadrage restent dans les dossiers voisins `presentation projet` et `étude avant projet`.
