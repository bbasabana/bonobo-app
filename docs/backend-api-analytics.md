# Backend API — Analytics & Statistiques

Ce document décrit comment remonter les **événements** depuis l’app et comment le backend peut exposer des **statistiques** : nombre d’utilisateurs/journalistes, articles lus, provenance, médias les plus lus, partages, articles top, journalistes top.

---

## 1. Événements envoyés par l’app (à enregistrer côté backend)

L’app envoie ces événements (avec token utilisateur si connecté, ou identifiant anonyme) pour alimenter les stats.

### 1.1 Inscription / Connexion

- Déjà géré par l’auth : chaque `verify-otp` ou `auth/social` crée ou met à jour un compte → comptage **utilisateurs** et **journalistes** (voir backend-api-auth.md).

### 1.2 Lecture d’un article

À chaque ouverture d’un article (écran détail) :

```http
POST /api/v1/events/article-view
Content-Type: application/json
Authorization: Bearer <token>   # optionnel si utilisateur connecté

{
  "articleId": "zoomeco_12345",
  "sourceId": "zoomeco",
  "sourceName": "Zoomeco",
  "publishedAt": "2025-06-01T10:00:00Z",
  "userId": "usr_xxx",           # si connecté, sinon absent
  "anonymousId": "device_xxx",   # si non connecté (stockage local)
  "country": "CD",               # optionnel : pays (géoloc ou paramètre)
  "region": "Kinshasa",          # optionnel : région
  "at": "2025-06-01T12:05:00Z"
}
```

- Permet de savoir : **qui lit quoi**, **d’où** (pays/région), **quel média** (`sourceId`) est le plus lu.

### 1.3 Partage d’un article

Quand l’utilisateur partage (bouton Partager ou Export PDF) :

```http
POST /api/v1/events/article-share
Content-Type: application/json
Authorization: Bearer <token>

{
  "articleId": "zoomeco_12345",
  "sourceId": "zoomeco",
  "shareMethod": "link",         # "link" | "pdf" | "whatsapp" | "twitter" | ...
  "userId": "usr_xxx",
  "anonymousId": "device_xxx",
  "at": "2025-06-01T12:06:00Z"
}
```

- Permet de savoir : **comment** les articles sont partagés (lien, PDF, réseau social).

### 1.4 Publication d’un article (journaliste)

Lorsqu’un article journaliste est approuvé et publié :

```http
POST /api/v1/events/article-published
# Côté backend / back-office, à la publication

{
  "articleId": "art_xxx",
  "journalistId": "usr_yyy",
  "sourceId": "journalist",
  "publishedAt": "2025-06-01T14:00:00Z"
}
```

- Permet de compter le **nombre d’articles publiés** par journaliste et au total.

---

## 2. Endpoints de statistiques (dashboard / admin)

Ces endpoints servent un **back-office** ou des **écrans dédiés** (ex. « Articles les plus lus », « Médias les plus lus »). Ils peuvent être protégés (admin) ou partiellement publics (ex. « Top articles » en lecture seule).

### 2.1 Nombre d’utilisateurs et de journalistes

```http
GET /api/v1/stats/counts
```

Réponse exemple :

```json
{
  "users": 12500,
  "journalists": 340
}
```

### 2.2 Articles les plus lus

```http
GET /api/v1/stats/articles/most-read?period=7d&country=CD&limit=20
```

- `period` : `24h`, `7d`, `30d`.
- `country` : optionnel (ex. `CD`).
- `region` : optionnel.

Réponse exemple :

```json
{
  "items": [
    {
      "articleId": "zoomeco_12345",
      "sourceId": "zoomeco",
      "sourceName": "Zoomeco",
      "title": "...",
      "viewCount": 1520,
      "shareCount": 89,
      "country": "CD",
      "period": "7d"
    }
  ]
}
```

### 2.3 Médias les plus lus

```http
GET /api/v1/stats/media/most-read?period=7d&country=CD&limit=10
```

Réponse exemple :

```json
{
  "items": [
    { "sourceId": "zoomeco", "sourceName": "Zoomeco", "viewCount": 45000, "articleCount": 120 },
    { "sourceId": "okapinews", "sourceName": "OkapiNews", "viewCount": 38000, "articleCount": 95 }
  ]
}
```

### 2.4 Journalistes les plus lus (articles publiés + vues)

```http
GET /api/v1/stats/journalists/top?period=30d&limit=20
```

Réponse exemple :

```json
{
  "items": [
    {
      "journalistId": "usr_yyy",
      "displayName": "Jean Dupont",
      "articlesPublished": 12,
      "totalViews": 8500,
      "mostReadArticleId": "art_xxx"
    }
  ]
}
```

### 2.5 Partages par canal

```http
GET /api/v1/stats/shares/by-method?period=7d
```

Réponse exemple :

```json
{
  "link": 1200,
  "pdf": 340,
  "whatsapp": 890,
  "twitter": 120
}
```

### 2.6 Provenance géographique (lectures)

```http
GET /api/v1/stats/geo/views?period=7d
```

Réponse exemple :

```json
{
  "byCountry": [
    { "country": "CD", "count": 45000 },
    { "country": "FR", "count": 8000 }
  ],
  "byRegion": [
    { "country": "CD", "region": "Kinshasa", "count": 28000 },
    { "country": "CD", "region": "Lubumbashi", "count": 9000 }
  ]
}
```

---

## 3. Récapitulatif

| Besoin métier | Événement / Source | Endpoint stats (exemple) |
|---------------|--------------------|---------------------------|
| Nombre utilisateurs / journalistes | Auth (comptes) | `GET /stats/counts` |
| Qui lit quoi, d’où | `article-view` | `GET /stats/articles/most-read`, `GET /stats/geo/views` |
| Quel média le plus lu | `article-view` par sourceId | `GET /stats/media/most-read` |
| Partages, comment | `article-share` (shareMethod) | `GET /stats/shares/by-method` |
| Articles top | Vues sur articles | `GET /stats/articles/most-read` |
| Journalistes top, articles publiés les plus lus | `article-published` + vues | `GET /stats/journalists/top` |

L’app Flutter doit envoyer **article-view** et **article-share** aux endpoints d’événements ; le backend agrège et expose les endpoints de stats pour dashboard et rapports.
