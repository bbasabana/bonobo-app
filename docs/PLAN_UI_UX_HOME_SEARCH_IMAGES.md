# Plan d'implémentation UI/UX — Home, Recherche & Qualité d'image

**Contexte :** Application agrégateur d'actualités (multi-sources). Objectif : design moderne, puissant, orienté expérience lecteur.

---

## 1. News Slider & Message « Nous actualisons »

### Objectif
Renforcer la perception d’une app « vivante » : pendant la consultation du slider, afficher périodiquement un message discret indiquant que les contenus sont mis à jour.

### Tâches

| # | Tâche | Détail | Priorité |
|---|--------|--------|----------|
| 1.1 | **Modal / Snack « Actualisation »** | Toutes les 10 secondes (configurable), afficher un message court : « Nous actualisons la rubrique » ou « Mise à jour en cours… ». Style : petit modal centré ou snack en bas, fond semi-transparent, typo courte, auto-dismiss 2–3 s. | P0 |
| 1.2 | **Éviter le spam** | Ne pas afficher si l’utilisateur a interagi récemment (ex. scroll, tap) ou si la vue n’est pas visible. Option : afficher seulement après 2–3 cycles du slider. | P1 |
| 1.3 | **Cohérence charte** | Couleurs Bonobo (vert #01732C), bords arrondis, pas de blocage de l’UI (non modal bloquant). | P0 |

### Livrables
- Widget réutilisable `ActualisationMessage` ou intégration dans le `HeroSliderWidget`.
- Timer 10 s dans le state du slider (ou du parent Home), affichage du message puis reset du timer.

---

## 2. Recherche avancée (agrégateur multi-sources)

### Objectif
Une recherche « puissante, avancée » : par titre, source, catégorie, date ; interface moderne type app d’actualité.

### Tâches

| # | Tâche | Détail | Priorité |
|---|--------|--------|----------|
| 2.1 | **Écran / overlay Recherche** | Au clic sur l’icône recherche (AppBar home) : ouvrir un écran dédié ou un bottom sheet plein écran. Barre de recherche en haut, résultats en dessous. | P0 |
| 2.2 | **Champ de recherche** | Champ avec debounce (300–400 ms), placeholder « Rechercher dans tous les médias », icône search, bouton effacer. Design : fond légèrement différencié, bords arrondis. | P0 |
| 2.3 | **Recherche full-text (titre + excerpt)** | Filtrer côté client (ou API si backend) sur `title` et `excerpt` (et `content` si souhaité) pour tous les articles en cache + dernier fetch. Insensible à la casse, trim, mots partiels. | P0 |
| 2.4 | **Filtres avancés** | Chips ou dropdowns : par **source** (média), par **catégorie**, par **période** (24h, 7j, 30j). Les filtres se combinent avec le texte. | P1 |
| 2.5 | **Affichage des résultats** | Liste ou grille de cartes (même style que la home). Indication « X résultats » et, si 0, message + illustration ou suggestion (ex. « Essayez un autre mot-clé ou une autre source »). | P0 |
| 2.6 | **Performance** | Pour gros volumes : recherche sur liste déjà chargée (Riverpod), pas de re-fetch à chaque keystroke. Option future : recherche côté backend si endpoint dédié. | P1 |
| 2.7 | **Historique / suggestions** | Optionnel : derniers termes recherchés (stockage local), ou suggestions par catégorie. | P2 |

### Livrables
- Écran ou route `/search` (ou overlay).
- Provider ou notifier `SearchNotifier` : `query`, `filters` (sourceId, category, dateRange), `results` (liste dérivée de `newsListProvider`).
- UI : `SearchScreen` avec `SearchBar`, filtres, `SearchResultsList`.

---

## 3. Qualité d’image des articles

### Objectif
Quand un article a une image, l’afficher en **très bonne qualité** (nette, sans pixellisation sur écrans haute densité).

### Tâches

| # | Tâche | Détail | Priorité |
|---|--------|--------|----------|
| 3.1 | **Haute résolution** | Utiliser `cached_network_image` avec une taille cible suffisante pour l’affichage. Pour une largeur d’écran W : demander au moins `W * devicePixelRatio` (ex. 2.0 ou 3.0). Éviter de forcer une résolution trop basse. | P0 |
| 3.2 | **URLs WordPress** | Si la source expose des URLs avec paramètre `?w=400`, remplacer par `?w=800` ou `?w=1200` pour le détail et le hero. Si l’API renvoie `media_details.sizes.large`, utiliser cette URL. | P0 |
| 3.3 | **Cache et placeholder** | Garder `BonoboArticleImage` avec placeholder `bonobo_load_bg.jpg`. Cache Hive/disk inchangé ; `cached_network_image` gère le cache mémoire/disque. | P0 |
| 3.4 | **Hero slider** | Images du slider en plein écran : qualité maximale (ex. largeur = screen width * pixelRatio). | P0 |
| 3.5 | **Détail article** | Image hero en haut de l’article : même règle, haute résolution. | P0 |

### Livrables
- Helper ou extension pour « upscaler » l’URL d’image (WordPress, etc.) vers une taille `width` demandée.
- Dans `BonoboArticleImage` et `HeroSliderWidget` : passer une taille cible en pixels physiques (ou utiliser `cacheWidth` / `cacheHeight` avec valeurs élevées).
- Vérifier que les URLs utilisées pour l’image ne sont pas redimensionnées côté serveur en trop petit (ex. 300px) ; si oui, documenter et utiliser la meilleure URL disponible.

---

## 4. Ordre d’implémentation recommandé

1. **Qualité d’image** (3.1, 3.2, 3.4, 3.5) — impact direct sur le slider et le détail.
2. **Message « Nous actualisons »** (1.1, 1.2, 1.3) — rapide, améliore la perception.
3. **Recherche** (2.1 → 2.5, puis 2.4, 2.6) — écran + logique + filtres.

---

## 5. Checklist design « moderne actualité »

- [x] Slider : message d’actualisation discret toutes les 10 s.
- [x] Recherche : écran dédié, debounce, full-text titre + excerpt, filtres source/catégorie/période.
- [x] Images : haute résolution (devicePixelRatio, URLs large), hero et détail.
- [x] Charte : vert #01732C, blanc, cohérence typo et espacements.
- [ ] Accessibilité : contraste, taille de touch targets, lecteur d’écran si besoin.

---

*Document à mettre à jour au fil de l’implémentation.*
