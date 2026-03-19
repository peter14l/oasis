# Flutter wrapper rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Supabase / PostgREST / GoTrue / Serialization
-keep class io.supabase.** { *; }
-keep class com.example.morrow_v2.models.** { *; }
-keepclassmembers class com.example.morrow_v2.models.** { *; }
-keepattributes Signature,Annotation,EnclosingMethod,InnerClasses
-dontwarn moxy.**
-dontwarn com.google.errorprone.annotations.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Sentry / Compose
-dontwarn androidx.compose.**
-dontwarn androidx.window.**

# Inferred missing rules from build cache
-dontwarn androidx.compose.runtime.internal.StabilityInferred
-dontwarn androidx.compose.ui.Modifier
-dontwarn androidx.compose.ui.geometry.Offset
-dontwarn androidx.compose.ui.geometry.OffsetKt
-dontwarn androidx.compose.ui.geometry.Rect
-dontwarn androidx.compose.ui.graphics.Color$Companion
-dontwarn androidx.compose.ui.graphics.Color
-dontwarn androidx.compose.ui.graphics.ColorKt
-dontwarn androidx.compose.ui.layout.LayoutCoordinates
-dontwarn androidx.compose.ui.layout.LayoutCoordinatesKt
-dontwarn androidx.compose.ui.layout.ModifierInfo
-dontwarn androidx.compose.ui.node.LayoutNode
-dontwarn androidx.compose.ui.node.NodeCoordinator
-dontwarn androidx.compose.ui.node.Owner
-dontwarn androidx.compose.ui.semantics.AccessibilityAction
-dontwarn androidx.compose.ui.semantics.SemanticsActions
-dontwarn androidx.compose.ui.semantics.SemanticsConfiguration
-dontwarn androidx.compose.ui.semantics.SemanticsConfigurationKt
-dontwarn androidx.compose.ui.semantics.SemanticsModifierKt
-dontwarn androidx.compose.ui.semantics.SemanticsProperties
-dontwarn androidx.compose.ui.semantics.SemanticsPropertyKey
-dontwarn androidx.compose.ui.semantics.SemanticsPropertyReceiver
-dontwarn androidx.compose.ui.text.TextLayoutInput
-dontwarn androidx.compose.ui.text.TextLayoutResult
-dontwarn androidx.compose.ui.text.TextStyle
-dontwarn androidx.compose.ui.unit.IntSize
-dontwarn androidx.compose.ui.unit.TextUnit$Companion
-dontwarn androidx.compose.ui.unit.TextUnit
-dontwarn androidx.window.extensions.WindowExtensions
-dontwarn androidx.window.extensions.WindowExtensionsProvider
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaPresentation
-dontwarn androidx.window.extensions.layout.DisplayFeature
-dontwarn androidx.window.extensions.layout.FoldingFeature
-dontwarn androidx.window.extensions.layout.WindowLayoutComponent
-dontwarn androidx.window.extensions.layout.WindowLayoutInfo
-dontwarn androidx.window.sidecar.SidecarDeviceState
-dontwarn androidx.window.sidecar.SidecarDisplayFeature
-dontwarn androidx.window.sidecar.SidecarInterface$SidecarCallback
-dontwarn androidx.window.sidecar.SidecarInterface
-dontwarn androidx.window.sidecar.SidecarProvider
-dontwarn androidx.window.sidecar.SidecarWindowLayoutInfo

# Play Services Core / Splitcompat (for deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# JNI / Native
-keep class com.tekartik.sqflite.** { *; }
