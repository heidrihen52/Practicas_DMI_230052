package com.example.toktik

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * Los aliases solo abren esta entrada. La tarea visible usa un componente estable,
 * así desactivar un alias al cambiar el icono no retira la sesión de Flutter.
 */
class LauncherActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val launch = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            // Conservar posibles extras enviados desde el launcher.
            intent.extras?.let { putExtras(it) }
        }
        startActivity(launch)
        finish()
    }
}
