package com.matthiascadet.holyday.service

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.RectF
import java.io.File
import java.io.FileOutputStream

/** Équivalent de `AvatarService` iOS : avatar recadré en carré, sauvegardé en JPEG local. */
object AvatarService {
    private const val SIDE = 256
    private const val FILE_NAME = "holyday_avatar.jpg"

    private fun avatarFile(context: Context): File = File(context.filesDir, FILE_NAME)

    /** Aspect-fill centré : le plus petit côté remplit le carré, le débordement est rogné. */
    fun save(context: Context, bitmap: Bitmap) {
        val squared = Bitmap.createBitmap(SIDE, SIDE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(squared)
        val scale = maxOf(SIDE.toFloat() / bitmap.width, SIDE.toFloat() / bitmap.height)
        val scaledWidth = bitmap.width * scale
        val scaledHeight = bitmap.height * scale
        val left = (SIDE - scaledWidth) / 2f
        val top = (SIDE - scaledHeight) / 2f
        val dest = RectF(left, top, left + scaledWidth, top + scaledHeight)
        canvas.drawBitmap(bitmap, null, dest, null)

        FileOutputStream(avatarFile(context)).use { out ->
            squared.compress(Bitmap.CompressFormat.JPEG, 85, out)
        }
    }

    fun load(context: Context): Bitmap? {
        val file = avatarFile(context)
        if (!file.exists()) return null
        return BitmapFactory.decodeFile(file.absolutePath)
    }

    fun delete(context: Context) {
        avatarFile(context).delete()
    }
}
