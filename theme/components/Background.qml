import QtQuick
import QtQuick.Effects
import ".."

// The wallpaper, sharp at first; blur and the background color fade in when
// `revealed` and clear again on the way out (login accepted)
Item {
    id: root

    property bool revealed: false

    readonly property real amount: revealed ? 1 : 0

    Rectangle {
        anchors.fill: parent
        color: Tokens.backgroundColor
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        visible: false
        source: Tokens.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
    }

    MultiEffect {
        anchors.fill: parent
        visible: wallpaper.status === Image.Ready
        source: wallpaper
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: Tokens.blurMax
        blur: Tokens.blur * root.amount

        Behavior on blur {
            NumberAnimation {
                duration: Tokens.animDurationLong * 2
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Tokens.backgroundColor
        opacity: Tokens.dim * root.amount

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.animDurationLong * 2
                easing.type: Easing.OutCubic
            }
        }
    }
}
