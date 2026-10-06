package `is`.xyz.mpv

import android.content.Context
import android.content.SharedPreferences
import androidx.appcompat.app.AppCompatDelegate

object ThemeManager {
    private const val PREFS_NAME = "mpv_theme_prefs"
    private const val KEY_THEME_MODE = "theme_mode"
    
    const val THEME_SYSTEM = 0
    const val THEME_LIGHT = 1
    const val THEME_DARK = 2
    
    private var prefs: SharedPreferences? = null
    private var context: Context? = null
    
    fun init(ctx: Context) {
        context = ctx
        prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    private fun ensureInitialized() {
        if (prefs == null && context != null) {
            prefs = context!!.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }
    
    fun applyTheme() {
        when (getThemeMode()) {
            THEME_LIGHT -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO)
            THEME_DARK -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES)
            else -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM)
        }
    }
    
    fun getThemeMode(): Int {
        ensureInitialized()
        return prefs?.getInt(KEY_THEME_MODE, THEME_SYSTEM) ?: THEME_SYSTEM
    }
    
    fun setThemeMode(mode: Int) {
        ensureInitialized()
        prefs?.edit()?.putInt(KEY_THEME_MODE, mode)?.apply()
        applyTheme()
    }
    
    fun getThemeModeName(mode: Int): String {
        return when (mode) {
            THEME_LIGHT -> "Light"
            THEME_DARK -> "Dark"
            else -> "System"
        }
    }
}