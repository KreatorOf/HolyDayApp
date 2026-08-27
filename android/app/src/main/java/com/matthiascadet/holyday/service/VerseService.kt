package com.matthiascadet.holyday.service

import com.matthiascadet.holyday.data.model.CorpusVerse
import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.data.model.Verse
import com.matthiascadet.holyday.data.model.VerseCorpus
import java.util.Locale

/**
 * Système de "pioche" (deck) par émotion sur `VerseCorpus` : épuise tout le tirage avant de
 * re-mélanger, pour que l'utilisateur voie l'ensemble des versets d'un thème avant qu'un seul
 * ne se répète.
 */
object VerseService {
    private val decks: MutableMap<Emotion, MutableList<Int>> = mutableMapOf()
    private val lastServed: MutableMap<Emotion, Int> = mutableMapOf()

    private val isFrench: Boolean
        get() {
            val lang = Locale.getDefault().language
            return !lang.startsWith("en")
        }

    private fun makeVerse(entry: CorpusVerse): Verse {
        val translation = if (isFrench) "LSG" else "KJV"
        val reference = "${entry.reference(isFrench)} ($translation)"
        return Verse(
            text = entry.text(isFrench),
            reference = reference,
            book = entry.book(isFrench),
            chapter = entry.chapter,
            verse = entry.verse,
        )
    }

    /**
     * Verset accompagnant une émotion. Chaque appel (re-tap inclus) avance la pioche du thème :
     * le verset change tant qu'il en reste, sans répétition immédiate.
     */
    fun verse(emotion: Emotion): Verse {
        val corpus = VerseCorpus.all
        val pool = corpus.indices.filter { corpus[it].emotionTags.contains(emotion.id) }
        if (pool.isEmpty()) return makeVerse(corpus[0])
        if (pool.size == 1) return makeVerse(corpus[pool[0]])

        var deck = decks[emotion] ?: mutableListOf()
        if (deck.isEmpty()) {
            deck = pool.shuffled().toMutableList()
            val last = lastServed[emotion]
            if (last != null && deck.first() == last) {
                val tmp = deck[0]
                deck[0] = deck[1]
                deck[1] = tmp
            }
        }

        val index = deck.removeAt(0)
        decks[emotion] = deck
        lastServed[emotion] = index
        return makeVerse(corpus[index])
    }
}
