pragma Singleton
import QtQuick

// Design tokens: the only place that reads SDDM's `config` (theme.conf with
// theme.conf.user on top). Components use these and the sizes derived below,
// with the same formulas as the lyne-dots lock screen
QtObject {
    id: root

    // ========================================================================
    // PALETTE
    // ========================================================================
    readonly property color backgroundColor: _color("background")
    readonly property color surface0Color: _color("surface0")
    readonly property color surface1Color: _color("surface1")
    readonly property color surface2Color: _color("surface2")
    readonly property color surface3Color: _color("surface3")
    readonly property color textColor: _color("text")
    readonly property color textReverseColor: _color("textReverse")
    readonly property color subtextColor: _color("subtext")
    readonly property color accentColor: _color("accent")
    readonly property color successColor: _color("success")
    readonly property color warningColor: _color("warning")
    readonly property color errorColor: _color("error")
    readonly property color mutedColor: _color("muted")

    readonly property real backgroundOpacity: _real("backgroundOpacity")
    readonly property color cardColor: Qt.alpha(surface0Color, backgroundOpacity)
    readonly property color cardHoverColor: Qt.alpha(surface1Color, backgroundOpacity)
    readonly property color cardBorderColor: Qt.alpha(surface2Color, 0.6)

    // ========================================================================
    // SYNCED DATA
    // ========================================================================
    readonly property string dataDir: _string("dataDir")

    // ========================================================================
    // WALLPAPER
    // ========================================================================
    readonly property url wallpaper: path(_string("wallpaper"))
    readonly property real blur: _real("blur")
    readonly property int blurMax: _int("blurMax")
    readonly property real dim: _real("dim")

    // ========================================================================
    // GEOMETRY
    // ========================================================================
    readonly property int radiusSmall: _int("radiusSmall")
    readonly property int radius: _int("radius")
    readonly property int radiusLarge: _int("radiusLarge")
    readonly property int spacing: _int("spacing")
    readonly property int padding: _int("padding")

    // ========================================================================
    // TYPOGRAPHY
    // ========================================================================
    readonly property string font: _string("font")
    readonly property int fontSizeSmall: _int("fontSizeSmall")
    readonly property int fontSizeNormal: _int("fontSizeNormal")
    readonly property int fontSizeLarge: _int("fontSizeLarge")
    readonly property int fontSizeIconSmall: _int("fontSizeIconSmall")
    readonly property int fontSizeIcon: _int("fontSizeIcon")
    readonly property int fontSizeIconLarge: _int("fontSizeIconLarge")

    // ========================================================================
    // ANIMATIONS
    // ========================================================================
    readonly property int animDurationShort: _int("animDurationShort")
    readonly property int animDuration: _int("animDuration")
    readonly property int animDurationLong: _int("animDurationLong")
    readonly property real animPopupFromScale: _real("animPopupFromScale")
    readonly property int animPopupEasing: Easing.OutExpo

    // ========================================================================
    // CLOCK, POWER, TEST
    // ========================================================================
    readonly property string clockFormat: _string("clockFormat")
    readonly property string dateFormat: _string("dateFormat")
    readonly property var locale: Qt.locale(_string("locale"))
    readonly property int powerCountdown: _int("powerCountdown")
    readonly property bool testMode: _string("testMode") === "true"

    // ========================================================================
    // DERIVED SIZES (lyne-dots lock screen, "center" template)
    // ========================================================================
    readonly property real clockSize: fontSizeIconLarge * 4
    readonly property real dateSize: Math.max(fontSizeLarge, Math.round(clockSize / 5))
    readonly property real avatarSize: fontSizeIconLarge * 3
    readonly property real fieldWidth: fontSizeNormal * 22
    readonly property real fieldHeight: fontSizeNormal * 3.4
    readonly property real dotSize: fontSizeSmall * 0.8
    readonly property real pillHeight: fontSizeNormal * 2.4
    readonly property real powerBoxSize: fontSizeIcon * 2.6
    readonly property real edgeMargin: spacing * 4

    // A theme file (relative to the theme dir) or an absolute path as a url
    function path(value: string): url {
        if (value === "")
            return "";
        return value.startsWith("/") ? "file://" + value : Qt.resolvedUrl(value);
    }

    function _string(key: string): string {
        const value = config[key];
        if (value === undefined) {
            console.warn("lyne-sddm: missing token", key);
            return "";
        }
        // An unquoted comma turns the value into a list
        return typeof value === "object" ? Array.from(value).join(", ") : String(value);
    }

    function _color(key: string): color {
        return _string(key);
    }

    function _real(key: string): real {
        return Number(_string(key));
    }

    function _int(key: string): int {
        return Math.round(_real(key));
    }
}
