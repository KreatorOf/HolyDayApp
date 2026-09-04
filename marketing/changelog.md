# Journal de développement

Une entrée par feature significative, la plus récente en haut.
Ce fichier est aussi la base de contexte des contenus futurs : **ne jamais supprimer une entrée**.

Format et règles : voir « Build in public » dans `CLAUDE.md`.

<!-- entrées -->
## 2026-09-04 — Écran de nouveautés

**What I built** — Un écran présenté une fois après chaque mise à jour, listant ce qui a changé dans la version installée. `WhatsNewService` (`@MainActor @Observable`) décide de l'affichage, `ReleaseNotesCatalog` porte les notes par version, `WhatsNewView` les présente en plein écran. Évaluation déclenchée par `HolyDayApp` après le retrait du splash, présentation par `MainTabView`. 12 tests unitaires. Livré dans la 1.1, builds TestFlight 18 à 22.

**Why** — La 1.1 corrigeait l'attribution de la traduction anglaise des versets et réparait le snapshot du widget. Deux changements réels mais invisibles : sans écran de nouveautés, un utilisateur qui met à jour ne voit rien et ne sait pas que quelque chose a été réparé.

**User benefit** — Savoir ce qui a changé sans aller lire la fiche App Store. Les versions sautées sont rattrapées : passer de 1.0.1 à 1.2 montre les notes de 1.1 et de 1.2 dans le même écran.

**Technical notes** — Deux invariants portent tout le comportement : l'onboarding appelle `markSeen()` à sa dernière étape, donc une installation neuve ne voit jamais l'écran ; et l'absence de repère enregistré signifie « mise à jour depuis un binaire antérieur à la fonctionnalité », pas « installation neuve » — le premier invariant garantit que les deux cas ne se confondent pas.

La comparaison de versions est numérique et non lexicographique : « 1.10 » serait sinon considérée comme antérieure à « 1.9 ». Un test couvre explicitement ce cas.

`sheet(item:)` puis `fullScreenCover(item:)` plutôt que la variante `isPresented` : `item` conserve son contenu pendant l'animation de fermeture, alors que `markSeen()` vide l'état au premier geste.

Le passage en plein écran a rendu la croix de fermeture obligatoire : un `fullScreenCover` n'offre aucun geste de fermeture système, contrairement à une feuille.

**Lessons learned** — Une feature qui ne s'affiche qu'une fois est une feature qu'on ne peut pas retester. La section Développeur des réglages est compilée sous `#if DEBUG` : elle n'existe pas dans un build TestFlight, qui est un Release. Les notes de test que j'avais écrites renvoyaient donc les testeurs vers un écran absent, et comme les builds 19, 20 et 21 portaient tous la version 1.1, quiconque avait lancé le 19 ne pouvait plus jamais revoir l'écran.

Corrigé par une section « Bêta » visible uniquement sur une installation TestFlight, détectée via `AppTransaction.shared` de StoreKit 2 — `Bundle.main.appStoreReceiptURL`, la méthode habituelle, est dépréciée depuis iOS 18.

Le contrôle le plus important s'est révélé être celui qui consiste à constater une **absence** : vérifier que l'écran n'apparaît pas après un onboarding complet sur installation neuve. C'est le test que personne ne pense à faire.

**Generated content** — versions proposées le 2026-09-04, non publiées.

*X* :
> J'ai ajouté un écran de nouveautés à mon app. Puis j'ai écrit à mes testeurs : « Réglages → Développeur → Rejouer les nouveautés ».
>
> Sauf que cette section est sous `#if DEBUG`. Elle n'existe pas dans un build TestFlight.
>
> J'avais documenté un chemin vers un écran qui n'existait pas.

*Threads* :
> Le plus dur, dans un écran qui ne s'affiche qu'une fois, ce n'est pas de l'afficher.
>
> C'est de vérifier qu'il ne s'affiche PAS quand il ne faut pas. Après une installation neuve, par exemple : l'utilisateur vient déjà de tout découvrir, il n'y a rien à lui annoncer.
>
> Un test qui consiste à constater une absence, personne ne pense à l'écrire. J'ai dû le mettre noir sur blanc dans mes notes de test pour que quelqu'un le fasse.
>
> Vous les testez comment, vos absences ?

*Substack* : titre « L'écran que personne ne pouvait revoir », angle et cinq points clés conservés dans la sortie de session.

