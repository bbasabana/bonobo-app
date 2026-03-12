# Nouveautés & idées pour captiver les utilisateurs

Charte graphique : à respecter sur tous les écrans (couleurs Bonobo, typo, toasts soft).

---

## Inscription & authentification utilisateurs

- **Utilisateurs** : peuvent s’inscrire / se connecter (écran **Mon compte**, icône profil en barre d’accueil) via **email + OTP** ou **Facebook, Google**, sans mot de passe. Voir **backend-api-auth.md**.
- **Journalistes** : même mécanisme depuis l’onglet **Espace journaliste**, avec rôle `journalist`.
- Cela permet de connaître **le nombre d’utilisateurs** et **le nombre de journalistes**, et d’associer lectures/partages à des comptes (voir **backend-api-analytics.md**).

---

## 1. Notifications

### Quand il y a des articles
- **In-app** : badge sur l’icône Actualités ou petit point « Nouveaux articles » après un refresh.
- **Toast soft** : « X nouveaux articles » après mise à jour en arrière-plan (déjà en place côté connectivité / cache).

### Notification push (même app fermée)
- **Firebase Cloud Messaging (FCM)** : envoyer une push quand de nouveaux articles sont publiés (par média ou par catégorie selon abonnements).
- **Contenu de la notification** : titre court + source (ex. « Zoomeco : titre de l’article »).
- **Clic** : ouvrir l’app sur l’article ou sur le fil du média.
- **Options** : dans Paramètres, permettre d’activer/désactiver par média et de choisir « Résumé quotidien » vs « En temps réel ».

---

## 2. Article le plus lu (stats pays / région)
- **Backend** : enregistrer des vues (anonymisées ou par user_id) par article, avec pays/région (ex. via IP ou paramètre app).
- **Endpoint** : `GET /api/v1/stats/most-read?country=CD&region=Kinshasa&period=7d`.
- **App** : section « Les plus lus » (pays ou région) sur l’accueil ou dans Catégories, avec petite icône « 🔥 » ou « Top ».
- **Charte** : cartes avec style existant, badge vert « Le plus lu ».

---

## 3. Commentaires « intelligents » (au lieu du classique)
- **Modération** : tous les commentaires passent par une modération (backend) ou par des règles (mots bloqués, signalement).
- **Affichage** : pas seulement fil chronologique ; mise en avant des « meilleurs » (likes, pas de troll), ou « Commentaires de la rédaction ».
- **Innovation** : résumé IA des commentaires (optionnel) : « En bref : les lecteurs soulignent… » sous l’article.
- **Partage** : permettre de partager un commentaire (lien deep link vers article + commentaire).

---

## 4. Partager (share)
- Déjà en place : partage d’article (texte + lien) et export PDF.
- **Amélioration** : bouton « Partager » bien visible sur chaque carte et dans le détail, avec aperçu (Open Graph) si le backend expose des meta pour le lien.

---

## 5. Idées supplémentaires pour captiver

- **Résumé du jour** : notification ou section « En 3 minutes » (3–5 titres + liens) le matin.
- **Mode « Sans spoiler »** : masquer les titres des articles sport (résultats) jusqu’au clic.
- **Favoris / Lire plus tard** : sauvegarde locale + option sync backend (liste « À lire »).
- **Thème** : respect strict de la charte (vert, fond sombre, toasts soft) partout.
- **Onboarding** : au premier lancement, « Choisir vos médias » (déjà en place) + « Activer les notifications ».
- **Badges / Gamification** : « Vous avez lu 10 articles cette semaine », partage d’un article débloque un badge, etc. (optionnel).

---

## 6. Stats & analytics (articles lus, provenance, médias, partages)

- **Qui lit quoi, d'où** : événement `article-view` (pays, région) → voir **backend-api-analytics.md**.
- **Média le plus lu** : agrégation par `sourceId` côté backend.
- **Partages (comment)** : événement `article-share` avec `shareMethod` (lien, PDF, WhatsApp, etc.).
- **Articles top, journalistes top** : endpoints de stats (most-read, journalists/top). L'app envoie les événements ; le backend agrège.

L'app appelle déjà `AnalyticsService.trackArticleView` et `trackArticleShare` (stub à brancher sur l'API).

---

## 7. Emplacement publicitaire

- **Espace réservé** : bandeau sur l'accueil (entre hero et médias), widget `AdPlaceholder` (charte respectée). Voir **ESPACE_PUBLICITAIRE.md**.
- À remplacer par une vraie bannière (AdMob, partenaire) pour vendre des emplacements pub.

---

## 8. Récap technique

| Fonctionnalité              | Côté app (Flutter)              | Côté backend / services     |
|----------------------------|----------------------------------|-----------------------------|
| Push (app fermée)          | FCM + deep link                 | Service d’envoi de pushes    |
| Articles en local          | Toast + mention « en cache »    | —                           |
| Connexion OTP / social     | Écran journaliste (fait)        | API auth (voir backend-api-auth.md) |
| Choix des médias           | Écran « Choisir mes médias »   | — (abos en local ou API)    |
| Article le plus lu         | Section dédiée                  | API stats + enregistrement vues |
| Commentaires intelligents  | UI commentaires + partage      | Modération + optionnel IA   |

Tout nouveau écran ou composant doit respecter la **charte graphique** (couleurs, toasts soft, bordures, ombres déjà définis).
