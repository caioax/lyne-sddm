import QtQuick
import QtQuick.Effects
import ".."

// The wallpaper, sharp at first; blur and the background color fade in when
// `revealed` and clear again on the way out (login accepted). `blurred`
// false keeps it sharp, only darkened a little (the wallpaper layout)
Item {
    id: root

    property bool revealed: false
    property bool blurred: true

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
        blur: root.blurred ? Tokens.blur * root.amount : 0

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
        opacity: (root.blurred ? Tokens.dim : Tokens.dimSharp) * root.amount

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.animDurationLong * 2
                easing.type: Easing.OutCubic
            }
        }
    }
}
