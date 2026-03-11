# 🌿 Bonobo — Agrégateur d'Actualités Congolaises

Application mobile Flutter (Android & iOS) qui agrège les actualités de dizaines de médias congolais et d'Afrique centrale.

## Démarrage rapide

```bash
flutter pub get
flutter run
```

## Stack

- **Flutter 3.x** (Dart) — UI
- **Riverpod** — State management
- **GoRouter** — Navigation
- **Dio** — HTTP (feeds WordPress + RSS)
- **Hive** — Cache local & mode offline
- **connectivity_plus** — Détection réseau
- **google_fonts** — Typographie (Poppins, Inter)
- **cached_network_image** — Images
- **webfeed_plus** — Parsing RSS

## Structure du projet

```
lib/
├── main.dart
├── app/                 # Router, thème, MaterialApp
├── core/                # Constantes, services, utils
├── features/
│   ├── news/            # Flux, slider héros, détail article
│   ├── categories/      # Catégories thématiques
│   ├── jobs/            # Offres d'emploi (Médias Congo)
│   ├── sports/          # Résultats & matchs (API-Football)
│   ├── journalist/      # Espace journaliste (Phase 3)
│   ├── media/           # Détail d'un média + abonnement
│   └── settings/       # Préférences, notifications
└── shared/              # Widgets communs, stockage local
```

## Fonctionnalités MVP

- [x] Flux d'actualités (WordPress + RSS), modèle `FeedNews` unifié
- [x] Slider héros (8 articles), tabs temporels (< 1h, 1h–4h, 4h–8h, Tout)
- [x] Cache Hive + mode hors-ligne + bannière connectivité
- [x] Détail article (partage, traduction placeholder, s'abonner au média)
- [x] Navigation 5 onglets (Accueil, Catégories, Emplois, Sport, Journaliste)
- [x] Catégories thématiques (Politique, Économie, Sport, etc.)
- [x] Page détail média + abonnements (stockage local)
- [x] Offres d'emploi (liste mock ; intégration Médias Congo en Phase 2)
- [x] Section Sport (UI mock ; API-Football en Phase 2)
- [ ] Export PDF (service prêt, à brancher sur le bouton)
- [ ] Notifications FCM (Phase 2)
- [ ] Auth journaliste Firebase (Phase 3)

## Sources de données

Les feeds sont définis dans `lib/core/constants/media_sources.dart` (Zoomeco, OkapiNews, Actu30, InfosCD, ScoopRDC, FootRDC, Radio Okapi, etc.).  
Récupération parallèle avec timeout 10 s par feed ; déduplication par URL.

## Variables d'environnement

Créer un fichier `.env` à la racine (optionnel pour le MVP) :

```
GOOGLE_TRANSLATE_API_KEY=...
API_FOOTBALL_KEY=...
```

## Charte graphique

- **Vert principal** : `#01732C` (primaryGreen), dégradé `#4ADE80` → `#036027`
- **Fond sombre** : `#1A1A2E`
- **Typo** : Poppins (titres), Inter (corps) via `google_fonts`

## Licence

Projet Meyllos — Documentation technique v1.0.
# bonobo-app
# bonobo-app
