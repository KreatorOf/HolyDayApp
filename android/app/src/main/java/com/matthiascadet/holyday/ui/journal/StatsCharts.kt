package com.matthiascadet.holyday.ui.journal

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.data.model.EmotionTotal
import com.matthiascadet.holyday.data.model.StatPoint
import kotlin.math.cos
import kotlin.math.sin

/** Courbe d'activité (aire + ligne). Équivalent simplifié du `Chart` Swift Charts (pas de lib tierce). */
@Composable
fun ActivityLineChart(points: List<StatPoint>, color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.fillMaxWidth().height(180.dp)) {
        if (points.isEmpty()) return@Canvas
        val maxValue = (points.maxOf { it.value }).coerceAtLeast(1.0)
        val stepX = if (points.size > 1) size.width / (points.size - 1) else size.width
        val linePath = Path()
        val areaPath = Path()

        points.forEachIndexed { index, point ->
            val x = stepX * index
            val y = size.height - (point.value / maxValue * size.height).toFloat()
            if (index == 0) {
                linePath.moveTo(x, y)
                areaPath.moveTo(x, size.height)
                areaPath.lineTo(x, y)
            } else {
                linePath.lineTo(x, y)
                areaPath.lineTo(x, y)
            }
        }
        areaPath.lineTo(stepX * (points.size - 1), size.height)
        areaPath.close()

        drawPath(areaPath, brush = Brush.verticalGradient(listOf(color.copy(alpha = 0.35f), color.copy(alpha = 0.02f))))
        drawPath(linePath, color = color, style = Stroke(width = 3f))

        points.forEachIndexed { index, point ->
            val x = stepX * index
            val y = size.height - (point.value / maxValue * size.height).toFloat()
            drawCircle(color = color, radius = 4f, center = Offset(x, y))
        }
    }
}

/** Donut de répartition des émotions. Équivalent simplifié du `SectorMark` Swift Charts. */
@Composable
fun EmotionsDonutChart(totals: List<EmotionTotal>, modifier: Modifier = Modifier) {
    val total = totals.sumOf { it.count }.coerceAtLeast(1)
    Canvas(modifier = modifier.fillMaxWidth().height(200.dp)) {
        val strokeWidth = size.minDimension * 0.18f
        val diameter = size.minDimension - strokeWidth
        val topLeft = Offset((size.width - diameter) / 2f, (size.height - diameter) / 2f)
        var startAngle = -90f
        totals.forEach { entry ->
            val sweep = 360f * entry.count / total
            drawArc(
                color = entry.emotion.pastel,
                startAngle = startAngle + 1.5f,
                sweepAngle = (sweep - 3f).coerceAtLeast(1f),
                useCenter = false,
                topLeft = topLeft,
                size = androidx.compose.ui.geometry.Size(diameter, diameter),
                style = Stroke(width = strokeWidth, cap = androidx.compose.ui.graphics.StrokeCap.Round),
            )
            startAngle += sweep
        }
    }
}
