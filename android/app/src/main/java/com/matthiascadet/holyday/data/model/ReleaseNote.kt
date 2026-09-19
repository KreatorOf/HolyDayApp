package com.matthiascadet.holyday.data.model

import androidx.annotation.StringRes
import com.matthiascadet.holyday.R

/** Notes compilées avec le binaire : elles restent disponibles hors ligne après une mise à jour. */
data class ReleaseNote(
    val version: String,
    val items: List<Item>,
) {
    data class Item(
        @StringRes val titleRes: Int,
        @StringRes val bodyRes: Int,
        val icon: Icon,
        val colorName: String,
    )

    enum class Icon { BOOK, DESCRIPTION, LANGUAGE, WIDGETS, NOTIFICATIONS, QUICK_PRAY }
}

/** Doit rester aligné sur `ReleaseNotesCatalog` côté iOS. */
object ReleaseNotesCatalog {
    val all = listOf(
        ReleaseNote(
            version = "1.2.0",
            items = listOf(
                ReleaseNote.Item(R.string.whatsnew_12_reminders_title, R.string.whatsnew_12_reminders_body, ReleaseNote.Icon.NOTIFICATIONS, "confessionBlue"),
                ReleaseNote.Item(R.string.whatsnew_12_widget_title, R.string.whatsnew_12_widget_body, ReleaseNote.Icon.WIDGETS, "supplicationGreen"),
                ReleaseNote.Item(R.string.whatsnew_12_quickpray_title, R.string.whatsnew_12_quickpray_body, ReleaseNote.Icon.QUICK_PRAY, "adorationPurple"),
            ),
        ),
        ReleaseNote(
            version = "1.1",
            items = listOf(
                ReleaseNote.Item(R.string.whatsnew_11_attribution_title, R.string.whatsnew_11_attribution_body, ReleaseNote.Icon.BOOK, "adorationPurple"),
                ReleaseNote.Item(R.string.whatsnew_11_legal_title, R.string.whatsnew_11_legal_body, ReleaseNote.Icon.DESCRIPTION, "confessionBlue"),
                ReleaseNote.Item(R.string.whatsnew_11_language_title, R.string.whatsnew_11_language_body, ReleaseNote.Icon.LANGUAGE, "thanksgivingGold"),
                ReleaseNote.Item(R.string.whatsnew_11_widget_title, R.string.whatsnew_11_widget_body, ReleaseNote.Icon.WIDGETS, "supplicationGreen"),
            ),
        ),
    )
}
