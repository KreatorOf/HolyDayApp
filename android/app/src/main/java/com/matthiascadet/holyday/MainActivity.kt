package com.matthiascadet.holyday

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.LocalActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.core.view.WindowCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.matthiascadet.holyday.data.prefs.rememberStringPreference
import com.matthiascadet.holyday.ui.navigation.HolyDayNavHost
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.HolyDayTheme

class MainActivity : ComponentActivity() {
    private var pendingDeepLink by mutableStateOf<Uri?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        pendingDeepLink = intent?.data
        enableEdgeToEdge()
        setContent {
            HolyDayRoot(deepLink = pendingDeepLink, onDeepLinkHandled = { pendingDeepLink = null })
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingDeepLink = intent.data
    }
}

@Composable
private fun HolyDayRoot(deepLink: Uri?, onDeepLinkHandled: () -> Unit) {
    val colorSchemePreference by rememberStringPreference("holyday.colorScheme", "system")
    val systemDark = isSystemInDarkTheme()
    val darkTheme = when (colorSchemePreference) {
        "light" -> false
        "dark" -> true
        else -> systemDark
    }
    val activity = LocalActivity.current
    SideEffect {
        activity?.window?.let { window ->
            WindowCompat.getInsetsController(window, window.decorView).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }
    HolyDayTheme(darkTheme = darkTheme) {
        // Couleur explicite : la valeur par défaut de `Surface` (colorScheme.surface = cardSurface)
        // ne correspond pas au jaune pâle de fond, ce qui laissait apparaître une teinte différente
        // derrière la barre du haut et la zone système du bas, avant que chaque écran ne dessine son
        // propre `AppBackground()`.
        Surface(modifier = Modifier.fillMaxSize(), color = AppTheme.colors.backgroundPrimary) {
            HolyDayNavHost(deepLink = deepLink, onDeepLinkHandled = onDeepLinkHandled)
        }
    }
}
