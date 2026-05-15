//
//  VerseService.swift
//  Kairos
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation

@Observable
class VerseService {
    static let shared = VerseService()
    
    private init() {}
    
    // Base de données locale de versets
    private let verses: [Verse] = [
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
    
    func getVerseOfTheDay() -> Verse {
        // Utilise le jour de l'année pour sélectionner un verset de manière cohérente
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % verses.count
        return verses[index]
    }
    

}
