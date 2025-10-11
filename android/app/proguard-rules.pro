# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.view.** { *; }

# Keep the Flutter engine
-keep class io.flutter.embedding.engine.** { *; }

# Keep method names for Flutter's channel communication
-keepclassmembers,allowobfuscation class * {
  @io.flutter.plugin.common.MethodChannel.Method <methods>;
}

# Do not obfuscate any classes/methods that have the @Keep annotation
-keep class androidx.annotation.Keep

-keep @androidx.annotation.Keep class * {*;}

-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}

-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}

-keepclasseswithmembers class * {
    @androidx.annotation.Keep <init>(...);
}

# Keep your application's model classes (if any)
-keep class com.example.nav_aif_fyp.models.** { *; }

# Uncomment if using Gson/JSON serialization
# -keepclassmembers class * {
#    @com.google.gson.annotations.SerializedName <fields>;
# }

# These options are enabled by default in R8
-dontskipnonpubliclibraryclasses
-dontskipnonpubliclibraryclassmembers

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# For enumerations
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}