# Emplacement réservé pour la publicité

L’application réserve des **emplacements publicitaires** prêts à être vendus et remplis par un serveur de pub (AdMob, partenaire, etc.) tout en respectant la **charte graphique** Bonobo.

---

## Où c’est placé

- **Accueil** : un bandeau (56px de hauteur) entre le **slider héros** et la **ligne des médias**.  
  Fichier : `lib/shared/widgets/ad_placeholder.dart`, utilisé dans `HomeScreen`.

Vous pouvez en ajouter d’autres au même endroit (copier `AdPlaceholder`) ou dans d’autres écrans (liste d’articles, détail article, etc.).

---

## Composant actuel

- **Widget** : `AdPlaceholder`
- **Paramètres** : `height` (défaut 56), `label` (défaut "Espace publicitaire").
- **Style** : fond discret, bordure verte légère, icône + texte, conforme à la charte.

Pour afficher une **vraie pub** plus tard :

1. Remplacer `AdPlaceholder` par votre widget de bannière (ex. `AdMob`, widget custom qui charge une image/HTML).
2. Ou garder `AdPlaceholder` et lui passer une `child` optionnelle (image ou iframe) quand une campagne est active.

---

## Formats possibles à vendre

- **Bannière** : 320×50 ou pleine largeur (hauteur ~50–56) — déjà réservé sur l’accueil.
- **Rectangle** : ex. 300×250 entre deux blocs d’articles (ajouter un second `AdPlaceholder(height: 250)`).
- **Native** : carte « sponsorisée » dans le fil (même style que les cartes articles, avec label « Pub »).

Tous les emplacements doivent rester conformes à la charte (couleurs, bords arrondis, pas de contenu intrusif).
