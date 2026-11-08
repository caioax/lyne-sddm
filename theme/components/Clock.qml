import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import ".."

// Time and date, ticking on the minute. `size` is the time's pixel size (the
// date follows it); `alignment` lines both up left, center or right;
// `shadow` lifts it off a sharp wallpaper
ColumnLayout {
    id: root

    property real size: Tokens.clockSize
    property int alignment: Qt.AlignHCenter
    // Drop shadow, for a clock over a sharp wallpaper
    property bool shadow: false
    readonly property date now: ticker.now

    spacing: 0

    layer.enabled: shadow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Tokens.backgroundColor
        shadowBlur: 1
        shadowOpacity: Tokens.clockShadow
    }

    Ticker {
        id: ticker
    }

    Text {
        Layout.alignment: root.alignment
        text: Tokens.locale.toString(root.now, Tokens.clockFormat)
        font.family: Tokens.font
        font.pixelSize: root.size
        font.bold: true
        color: Tokens.textColor
    }

    Text {
        Layout.alignment: root.alignment
        text: Tokens.locale.toString(root.now, Tokens.dateFormat)
        font.family: Tokens.font
        font.pixelSize: Math.max(Tokens.fontSizeLarge, Math.round(root.size / 5))
        color: Tokens.subtextColor
    }
}
