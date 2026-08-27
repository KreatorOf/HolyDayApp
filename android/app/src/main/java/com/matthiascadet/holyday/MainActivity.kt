package com.matthiascadet.holyday

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.matthiascadet.holyday.data.prefs.rememberStringPreference
import com.matthiascadet.holyday.ui.navigation.HolyDayNavHost
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.HolyDayTheme

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            HolyDayRoot()
        }
    }
}

@Composable
private fun HolyDayRoot() {
    val colorSchemePreference by rememberStringPreference("holyday.colorScheme", "system")
    val systemDark = isSystemInDarkTheme()
    val darkTheme = when (colorSchemePreference) {
        "light" -> false
        "dark" -> true
        else -> systemDark
    }
    HolyDayTheme(darkTheme = darkTheme) {
        // Couleur explicite : la valeur par défaut de `Surface` (colorScheme.surface = cardSurface)
        // ne correspond pas au jaune pâle de fond, ce qui laissait apparaître une teinte différente
        // derrière la barre du haut et la zone système du bas, avant que chaque écran ne dessine son
        // propre `AppBackground()`.
        Surface(modifier = Modifier.fillMaxSize(), color = AppTheme.colors.backgroundPrimary) {
            HolyDayNavHost()
        }
    }
}
