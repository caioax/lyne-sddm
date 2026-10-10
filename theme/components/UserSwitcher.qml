pragma ComponentBehavior: Bound
import QtQuick
import ".."

// The chosen user's name, with arrows beside it when there are others. Only
// the name takes room in the layout (like the lock screen's plain name), the
// arrows hang outside it
Item {
    id: root

    readonly property bool multiple: Greeter.users.length > 1

    implicitWidth: name.implicitWidth
    implicitHeight: name.implicitHeight

    Text {
        id: name

        anchors.centerIn: parent
        text: Greeter.user ? (Greeter.user.realName || Greeter.user.name) : ""
        font.family: Tokens.font
        font.pixelSize: Tokens.fontSizeLarge
        font.bold: true
        color: Tokens.textColor
    }

    Arrow {
        anchors.right: name.left
        anchors.rightMargin: Tokens.spacing
        anchors.verticalCenter: name.verticalCenter
        glyph: "\u{f0141}"
        step: -1
    }

    Arrow {
        anchors.left: name.right
        anchors.leftMargin: Tokens.spacing
        anchors.verticalCenter: name.verticalCenter
        glyph: "\u{f0142}"
        step: 1
    }

    component Arrow: Rectangle {
        id: arrow

        property string glyph
        property int step

        visible: root.multiple
        width: Tokens.fontSizeIcon * 1.4
        height: width
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
