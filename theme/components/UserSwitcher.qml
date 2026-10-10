pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// The chosen user's name, with arrows around it when there are others
RowLayout {
    id: root

    readonly property bool multiple: Greeter.users.length > 1

    spacing: Tokens.spacing

    Arrow {
        glyph: "\u{f0141}"
        step: -1
    }

    Text {
        text: Greeter.user ? (Greeter.user.realName || Greeter.user.name) : ""
        font.family: Tokens.font
        font.pixelSize: Tokens.fontSizeLarge
        font.bold: true
        color: Tokens.textColor
    }

    Arrow {
        glyph: "\u{f0142}"
        step: 1
    }

    component Arrow: Rectangle {
        id: arrow

        property string glyph
        property int step

        // Keeps the name centered while hidden
        opacity: root.multiple ? 1 : 0
        enabled: root.multiple
        implicitWidth: Tokens.fontSizeIcon * 1.4
        implicitHeight: implicitWidth
        radius: width / 2
        color: mouse.containsMouse ? Tokens.cardHoverColor : Qt.alpha(Tokens.cardHoverColor, 0)

        Behavior on color {
            ColorAnimation {
                duration: Tokens.animDurationShort
            }
        }

        Text {
            anchors.centerIn: parent
            text: arrow.glyph
            font.family: Tokens.font
            font.pixelSize: Tokens.fontSizeIconSmall
            color: mouse.containsMouse ? Tokens.textColor : Tokens.subtextColor
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Greeter.cycleUser(arrow.step);
                Greeter.focusRequested();
            }
        }
    }
}
