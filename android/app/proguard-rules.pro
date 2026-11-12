# Flutter ProGuard Rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# audio_service & just_audio native binding
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# Android media and media session compatibility
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
