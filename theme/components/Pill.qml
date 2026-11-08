import QtQuick
import QtQuick.Layouts
import ".."

// Rounded chip with an icon and a label, clickable when `interactive`. Past
// `maxWidth` the label elides
Rectangle {
    id: root

    property string icon
    property string text
    property color accent: Tokens.textColor
    property bool interactive: true
    property bool active: false
    property real maxWidth: Number.POSITIVE_INFINITY

    signal clicked

    implicitWidth: Math.min(row.implicitWidth + Tokens.padding * 4, maxWidth)
    implicitHeight: Tokens.pillHeight
    radius: height / 2
    color: active || mouse.containsMouse ? Tokens.cardHoverColor : Tokens.cardColor
    border.width: 1
    border.color: active ? Qt.alpha(Tokens.accentColor, 0.6) : Qt.alpha(Tokens.accentColor, 0)

    Behavior on color {
        ColorAnimation {
            duration: Tokens.animDurationShort
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Tokens.animDurationShort
        }
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing

        Text {
            id: iconText

            visible: root.icon !== ""
            text: root.icon
            font.family: Tokens.font
            font.pixelSize: Tokens.fontSizeIconSmall
            color: root.accent
        }

        Text {
            // What maxWidth leaves after the icon and the padding
            Layout.maximumWidth: root.maxWidth - Tokens.padding * 4 - (iconText.visible ? iconText.implicitWidth + row.spacing : 0)
            text: root.text
            // Only when cut: the layout rounds a fraction of a pixel off
            elide: implicitWidth - width > 1 ? Text.ElideRight : Text.ElideNone
            font.family: Tokens.font
            font.pixelSize: Tokens.fontSizeNormal
            color: Tokens.textColor
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
