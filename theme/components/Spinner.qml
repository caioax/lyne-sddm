pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Spinning arrow while the login is checked
Text {
    id: root

    property bool running: true
    property int size: Tokens.fontSizeIcon

    visible: running
    text: "\u{f0450}"
    font.family: Tokens.font
    font.pixelSize: size
    color: Tokens.textColor

    RotationAnimator on rotation {
        from: 0
        to: 360
        duration: Tokens.animDurationLong * 2
        loops: Animation.Infinite
        running: root.running
    }
}
