# Content Agent

Transforme une feature réellement commitée en brouillons pour X, Threads et Substack.
Il n'invente rien, et il ne publie rien sans toi.

## Pourquoi ces trois couches

| Couche | Fichier | Rôle | Accès |
|---|---|---|---|
| **Developer Historian** | `historian.py` | Lit git et GitHub, produit une fiche factuelle | git, `gh` |
| **Content Writer** | `writer.py` | Transforme la fiche en brouillons | le modèle, **rien d'autre** |
| **Publisher** | `publisher.py` | Publierait, après approbation | rien pour l'instant |

La séparation n'est pas décorative : c'est ce qui rend l'invention structurellement
difficile. Le Writer ne reçoit **que** l'objet `FeatureFact` sérialisé — jamais le
dépôt, jamais le web, jamais tes données d'usage. Ce qui n'est pas dans la fiche ne
peut pas être écrit.

Et parce qu'un modèle peut toujours déraper, `guards.py` vérifie la sortie **après**
génération, mécaniquement, sans modèle :

- **chiffres** — tout nombre écrit doit exister dans la fiche ;
- **affirmations interdites** — métriques d'audience, revenus, témoignages, classements ;
- **longueurs** — 280 caractères sur X, 500 sur Threads ;
- **secrets** — clés API, tokens, e-mails, fichiers `.p8`.

Un brouillon qui échoue est **rejeté**, jamais corrigé en silence.

## Installation

```bash
cd scripts/content-agent
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

L'authentification suit le SDK : `ANTHROPIC_API_KEY`, ou un profil `ant auth login`.
Aucune clé n'est lue ni écrite par ce code.

## Utilisation

```bash
# Fiche factuelle seule — aucun appel au modèle, aucun coût
./content-agent analyze HEAD

# Brouillons (dry-run implicite : rien n'est publié)
./content-agent draft HEAD

# Sans modèle du tout, à partir des seuls faits
./content-agent --offline draft HEAD

# Validation : APPROVE / EDIT / CANCEL
./content-agent review 8c06bf1
```

`review` revérifie les garde-fous au moment d'approuver — car tu as pu éditer le
fichier à la main entre-temps.

## Ce qui n'est pas publié

Tout commit ne mérite pas un post. `historian.is_publishable` écarte en amont, **avant
de payer une génération** : les commits `chore`/`style`/`docs`/`merge`, les changements
de moins de dix lignes, et ceux qui ne touchent que des fichiers générés. `--force`
passe outre.

Si le modèle juge qu'il n'y a rien à raconter, il renseigne `skipped_reason` au lieu
de meubler. C'est un résultat valide.

## Publication

**Aucun adaptateur ne publie, et c'est délibéré.** La contrainte est « pas de
publication sans validation humaine » ; le moyen le plus sûr de la tenir est qu'aucun
code de publication n'existe encore.

Les trois adaptateurs figent le contrat pour la phase 3 :

| Plateforme | Intégration officielle prévue |
|---|---|
| X | API v2, `POST /2/tweets` |
| Threads | Threads API (Meta), `/threads_publish` |
| Substack | aucune API d'écriture publique — copie manuelle assumée |

Sur Substack, il n'y a rien à contourner : on copie l'article approuvé dans l'éditeur.

## Fichiers produits

```
marketing/
├── brand.md              # ton identité éditoriale — édite-le, c'est le vrai levier
├── content-history.md    # angles déjà publiés, pour ne pas se répéter
├── pending/<sha>.json    # brouillons en attente
├── published/<sha>.json  # brouillons approuvés
└── content-agent.log     # journal, systématiquement expurgé des secrets
```

## Tests

```bash
.venv/bin/python -m pytest tests -q
```

33 tests, sans réseau ni clé API. Ils couvrent l'analyse d'un vrai commit dans un
dépôt git jetable, le rejet des métriques et témoignages inventés, les limites de
longueur, la non-fuite de secrets, le dry-run, et le cycle d'approbation.

Deux d'entre eux ont déjà trouvé de vrais défauts pendant l'écriture — dont le fait
qu'un sha de commit contient des chiffres qu'il ne fallait pas confondre avec une
métrique inventée.

## Limites connues

- Le filtre de publiabilité est grossier : il juge la taille et le préfixe, pas
  l'intérêt. C'est un filtre de coût, pas un rédacteur en chef.
- Le lien commit → PR passe par `gh pr list --search <sha>` : il échoue silencieusement
  hors ligne, et la fiche est alors simplement moins riche.
- L'extrait de diff est tronqué à 6 000 caractères. Une très grosse feature sera vue
  partiellement — préfère alors analyser la PR.
