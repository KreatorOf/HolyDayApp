//
//  VerseCorpus.swift
//  HolyDay
//
//  Created by Matthias Cadet on 10/06/2026.
//

import Foundation

/// Entrée du corpus : texte/référence dans les deux langues + thèmes d'émotions associés.
/// Compilé dans l'app ET dans l'extension widget (dossier partagé HolyDayShared) : c'est la
/// source unique des versets — ne pas redéclarer de liste locale côté widget.
/// Les émotions sont portées par leur `rawValue` (`Emotion` vit côté app, le widget n'en a
/// pas besoin) ; voir `Emotion.rawValue`, stable et non localisée.
/// Traductions : français = Louis Segond (LSG), domaine public ; anglais = Berean Standard Bible
/// (BSB), libre d'utilisation (Berean Bible, bereanbible.com).
nonisolated struct CorpusVerse: Sendable {
  let textFR: String
  let textEN: String
  let referenceFR: String
  let referenceEN: String
  let bookFR: String
  let bookEN: String
  let chapter: Int
  let verse: Int
  let emotionTags: Set<String>

  func text(french: Bool) -> String { french ? textFR : textEN }
  func reference(french: Bool) -> String { french ? referenceFR : referenceEN }
  func book(french: Bool) -> String { french ? bookFR : bookEN }
}

nonisolated enum VerseCorpus {
  // Un même verset peut porter plusieurs thèmes : il apparaîtra alors dans plusieurs decks.
  static let all: [CorpusVerse] = [
    CorpusVerse(
      textFR:
        "Car Dieu a tant aimé le monde qu'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu'il ait la vie éternelle.",
      textEN:
        "For God so loved the world that He gave His one and only Son, that everyone who believes in Him shall not perish but have eternal life.",
      referenceFR: "Jean 3:16", referenceEN: "John 3:16", bookFR: "Jean", bookEN: "John",
      chapter: 3, verse: 16, emotionTags: ["hope", "gratitude", "joy"]),
    CorpusVerse(
      textFR: "Je puis tout par celui qui me fortifie.",
      textEN: "I can do all things through Christ who gives me strength.",
      referenceFR: "Philippiens 4:13", referenceEN: "Philippians 4:13",
      bookFR: "Philippiens", bookEN: "Philippians", chapter: 4, verse: 13,
      emotionTags: ["fatigue", "hope"]),
    CorpusVerse(
      textFR: "L'Éternel est mon berger : je ne manquerai de rien.",
      textEN: "The LORD is my shepherd; I shall not want.",
      referenceFR: "Psaume 23:1", referenceEN: "Psalm 23:1", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 23, verse: 1, emotionTags: ["peace", "fear"]),
    CorpusVerse(
      textFR: "Confie-toi en l'Éternel de tout ton cœur, et ne t'appuie pas sur ta sagesse.",
      textEN: "Trust in the LORD with all your heart, and lean not on your own understanding.",
      referenceFR: "Proverbes 3:5", referenceEN: "Proverbs 3:5",
      bookFR: "Proverbes", bookEN: "Proverbs", chapter: 3, verse: 5,
      emotionTags: ["fear", "hope"]),
    CorpusVerse(
      textFR:
        "Ne crains rien, car je suis avec toi ; ne promène pas des regards inquiets, car je suis ton Dieu.",
      textEN: "Do not fear, for I am with you; do not be afraid, for I am your God.",
      referenceFR: "Ésaïe 41:10", referenceEN: "Isaiah 41:10", bookFR: "Ésaïe", bookEN: "Isaiah",
      chapter: 41, verse: 10, emotionTags: ["fear"]),
    CorpusVerse(
      textFR:
        "Cherchez premièrement le royaume et la justice de Dieu ; et toutes ces choses vous seront données par-dessus.",
      textEN:
        "But seek first the kingdom of God and His righteousness, and all these things will be added unto you.",
      referenceFR: "Matthieu 6:33", referenceEN: "Matthew 6:33",
      bookFR: "Matthieu", bookEN: "Matthew", chapter: 6, verse: 33, emotionTags: ["fear", "hope"]),
    CorpusVerse(
      textFR: "Voici, je suis avec vous tous les jours, jusqu'à la fin du monde.",
      textEN: "And surely I am with you always, even to the end of the age.",
      referenceFR: "Matthieu 28:20", referenceEN: "Matthew 28:20",
      bookFR: "Matthieu", bookEN: "Matthew", chapter: 28, verse: 20,
      emotionTags: ["sadness", "fear"]),
    CorpusVerse(
      textFR:
        "Car mes pensées ne sont pas vos pensées, et vos voies ne sont pas mes voies, dit l'Éternel.",
      textEN:
        "For My thoughts are not your thoughts, neither are your ways My ways, declares the LORD.",
      referenceFR: "Ésaïe 55:8", referenceEN: "Isaiah 55:8", bookFR: "Ésaïe", bookEN: "Isaiah",
      chapter: 55, verse: 8, emotionTags: ["sadness", "hope"]),
    CorpusVerse(
      textFR: "Que ton cœur ne se trouble point. Croyez en Dieu, et croyez en moi.",
      textEN: "Do not let your hearts be troubled. You believe in God; believe in Me as well.",
      referenceFR: "Jean 14:1", referenceEN: "John 14:1", bookFR: "Jean", bookEN: "John",
      chapter: 14, verse: 1, emotionTags: ["sadness", "fear", "peace"]),
    CorpusVerse(
      textFR: "Approchez-vous de Dieu, et il s'approchera de vous.",
      textEN: "Draw near to God, and He will draw near to you.",
      referenceFR: "Jacques 4:8", referenceEN: "James 4:8", bookFR: "Jacques", bookEN: "James",
      chapter: 4, verse: 8, emotionTags: ["hope", "gratitude"]),
    CorpusVerse(
      textFR: "L'Éternel combattra pour vous ; et vous, gardez le silence.",
      textEN: "The LORD will fight for you; you need only to be still.",
      referenceFR: "Exode 14:14", referenceEN: "Exodus 14:14", bookFR: "Exode", bookEN: "Exodus",
      chapter: 14, verse: 14, emotionTags: ["anger", "fear"]),
    CorpusVerse(
      textFR:
        "Demandez, et l'on vous donnera ; cherchez, et vous trouverez ; frappez, et l'on vous ouvrira.",
      textEN:
        "Ask, and it will be given to you; seek, and you will find; knock, and the door will be opened to you.",
      referenceFR: "Matthieu 7:7", referenceEN: "Matthew 7:7",
      bookFR: "Matthieu", bookEN: "Matthew", chapter: 7, verse: 7, emotionTags: ["hope"]),
    CorpusVerse(
      textFR: "Mais ceux qui se confient en l'Éternel renouvellent leur force.",
      textEN: "But those who wait upon the LORD will renew their strength.",
      referenceFR: "Ésaïe 40:31", referenceEN: "Isaiah 40:31", bookFR: "Ésaïe", bookEN: "Isaiah",
      chapter: 40, verse: 31, emotionTags: ["fatigue", "hope"]),
    CorpusVerse(
      textFR: "Rejetez sur lui tous vos soucis, car lui-même prend soin de vous.",
      textEN: "Cast all your anxiety on Him, because He cares for you.",
      referenceFR: "1 Pierre 5:7", referenceEN: "1 Peter 5:7", bookFR: "1 Pierre",
      bookEN: "1 Peter",
      chapter: 5, verse: 7, emotionTags: ["fear", "sadness"]),
    CorpusVerse(
      textFR:
        "La paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs et vos pensées en Jésus Christ.",
      textEN:
        "And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus.",
      referenceFR: "Philippiens 4:7", referenceEN: "Philippians 4:7",
      bookFR: "Philippiens", bookEN: "Philippians", chapter: 4, verse: 7, emotionTags: ["peace"]),
    CorpusVerse(
      textFR: "Réjouissez-vous toujours dans le Seigneur ; je le répète, réjouissez-vous.",
      textEN: "Rejoice in the Lord always. I will say it again: Rejoice!",
      referenceFR: "Philippiens 4:4", referenceEN: "Philippians 4:4",
      bookFR: "Philippiens", bookEN: "Philippians", chapter: 4, verse: 4, emotionTags: ["joy"]),
    CorpusVerse(
      textFR: "Rendez grâces en toutes choses, car c'est à votre égard la volonté de Dieu.",
      textEN:
        "Give thanks in every circumstance, for this is God's will for you in Christ Jesus.",
      referenceFR: "1 Thessaloniciens 5:18", referenceEN: "1 Thessalonians 5:18",
      bookFR: "1 Thessaloniciens", bookEN: "1 Thessalonians", chapter: 5, verse: 18,
      emotionTags: ["gratitude"]),
    CorpusVerse(
      textFR: "Venez à moi, vous tous qui êtes fatigués et chargés, et je vous donnerai du repos.",
      textEN: "Come to Me, all you who are weary and burdened, and I will give you rest.",
      referenceFR: "Matthieu 11:28", referenceEN: "Matthew 11:28",
      bookFR: "Matthieu", bookEN: "Matthew", chapter: 11, verse: 28,
      emotionTags: ["fatigue", "sadness", "peace"]),

    // MARK: Colère
    CorpusVerse(
      textFR:
        "Si vous vous mettez en colère, ne péchez point ; que le soleil ne se couche pas sur votre colère.",
      textEN: "Be angry, yet do not sin. Do not let the sun set upon your anger.",
      referenceFR: "Éphésiens 4:26", referenceEN: "Ephesians 4:26",
      bookFR: "Éphésiens", bookEN: "Ephesians", chapter: 4, verse: 26, emotionTags: ["anger"]),
    CorpusVerse(
      textFR:
        "Que tout homme soit prompt à écouter, lent à parler, lent à se mettre en colère.",
      textEN: "Everyone should be quick to listen, slow to speak, and slow to anger.",
      referenceFR: "Jacques 1:19", referenceEN: "James 1:19", bookFR: "Jacques", bookEN: "James",
      chapter: 1, verse: 19, emotionTags: ["anger"]),
    CorpusVerse(
      textFR: "Une réponse douce calme la fureur, mais une parole dure excite la colère.",
      textEN: "A gentle answer turns away wrath, but a harsh word stirs up anger.",
      referenceFR: "Proverbes 15:1", referenceEN: "Proverbs 15:1",
      bookFR: "Proverbes", bookEN: "Proverbs", chapter: 15, verse: 1, emotionTags: ["anger"]),
    CorpusVerse(
      textFR: "Laisse la colère, abandonne la fureur ; ne t'irrite pas, ce serait mal faire.",
      textEN: "Refrain from anger and abandon wrath; do not fret—it can only bring harm.",
      referenceFR: "Psaume 37:8", referenceEN: "Psalm 37:8", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 37, verse: 8, emotionTags: ["anger", "peace"]),
    CorpusVerse(
      textFR:
        "Celui qui est lent à la colère a une grande intelligence, mais celui qui est prompt à s'emporter proclame sa folie.",
      textEN:
        "A patient man has great understanding, but a quick-tempered man promotes folly.",
      referenceFR: "Proverbes 14:29", referenceEN: "Proverbs 14:29",
      bookFR: "Proverbes", bookEN: "Proverbs", chapter: 14, verse: 29, emotionTags: ["anger"]),

    // MARK: Joie
    CorpusVerse(
      textFR: "Il y a d'abondantes joies devant ta face, des délices éternelles à ta droite.",
      textEN:
        "You will fill me with joy in Your presence, with eternal pleasures at Your right hand.",
      referenceFR: "Psaume 16:11", referenceEN: "Psalm 16:11", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 16, verse: 11, emotionTags: ["joy"]),
    CorpusVerse(
      textFR: "La joie de l'Éternel sera votre force.",
      textEN: "The joy of the LORD is your strength.",
      referenceFR: "Néhémie 8:10", referenceEN: "Nehemiah 8:10",
      bookFR: "Néhémie", bookEN: "Nehemiah", chapter: 8, verse: 10,
      emotionTags: ["joy", "fatigue"]),
    CorpusVerse(
      textFR:
        "Je vous ai dit ces choses, afin que ma joie soit en vous, et que votre joie soit parfaite.",
      textEN:
        "I have told you these things so that My joy may be in you and your joy may be complete.",
      referenceFR: "Jean 15:11", referenceEN: "John 15:11", bookFR: "Jean", bookEN: "John",
      chapter: 15, verse: 11, emotionTags: ["joy"]),
    CorpusVerse(
      textFR:
        "C'est ici la journée que l'Éternel a faite : qu'elle soit pour nous un sujet d'allégresse et de joie !",
      textEN: "This is the day that the LORD has made; we will rejoice and be glad in it.",
      referenceFR: "Psaume 118:24", referenceEN: "Psalm 118:24",
      bookFR: "Psaumes", bookEN: "Psalms", chapter: 118, verse: 24,
      emotionTags: ["joy", "gratitude"]),

    // MARK: Paix
    CorpusVerse(
      textFR:
        "Je vous laisse la paix, je vous donne ma paix. Je ne vous donne pas comme le monde donne.",
      textEN:
        "Peace I leave with you; My peace I give to you. I do not give to you as the world gives.",
      referenceFR: "Jean 14:27", referenceEN: "John 14:27", bookFR: "Jean", bookEN: "John",
      chapter: 14, verse: 27, emotionTags: ["peace", "fear", "sadness"]),
    CorpusVerse(
      textFR:
        "À celui qui est ferme dans ses sentiments tu assures la paix, la paix, parce qu'il se confie en toi.",
      textEN:
        "You will keep in perfect peace the steadfast of mind, because he trusts in You.",
      referenceFR: "Ésaïe 26:3", referenceEN: "Isaiah 26:3", bookFR: "Ésaïe", bookEN: "Isaiah",
      chapter: 26, verse: 3, emotionTags: ["peace", "fear"]),
    CorpusVerse(
      textFR:
        "Que la paix de Christ, à laquelle vous avez été appelés pour former un seul corps, règne dans vos cœurs ; et soyez reconnaissants.",
      textEN:
        "Let the peace of Christ rule in your hearts, for to this you were called as members of one body. And be thankful.",
      referenceFR: "Colossiens 3:15", referenceEN: "Colossians 3:15",
      bookFR: "Colossiens", bookEN: "Colossians", chapter: 3, verse: 15,
      emotionTags: ["peace", "gratitude"]),

    // MARK: Reconnaissance
    CorpusVerse(
      textFR:
        "Entrez dans ses portes avec des louanges, dans ses parvis avec des cantiques ! Célébrez-le, bénissez son nom !",
      textEN:
        "Enter His gates with thanksgiving and His courts with praise; give thanks to Him and bless His name.",
      referenceFR: "Psaume 100:4", referenceEN: "Psalm 100:4", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 100, verse: 4, emotionTags: ["gratitude"]),
    CorpusVerse(
      textFR: "Louez l'Éternel, car il est bon, car sa miséricorde dure à toujours !",
      textEN: "Give thanks to the LORD, for He is good; His loving devotion endures forever.",
      referenceFR: "Psaume 107:1", referenceEN: "Psalm 107:1", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 107, verse: 1, emotionTags: ["gratitude", "hope"]),
    CorpusVerse(
      textFR:
        "Quoi que vous fassiez, en parole ou en œuvre, faites tout au nom du Seigneur Jésus, en rendant par lui des actions de grâces à Dieu le Père.",
      textEN:
        "And whatever you do, in word or deed, do it all in the name of the Lord Jesus, giving thanks to God the Father through Him.",
      referenceFR: "Colossiens 3:17", referenceEN: "Colossians 3:17",
      bookFR: "Colossiens", bookEN: "Colossians", chapter: 3, verse: 17,
      emotionTags: ["gratitude"]),

    // MARK: Fatigue
    CorpusVerse(
      textFR: "Ma grâce te suffit, car ma puissance s'accomplit dans la faiblesse.",
      textEN: "My grace is sufficient for you, for My power is perfected in weakness.",
      referenceFR: "2 Corinthiens 12:9", referenceEN: "2 Corinthians 12:9",
      bookFR: "2 Corinthiens", bookEN: "2 Corinthians", chapter: 12, verse: 9,
      emotionTags: ["fatigue", "hope"]),
    CorpusVerse(
      textFR:
        "Ne nous lassons pas de faire le bien ; car nous moissonnerons au temps convenable, si nous ne nous relâchons pas.",
      textEN:
        "Let us not grow weary in well-doing, for in due time we will reap a harvest if we do not give up.",
      referenceFR: "Galates 6:9", referenceEN: "Galatians 6:9", bookFR: "Galates",
      bookEN: "Galatians", chapter: 6, verse: 9, emotionTags: ["fatigue", "hope"]),
    CorpusVerse(
      textFR:
        "L'Éternel est ma force et mon bouclier ; en lui mon cœur se confie, et je suis secouru.",
      textEN: "The LORD is my strength and my shield; my heart trusts in Him, and I am helped.",
      referenceFR: "Psaume 28:7", referenceEN: "Psalm 28:7", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 28, verse: 7, emotionTags: ["fatigue", "fear"]),
  ]
}
