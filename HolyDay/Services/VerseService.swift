//
//  VerseService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation

@Observable
class VerseService {
    static let shared = VerseService()

    private init() {}

    private let frenchVerses: [Verse] = [
        Verse(text: "Car Dieu a tant aimé le monde qu'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu'il ait la vie éternelle.", reference: "Jean 3:16", book: "Jean", chapter: 3, verse: 16),
        Verse(text: "Je puis tout par celui qui me fortifie.", reference: "Philippiens 4:13", book: "Philippiens", chapter: 4, verse: 13),
        Verse(text: "L'Éternel est mon berger : je ne manquerai de rien.", reference: "Psaume 23:1", book: "Psaumes", chapter: 23, verse: 1),
        Verse(text: "Confie-toi en l'Éternel de tout ton cœur, et ne t'appuie pas sur ta sagesse.", reference: "Proverbes 3:5", book: "Proverbes", chapter: 3, verse: 5),
        Verse(text: "Ne crains rien, car je suis avec toi ; ne promène pas des regards inquiets, car je suis ton Dieu.", reference: "Ésaïe 41:10", book: "Ésaïe", chapter: 41, verse: 10),
        Verse(text: "Cherchez premièrement le royaume et la justice de Dieu ; et toutes ces choses vous seront données par-dessus.", reference: "Matthieu 6:33", book: "Matthieu", chapter: 6, verse: 33),
        Verse(text: "Voici, je suis avec vous tous les jours, jusqu'à la fin du monde.", reference: "Matthieu 28:20", book: "Matthieu", chapter: 28, verse: 20),
        Verse(text: "Car mes pensées ne sont pas vos pensées, et vos voies ne sont pas mes voies, dit l'Éternel.", reference: "Ésaïe 55:8", book: "Ésaïe", chapter: 55, verse: 8),
        Verse(text: "Que ton cœur ne se trouble point. Croyez en Dieu, et croyez en moi.", reference: "Jean 14:1", book: "Jean", chapter: 14, verse: 1),
        Verse(text: "Approchez-vous de Dieu, et il s'approchera de vous.", reference: "Jacques 4:8", book: "Jacques", chapter: 4, verse: 8),
        Verse(text: "L'Éternel combattra pour vous ; et vous, gardez le silence.", reference: "Exode 14:14", book: "Exode", chapter: 14, verse: 14),
        Verse(text: "Demandez, et l'on vous donnera ; cherchez, et vous trouverez ; frappez, et l'on vous ouvrira.", reference: "Matthieu 7:7", book: "Matthieu", chapter: 7, verse: 7),
        Verse(text: "Mais ceux qui se confient en l'Éternel renouvellent leur force.", reference: "Ésaïe 40:31", book: "Ésaïe", chapter: 40, verse: 31),
        Verse(text: "Rejetez sur lui tous vos soucis, car lui-même prend soin de vous.", reference: "1 Pierre 5:7", book: "1 Pierre", chapter: 5, verse: 7),
        Verse(text: "La paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs et vos pensées en Jésus Christ.", reference: "Philippiens 4:7", book: "Philippiens", chapter: 4, verse: 7)
    ]

    private let englishVerses: [Verse] = [
        Verse(text: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.", reference: "John 3:16", book: "John", chapter: 3, verse: 16),
        Verse(text: "I can do all this through him who gives me strength.", reference: "Philippians 4:13", book: "Philippians", chapter: 4, verse: 13),
        Verse(text: "The Lord is my shepherd, I lack nothing.", reference: "Psalm 23:1", book: "Psalms", chapter: 23, verse: 1),
        Verse(text: "Trust in the Lord with all your heart and lean not on your own understanding.", reference: "Proverbs 3:5", book: "Proverbs", chapter: 3, verse: 5),
        Verse(text: "So do not fear, for I am with you; do not be dismayed, for I am your God.", reference: "Isaiah 41:10", book: "Isaiah", chapter: 41, verse: 10),
        Verse(text: "But seek first his kingdom and his righteousness, and all these things will be given to you as well.", reference: "Matthew 6:33", book: "Matthew", chapter: 6, verse: 33),
        Verse(text: "And surely I am with you always, to the very end of the age.", reference: "Matthew 28:20", book: "Matthew", chapter: 28, verse: 20),
        Verse(text: "For my thoughts are not your thoughts, neither are your ways my ways, declares the Lord.", reference: "Isaiah 55:8", book: "Isaiah", chapter: 55, verse: 8),
        Verse(text: "Do not let your hearts be troubled. You believe in God; believe also in me.", reference: "John 14:1", book: "John", chapter: 14, verse: 1),
        Verse(text: "Come near to God and he will come near to you.", reference: "James 4:8", book: "James", chapter: 4, verse: 8),
        Verse(text: "The Lord will fight for you; you need only to be still.", reference: "Exodus 14:14", book: "Exodus", chapter: 14, verse: 14),
        Verse(text: "Ask and it will be given to you; seek and you will find; knock and the door will be opened to you.", reference: "Matthew 7:7", book: "Matthew", chapter: 7, verse: 7),
        Verse(text: "But those who hope in the Lord will renew their strength.", reference: "Isaiah 40:31", book: "Isaiah", chapter: 40, verse: 31),
        Verse(text: "Cast all your anxiety on him because he cares for you.", reference: "1 Peter 5:7", book: "1 Peter", chapter: 5, verse: 7),
        Verse(text: "And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.", reference: "Philippians 4:7", book: "Philippians", chapter: 4, verse: 7)
    ]

    private var localizedVerses: [Verse] {
        let lang = Locale.current.language.languageCode?.identifier ?? "fr"
        return lang.hasPrefix("en") ? englishVerses : frenchVerses
    }

    func getVerseOfTheDay() -> Verse {
        let verses = localizedVerses
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % verses.count
        return verses[index]
    }
}
