package com.matthiascadet.holyday.data.model

import java.util.UUID

data class Verse(
    val id: UUID = UUID.randomUUID(),
    val text: String,
    val reference: String,
    val book: String,
    val chapter: Int,
    val verse: Int,
)
