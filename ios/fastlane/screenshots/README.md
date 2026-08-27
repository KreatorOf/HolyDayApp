# App Store screenshots

`deliver`/`upload_to_app_store` picks up screenshots from this folder, one sub-folder per locale (`fr-FR`, `en-US`).

## Tailles requises (App Store Connect)

| Device            | Résolution (portrait) |
|-------------------|-----------------------|
| iPhone 6.9" / 6.7"| 1290 × 2796           |
| iPhone 6.5"       | 1284 × 2778           |
| iPad Pro 13" / 12.9" | 2048 × 2732        |

Nomme les fichiers dans l'ordre d'affichage, ex. `01_checkin.png`, `02_verset.png`, `03_priere.png`.
Place-les dans `fr-FR/` et `en-US/`.

Pour les générer automatiquement, configure `snapshot` (UI tests) — non encore mis en place.
