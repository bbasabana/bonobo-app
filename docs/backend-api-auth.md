# Backend API — Inscription & Authentification (Utilisateurs & Journalistes)

Ce document décrit les endpoints pour que **les utilisateurs** et **les journalistes** puissent **s’inscrire** et **s’authentifier** (sans mot de passe : OTP par email ou réseaux sociaux). Cela permet de connaître les nombres d’utilisateurs et de journalistes, et d’associer les lectures/partages à des comptes.

---

## Rôles

| Rôle         | Usage                                      |
|--------------|--------------------------------------------|
| `user`       | Lecteur : inscription/connexion pour stats, favoris, notifs |
| `journalist` | Création de compte journaliste pour publier des articles   |

Les **mêmes endpoints** servent les deux : le rôle est déterminé soit par un paramètre (ex. `?role=journalist` sur l’inscription), soit par un flux dédié (ex. écran « Espace journaliste » → rôle `journalist`).

---

## 1. Envoi du code OTP (email)

Utilisé pour **utilisateur** et **journaliste**.

### Requête

```http
POST /api/v1/auth/send-otp
Content-Type: application/json

{
  "email": "utilisateur@example.com",
  "role": "user"
}
```

- `role` : `"user"` (défaut) ou `"journalist"`.

### Réponse succès (200)

```json
{
  "success": true,
  "message": "Code envoyé",
  "expiresIn": 600
}
```

### Réponse erreur (4xx)

- `400` : email invalide.
- `429` : trop de demandes (rate limit).

---

## 2. Vérification OTP et création / connexion de compte

### Requête

```http
POST /api/v1/auth/verify-otp
Content-Type: application/json

{
  "email": "utilisateur@example.com",
  "otp": "123456"
}
```

Le backend détermine si le compte existe déjà (connexion) ou non (création). Le rôle a été fixé à l’envoi de l’OTP (lien ou contexte « journaliste » vs « utilisateur »).

### Réponse succès (200)

```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "...",
  "user": {
    "id": "usr_xxx",
    "email": "utilisateur@example.com",
    "role": "user",
    "displayName": null,
    "avatarUrl": null,
    "createdAt": "2025-06-01T12:00:00Z"
  },
  "expiresIn": 3600
}
```

Pour un journaliste, `role` sera `"journalist"`.

---

## 3. Connexion avec Facebook / Google

```http
POST /api/v1/auth/social
Content-Type: application/json

{
  "provider": "google",
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "role": "user"
}
```

- `role` : `"user"` ou `"journalist"` selon l’écran (inscription utilisateur vs espace journaliste).

Réponse : même forme que `verify-otp` (`token`, `refreshToken`, `user`).

---

## 4. Rafraîchissement du token

```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "..."
}
```

---

## 5. Comptage utilisateurs et journalistes

Pour connaître **le nombre d’utilisateurs** et **le nombre de journalistes** :

- Stocker en base chaque compte avec un champ `role` (`user` | `journalist`).
- Exposer des endpoints (ex. admin/dashboard) ou des agrégats :
  - **Utilisateurs** : `COUNT(*) WHERE role = 'user'`.
  - **Journalistes** : `COUNT(*) WHERE role = 'journalist'`.

Les événements (lectures, partages, etc.) sont décrits dans **backend-api-analytics.md**.

---

## 6. Récapitulatif

| Endpoint           | Méthode | Usage                                      |
|--------------------|--------|--------------------------------------------|
| `/auth/send-otp`   | POST   | Envoyer code OTP (user ou journalist)       |
| `/auth/verify-otp` | POST   | Vérifier OTP, créer/connexion, retour token|
| `/auth/social`     | POST   | Connexion Facebook / Google (user ou journalist) |
| `/auth/refresh`    | POST   | Renouveler le token                         |

L’app Flutter envoie `role` selon l’écran (inscription utilisateur vs espace journaliste) et stocke le token pour les appels authentifiés et l’envoi des événements analytics.
