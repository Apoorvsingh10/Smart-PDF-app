pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Light theme only
    readonly property bool isDark: false

    // Premium color palette - Vibrant purple/indigo with warm accents
    readonly property color primary: "#7C3AED"
    readonly property color primaryForeground: "#FFFFFF"
    readonly property color primaryContainer: "#EDE9FE"
    readonly property color primaryContainerForeground: "#4C1D95"

    // Secondary - Warm rose/pink accent
    readonly property color secondary: "#EC4899"
    readonly property color secondaryForeground: "#FFFFFF"
    readonly property color secondaryContainer: "#FCE7F3"
    readonly property color secondaryContainerForeground: "#831843"

    // Tertiary - Teal/cyan for variety
    readonly property color tertiary: "#14B8A6"
    readonly property color tertiaryForeground: "#FFFFFF"
    readonly property color tertiaryContainer: "#CCFBF1"
    readonly property color tertiaryContainerForeground: "#134E4A"

    // Background/Surface
    readonly property color background: "#FAFAFA"
    readonly property color backgroundForeground: "#1C1917"
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceForeground: "#1C1917"
    readonly property color surfaceVariant: "#F3F0F7"
    readonly property color surfaceVariantForeground: "#57534E"
    readonly property color surfaceContainer: "#F5F3F8"
    readonly property color surfaceContainerHigh: "#EEEAF2"
    readonly property color surfaceContainerHighest: "#E6E1EC"

    // Elevated surface for cards with subtle distinction
    readonly property color cardSurface: "#FFFFFF"
    readonly property color cardSurfaceHover: "#FAF8FC"

    // Error/Success/Warning
    readonly property color error: "#DC2626"
    readonly property color errorForeground: "#FFFFFF"
    readonly property color errorContainer: "#FEE2E2"
    readonly property color success: "#16A34A"
    readonly property color successForeground: "#FFFFFF"
    readonly property color successContainer: "#DCFCE7"
    readonly property color warning: "#F59E0B"
    readonly property color warningForeground: "#FFFFFF"

    // Outline
    readonly property color outline: "#A8A29E"
    readonly property color outlineVariant: "#D6D3D1"

    // Gradient colors for premium feel
    readonly property color gradientStart: "#8B5CF6"
    readonly property color gradientEnd: "#D946EF"
    readonly property color gradientTertiary: "#14B8A6"

    // Shadow colors with elevation levels
    readonly property color shadowLight: "#00000015"
    readonly property color shadowMedium: "#00000025"
    readonly property color shadowHeavy: "#00000040"

    // Material Design naming aliases (for compatibility)
    readonly property color onSurface: surfaceForeground
    readonly property color onSurfaceVariant: surfaceVariantForeground
    readonly property color onBackground: backgroundForeground
    readonly property color onPrimary: primaryForeground
    readonly property color onSecondary: secondaryForeground
    readonly property color onError: errorForeground

    // Additional surface foreground variant
    readonly property color surfaceForegroundVariant: "#78716C"

    // Warning container
    readonly property color warningContainer: "#FEF3C7"

    // State properties
    readonly property real disabledOpacity: 0.38
    readonly property real hoverOpacity: 0.08
    readonly property real pressedOpacity: 0.12

    // Spacing - Generous for breathing room
    readonly property int spacingTiny: 4
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 16
    readonly property int spacingLarge: 24
    readonly property int spacingXLarge: 32
    readonly property int spacingXXLarge: 48

    // Border radius - Softer, more modern
    readonly property int radiusTiny: 6
    readonly property int radiusSmall: 10
    readonly property int radiusMedium: 14
    readonly property int radiusLarge: 20
    readonly property int radiusXLarge: 28
    readonly property int radiusFull: 9999

    // Typography - Modern scale
    readonly property int fontSizeTiny: 10
    readonly property int fontSizeCaption: 12
    readonly property int fontSizeBody: 14
    readonly property int fontSizeSubtitle: 16
    readonly property int fontSizeTitle: 20
    readonly property int fontSizeHeadline: 26
    readonly property int fontSizeDisplay: 32

    // Icon sizes
    readonly property int iconSizeTiny: 16
    readonly property int iconSizeSmall: 20
    readonly property int iconSizeMedium: 24
    readonly property int iconSizeLarge: 32
    readonly property int iconSizeXLarge: 48
    readonly property int iconSizeHero: 72

    // Component heights
    readonly property int buttonHeight: 52
    readonly property int buttonHeightSmall: 40
    readonly property int listItemHeight: 64
    readonly property int bottomNavHeight: 72
    readonly property int appBarHeight: 60

    // Animation durations - Snappy but smooth
    readonly property int animationFast: 120
    readonly property int animationNormal: 200
    readonly property int animationSlow: 350
    readonly property int animationVerySlow: 500

    // Easing curves as properties for consistency
    readonly property int easingType: Easing.OutCubic
    readonly property int easingTypeBack: Easing.OutBack
}
