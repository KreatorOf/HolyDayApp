//
//  VerseService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation

@Observable
final class VerseService {
  static let shared = VerseService()

  private init() {}

  /// Entrée du corpus : texte/référence dans les deux langues + thèmes d'émotions associés.
  /// Le classement par émotion vit ici (et non sur `Verse`), pour ne pas alourdir le modèle public.
  /// Traductions : français = Louis Segond (LSG), anglais = King James Version (KJV) — toutes deux
  /// dans le domaine public. Le sigle de version est ajouté à la référence dans `makeVerse`.
  private struct Entry {
    let textFR: String
    let textEN: String
    let referenceFR: String
    let referenceEN: String
    let bookFR: String
    let bookEN: String
    let chapter: Int
    let verse: Int
    let emotions: Set<Emotion>
  }

  // Un même verset peut porter plusieurs thèmes : il apparaîtra alors dans plusieurs decks.
  private let corpus: [Entry] = [
    Entry(
      textFR:
        "Car Dieu a tant aimé le monde qu'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu'il ait la vie éternelle.",
      textEN:
        "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
      referenceFR: "Jean 3:16", referenceEN: "John 3:16", bookFR: "Jean", bookEN: "John",
      chapter: 3, verse: 16, emotions: [.hope, .gratitude, .joy]),
    Entry(
      textFR: "Je puis tout par celui qui me fortifie.",
      textEN: "I can do all things through Christ which strengtheneth me.",
      referenceFR: "Philippiens 4:13", referenceEN: "Philippians 4:13",
      bookFR: "Philippiens", bookEN: "Philippians", chapter: 4, verse: 13,
      emotions: [.fatigue, .hope]),
    Entry(
      textFR: "L'Éternel est mon berger : je ne manquerai de rien.",
      textEN: "The Lord is my shepherd; I shall not want.",
      referenceFR: "Psaume 23:1", referenceEN: "Psalm 23:1", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 23, verse: 1, emotions: [.peace, .fear]),
    Entry(
      textFR: "Confie-toi en l'Éternel de tout ton cœur, et ne t'appuie pas sur ta sagesse.",
      textEN: "Trust in the Lord with all thine heart; and lean not unto thine own understanding.",
      referenceFR: "Proverbes 3:5", referenceEN: "Proverbs 3:5",
      bookFR: "Proverbes", bookEN: "Proverbs", chapter: 3, verse: 5, emotions: [.fear, .hope]),
    Entry(
      textFR:
        "Ne crains rien, car je suis avec toi ; ne promène pas des regards inquiets, car je suis ton Dieu.",
      textEN: "Fear thou not; for I am with thee: be not dismayed; for I am thy God.",
      referenceFR: "Ésaïe 41:10", referenceEN: "Isaiah 41:10", bookFR: "Ésaïe", bookEN: "Isaiah",
      chapter: 41, verse: 10, emotions: [.fear]),
    Entry(
      textFR:
        "Cherchez premièrement le royaume et la justice de Dieu ; et toutes ces choses vous seront données par-dessus.",
      textEN:
        "But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.",
      referenceFR: "Matthieu 6:33", referenceEN: "Matthew 6:33",
      bookFR: "Matthieu", bookEN: "Matthew", chapter: 6, verse: 33, emotions: [.fear, .hope]),
    Entry(
      textFR: "Voici, je suis avec vous tous les jours, jusqu'à la fin du monde.",
      textEN: "Lo, I am with you alway, even unto the end of the world.",
      referenceFR: "Matthieu 28:20", referenceEN: "Matthew 28:20",
      bookFR: "Matthieu", bookEN: "Matthew", chapter: 28, verse: 20, emotions: [.sadness, .fear]),
    Entry(
      textFR:
        "Car mes pensées ne sont pas vos pensées, et vos voies ne sont pas mes voies, dit l'Éternel.",
      textEN:
        "For my thoughts are not your thoughts, neither are your ways my ways, saith the Lord.",
      referenceFR: "Ésaïe 55:8", referenceEN: "Isaiah 55:8", bookFR: "Ésaïe", bookEN: "Isaiah",
      chapter: 55, verse: 8, emotions: [.sadness, .hope]),
    Entry(
      textFR: "Que ton cœur ne se trouble point. Croyez en Dieu, et croyez en moi.",
      textEN: "Let not your heart be troubled: ye believe in God, believe also in me.",
      referenceFR: "Jean 14:1", referenceEN: "John 14:1", bookFR: "Jean", bookEN: "John",
      chapter: 14, verse: 1, emotions: [.sadness, .fear, .peace]),
    Entry(
      textFR: "Approchez-vous de Dieu, et il s'approchera de vous.",
      textEN: "Draw nigh to God, and he will draw nigh to you.",
      referenceFR: "Jacques 4:8", referenceEN: "James 4:8", bookFR: "Jacques", bookEN: "James",
      chapter: 4, verse: 8, emotions: [.hope, .gratitude]),
    Entry(
      textFR: "L'Éternel combattra pour vous ; et vous, gardez le silence.",
      textEN: "The Lord shall fight for you, and ye shall hold your peace.",
      referenceFR: "Exode 14:14", referenceEN: "Exodus 14:14", bookFR: "Exode", bookEN: "Exodus",
      chapter: 14, verse: 14, emotions: [.anger, .fear]),
    Entry(
      textFR:
        "Demandez, et l'on vous donnera ; cherchez, et vous trouverez ; frappez, et l'on vous ouvrira.",
      textEN:
        "Ask, and it shall be given you; seek, and ye shall find; knock, and it shall be opened unto you.",
      referenceFR: "Matthieu 7:7", referenceEN: "Matthew 7:7",
      bookFR: "Matthieu", bookEN: "Matthew", chapter: 7, verse: 7, emotions: [.hope]),
    Entry(
      textFR: "Mais ceux qui se confient en l'Éternel renouvellent leur force.",
      textEN: "But they that wait upon the Lord shall renew their strength.",
      referenceFR: "Ésaïe 40:31", referenceEN: "Isaiah 40:31", bookFR: "Ésaïe", bookEN: "Isaiah",
      chapter: 40, verse: 31, emotions: [.fatigue, .hope]),
    Entry(
      textFR: "Rejetez sur lui tous vos soucis, car lui-même prend soin de vous.",
      textEN: "Casting all your care upon him; for he careth for you.",
      referenceFR: "1 Pierre 5:7", referenceEN: "1 Peter 5:7", bookFR: "1 Pierre",
      bookEN: "1 Peter",
      chapter: 5, verse: 7, emotions: [.fear, .sadness]),
    Entry(
      textFR:
        "La paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs et vos pensées en Jésus Christ.",
      textEN:
        "And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.",
      referenceFR: "Philippiens 4:7", referenceEN: "Philippians 4:7",
      bookFR: "Philippiens", bookEN: "Philippians", chapter: 4, verse: 7, emotions: [.peace]),
    Entry(
      textFR: "Réjouissez-vous toujours dans le Seigneur ; je le répète, réjouissez-vous.",
      textEN: "Rejoice in the Lord alway: and again I say, Rejoice.",
      referenceFR: "Philippiens 4:4", referenceEN: "Philippians 4:4",
      bookFR: "Philippiens", bookEN: "Philippians", chapter: 4, verse: 4, emotions: [.joy]),
    Entry(
      textFR: "Rendez grâces en toutes choses, car c'est à votre égard la volonté de Dieu.",
      textEN:
        "In every thing give thanks: for this is the will of God in Christ Jesus concerning you.",
      referenceFR: "1 Thessaloniciens 5:18", referenceEN: "1 Thessalonians 5:18",
      bookFR: "1 Thessaloniciens", bookEN: "1 Thessalonians", chapter: 5, verse: 18,
      emotions: [.gratitude]),
    Entry(
      textFR: "Venez à moi, vous tous qui êtes fatigués et chargés, et je vous donnerai du repos.",
      textEN: "Come unto me, all ye that labour and are heavy laden, and I will give you rest.",
      referenceFR: "Matthieu 11:28", referenceEN: "Matthew 11:28",
      bookFR: "Matthieu", bookEN: "Matthew", chapter: 11, verse: 28,
      emotions: [.fatigue, .sadness, .peace]),

    // MARK: Colère
    Entry(
      textFR:
        "Si vous vous mettez en colère, ne péchez point ; que le soleil ne se couche pas sur votre colère.",
      textEN: "Be ye angry, and sin not: let not the sun go down upon your wrath.",
      referenceFR: "Éphésiens 4:26", referenceEN: "Ephesians 4:26",
      bookFR: "Éphésiens", bookEN: "Ephesians", chapter: 4, verse: 26, emotions: [.anger]),
    Entry(
      textFR:
        "Que tout homme soit prompt à écouter, lent à parler, lent à se mettre en colère.",
      textEN: "Let every man be swift to hear, slow to speak, slow to wrath.",
      referenceFR: "Jacques 1:19", referenceEN: "James 1:19", bookFR: "Jacques", bookEN: "James",
      chapter: 1, verse: 19, emotions: [.anger]),
    Entry(
      textFR: "Une réponse douce calme la fureur, mais une parole dure excite la colère.",
      textEN: "A soft answer turneth away wrath: but grievous words stir up anger.",
      referenceFR: "Proverbes 15:1", referenceEN: "Proverbs 15:1",
      bookFR: "Proverbes", bookEN: "Proverbs", chapter: 15, verse: 1, emotions: [.anger]),
    Entry(
      textFR: "Laisse la colère, abandonne la fureur ; ne t'irrite pas, ce serait mal faire.",
      textEN: "Cease from anger, and forsake wrath: fret not thyself in any wise to do evil.",
      referenceFR: "Psaume 37:8", referenceEN: "Psalm 37:8", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 37, verse: 8, emotions: [.anger, .peace]),
    Entry(
      textFR:
        "Celui qui est lent à la colère a une grande intelligence, mais celui qui est prompt à s'emporter proclame sa folie.",
      textEN:
        "He that is slow to wrath is of great understanding: but he that is hasty of spirit exalteth folly.",
      referenceFR: "Proverbes 14:29", referenceEN: "Proverbs 14:29",
      bookFR: "Proverbes", bookEN: "Proverbs", chapter: 14, verse: 29, emotions: [.anger]),

    // MARK: Joie
    Entry(
      textFR: "Il y a d'abondantes joies devant ta face, des délices éternelles à ta droite.",
      textEN:
        "In thy presence is fulness of joy; at thy right hand there are pleasures for evermore.",
      referenceFR: "Psaume 16:11", referenceEN: "Psalm 16:11", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 16, verse: 11, emotions: [.joy]),
    Entry(
      textFR: "La joie de l'Éternel sera votre force.",
      textEN: "The joy of the Lord is your strength.",
      referenceFR: "Néhémie 8:10", referenceEN: "Nehemiah 8:10",
      bookFR: "Néhémie", bookEN: "Nehemiah", chapter: 8, verse: 10, emotions: [.joy, .fatigue]),
    Entry(
      textFR:
        "Je vous ai dit ces choses, afin que ma joie soit en vous, et que votre joie soit parfaite.",
      textEN:
        "These things have I spoken unto you, that my joy might remain in you, and that your joy might be full.",
      referenceFR: "Jean 15:11", referenceEN: "John 15:11", bookFR: "Jean", bookEN: "John",
      chapter: 15, verse: 11, emotions: [.joy]),
    Entry(
      textFR:
        "C'est ici la journée que l'Éternel a faite : qu'elle soit pour nous un sujet d'allégresse et de joie !",
      textEN: "This is the day which the Lord hath made; we will rejoice and be glad in it.",
      referenceFR: "Psaume 118:24", referenceEN: "Psalm 118:24",
      bookFR: "Psaumes", bookEN: "Psalms", chapter: 118, verse: 24, emotions: [.joy, .gratitude]),

    // MARK: Paix
    Entry(
      textFR:
        "Je vous laisse la paix, je vous donne ma paix. Je ne vous donne pas comme le monde donne.",
      textEN:
        "Peace I leave with you, my peace I give unto you: not as the world giveth, give I unto you.",
      referenceFR: "Jean 14:27", referenceEN: "John 14:27", bookFR: "Jean", bookEN: "John",
      chapter: 14, verse: 27, emotions: [.peace, .fear, .sadness]),
    Entry(
      textFR:
        "À celui qui est ferme dans ses sentiments tu assures la paix, la paix, parce qu'il se confie en toi.",
      textEN:
        "Thou wilt keep him in perfect peace, whose mind is stayed on thee: because he trusteth in thee.",
      referenceFR: "Ésaïe 26:3", referenceEN: "Isaiah 26:3", bookFR: "Ésaïe", bookEN: "Isaiah",
      chapter: 26, verse: 3, emotions: [.peace, .fear]),
    Entry(
      textFR:
        "Que la paix de Christ, à laquelle vous avez été appelés pour former un seul corps, règne dans vos cœurs ; et soyez reconnaissants.",
      textEN:
        "Let the peace of God rule in your hearts, to the which also ye are called in one body; and be ye thankful.",
      referenceFR: "Colossiens 3:15", referenceEN: "Colossians 3:15",
      bookFR: "Colossiens", bookEN: "Colossians", chapter: 3, verse: 15,
      emotions: [.peace, .gratitude]),

    // MARK: Reconnaissance
    Entry(
      textFR:
        "Entrez dans ses portes avec des louanges, dans ses parvis avec des cantiques ! Célébrez-le, bénissez son nom !",
      textEN:
        "Enter into his gates with thanksgiving, and into his courts with praise: be thankful unto him, and bless his name.",
      referenceFR: "Psaume 100:4", referenceEN: "Psalm 100:4", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 100, verse: 4, emotions: [.gratitude]),
    Entry(
      textFR: "Louez l'Éternel, car il est bon, car sa miséricorde dure à toujours !",
      textEN: "O give thanks unto the Lord, for he is good: for his mercy endureth for ever.",
      referenceFR: "Psaume 107:1", referenceEN: "Psalm 107:1", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 107, verse: 1, emotions: [.gratitude, .hope]),
    Entry(
      textFR:
        "Quoi que vous fassiez, en parole ou en œuvre, faites tout au nom du Seigneur Jésus, en rendant par lui des actions de grâces à Dieu le Père.",
      textEN:
        "And whatsoever ye do in word or deed, do all in the name of the Lord Jesus, giving thanks to God and the Father by him.",
      referenceFR: "Colossiens 3:17", referenceEN: "Colossians 3:17",
      bookFR: "Colossiens", bookEN: "Colossians", chapter: 3, verse: 17, emotions: [.gratitude]),

    // MARK: Fatigue
    Entry(
      textFR: "Ma grâce te suffit, car ma puissance s'accomplit dans la faiblesse.",
      textEN: "My grace is sufficient for thee: for my strength is made perfect in weakness.",
      referenceFR: "2 Corinthiens 12:9", referenceEN: "2 Corinthians 12:9",
      bookFR: "2 Corinthiens", bookEN: "2 Corinthians", chapter: 12, verse: 9,
      emotions: [.fatigue, .hope]),
    Entry(
      textFR:
        "Ne nous lassons pas de faire le bien ; car nous moissonnerons au temps convenable, si nous ne nous relâchons pas.",
      textEN:
        "And let us not be weary in well doing: for in due season we shall reap, if we faint not.",
      referenceFR: "Galates 6:9", referenceEN: "Galatians 6:9", bookFR: "Galates",
      bookEN: "Galatians", chapter: 6, verse: 9, emotions: [.fatigue, .hope]),
    Entry(
      textFR:
        "L'Éternel est ma force et mon bouclier ; en lui mon cœur se confie, et je suis secouru.",
      textEN: "The Lord is my strength and my shield; my heart trusted in him, and I am helped.",
      referenceFR: "Psaume 28:7", referenceEN: "Psalm 28:7", bookFR: "Psaumes", bookEN: "Psalms",
      chapter: 28, verse: 7, emotions: [.fatigue, .fear]),
  ]

  // Decks mélangés par émotion : on épuise toute la pioche avant de re-mélanger → l'utilisateur
  // voit l'ensemble des versets d'un thème avant qu'un seul ne se répète.
  @ObservationIgnored private var decks: [Emotion: [Int]] = [:]
  @ObservationIgnored private var lastServed: [Emotion: Int] = [:]

  private var isFrench: Bool {
    let lang = Locale.current.language.languageCode?.identifier ?? "fr"
    return !lang.hasPrefix("en")
  }

  private func makeVerse(_ entry: Entry) -> Verse {
    let translation = isFrench ? "LSG" : "KJV"
    let reference = "\(isFrench ? entry.referenceFR : entry.referenceEN) (\(translation))"
    return Verse(
      text: isFrench ? entry.textFR : entry.textEN,
      reference: reference,
      book: isFrench ? entry.bookFR : entry.bookEN,
      chapter: entry.chapter, verse: entry.verse)
  }

  func getVerseOfTheDay() -> Verse {
    verse(for: Date())
  }

  // Déterministe par jour de l'année : une date donnée renvoie toujours le même verset — permet
  // aux notifications de pré-planifier le bon verset pour chaque jour à venir.
  func verse(for date: Date) -> Verse {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
    return makeVerse(corpus[(dayOfYear - 1) % corpus.count])
  }

  /// Verset accompagnant une émotion. Chaque appel (re-tap inclus) avance la pioche du thème :
  /// le verset change tant qu'il en reste, sans répétition immédiate, pour que l'utilisateur
  /// finisse par trouver celui qui lui parle. Repli sur le verset du jour si le thème est vide.
  func verse(for emotion: Emotion) -> Verse {
    let pool = corpus.indices.filter { corpus[$0].emotions.contains(emotion) }
    guard !pool.isEmpty else { return getVerseOfTheDay() }
    guard pool.count > 1 else { return makeVerse(corpus[pool[0]]) }

    var deck = decks[emotion] ?? []
    if deck.isEmpty {
      deck = pool.shuffled()
      // Évite d'enchaîner deux fois de suite le même verset au moment du re-mélange.
      if let last = lastServed[emotion], deck.first == last {
        deck.swapAt(0, 1)
      }
    }

    let index = deck.removeFirst()
    decks[emotion] = deck
    lastServed[emotion] = index
    return makeVerse(corpus[index])
  }
}
