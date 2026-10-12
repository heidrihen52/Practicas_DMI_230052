package com.example.toktik

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.graphics.BitmapFactory
import android.graphics.Color
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import org.json.JSONObject
import java.util.Calendar
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.embedding.engine.renderer.FlutterRenderer
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var startupView: FrameLayout? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // El driver OMX del Nokia API 29 rechaza los buffers de ImageReader.
        // Usar SurfaceTexture/OpenGLES antes de crear el motor: el selector de
        // Flutter actualmente solo detecta este defecto en dispositivos Huawei.
        // https://github.com/flutter/flutter/issues/166481
        if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q &&
            Build.MODEL.equals("Nokia 5.1 Plus", ignoreCase = true)) {
            intent.putExtra(FlutterShellArgs.ARG_KEY_TOGGLE_IMPELLER, false)
            FlutterRenderer.debugForceSurfaceProducerGlTextures = true
        }
        super.onCreate(savedInstanceState)
        // La ventana inicial del sistema es neutra. Este icono usa la misma
        // preferencia persistida y regla de fecha que Flutter, antes de su primer frame.
        val season = startupSeason()
        val filename = when (season) {
            "halloween" -> "vdry-halloween.png"
            "christmas" -> "vdry-Christmas.png"
            "valentines" -> "vdry-valentines.png"
            else -> "vdry_launcher.png"
        }
        val overlay = FrameLayout(this).apply { setBackgroundColor(Color.rgb(16, 16, 21)) }
        val icon = ImageView(this).apply {
            scaleType = ImageView.ScaleType.FIT_CENTER
            assets.open("flutter_assets/assets/icons/$filename").use {
                setImageBitmap(BitmapFactory.decodeStream(it))
            }
        }
        val size = (160 * resources.displayMetrics.density).toInt()
        overlay.addView(icon, FrameLayout.LayoutParams(size, size, Gravity.CENTER))
        startupView = overlay
        addContentView(overlay, ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splash ->
                // Android crea su ventana antes de poder leer preferencias.
                // Al entregarla a la app, mostrar el arte correcto y cerrar
                // con una transición breve hacia el primer frame de Flutter.
                (overlay.parent as? ViewGroup)?.removeView(overlay)
                startupView = null
                splash.addView(overlay, FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
                overlay.animate().alpha(0f).setStartDelay(150).setDuration(150)
                    .withEndAction { splash.remove() }.start()
            }
        }
    }

    private fun startupSeason(): String {
        val saved = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getString("flutter.toktik.preferences.v1", null)
        val forced = try { JSONObject(saved ?: "{}").optString("season") } catch (_: Exception) { "" }
        if (forced in listOf("normal", "halloween", "christmas", "valentines")) return forced
        val today = Calendar.getInstance()
        return when (today.get(Calendar.MONTH)) {
            Calendar.OCTOBER -> "halloween"
            Calendar.DECEMBER -> "christmas"
            Calendar.FEBRUARY -> if (today.get(Calendar.DAY_OF_MONTH) <= 14) "valentines" else "normal"
            else -> "normal"
        }
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        startupView?.let { (it.parent as? ViewGroup)?.removeView(it) }
        startupView = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "toktik/app_icon")
            .setMethodCallHandler { call, result ->
                if (call.method != "setIcon") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val aliases = mapOf("normal" to "NormalIcon", "halloween" to "HalloweenIcon", "christmas" to "ChristmasIcon", "valentines" to "ValentinesIcon")
                val requested = aliases[call.arguments as? String]
                if (requested == null) {
                    result.error("INVALID_ICON", "Icono desconocido", null)
                    return@setMethodCallHandler
                }
                try {
                    val changes = aliases.values.mapNotNull { alias ->
                        val component = ComponentName(this, "$packageName.$alias")
                        val current = packageManager.getComponentEnabledSetting(component)
                        val enabled = current == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                            (current == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && alias == "NormalIcon")
                        val desired = alias == requested
                        if (enabled == desired) null else Pair(component, if (desired)
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (changes.isNotEmpty()) packageManager.setComponentEnabledSettings(changes.map {
                            PackageManager.ComponentEnabledSetting(it.first, it.second, PackageManager.DONT_KILL_APP)
                        })
                    } else {
                        // Activar primero el destino para mantener siempre un acceso visible.
                        changes.sortedByDescending { it.second == PackageManager.COMPONENT_ENABLED_STATE_ENABLED }
                            .forEach { packageManager.setComponentEnabledSetting(it.first, it.second, PackageManager.DONT_KILL_APP) }
                    }
                    result.success(null)
                } catch (error: Exception) {
                    result.error("ICON_UPDATE_FAILED", error.message, null)
                }
            }
    }
}
