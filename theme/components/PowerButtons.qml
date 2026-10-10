pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Bottom right: suspend, reboot and shut down as square buttons (the lock
// screen's "square" PowerButton). A first click selects, a second runs it;
// reboot and shut down count down first, with the seconds in the box, a
// ring filling around it and a line below (Esc cancels)
ColumnLayout {
    id: root

    spacing: Tokens.padding

    RowLayout {
        id: buttons

        Layout.alignment: Qt.AlignHCenter
        spacing: 0

        Repeater {
            model: Greeter.actions

            PowerButton {}
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: buttons.implicitWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        visible: Greeter.pending !== null
        text: Greeter.pending ? qsTr("%1 in %2s · esc cancels").arg(Greeter.pending.progress).arg(Math.ceil(Greeter.remaining / 1000)) : ""
        font.family: Tokens.font
        font.pixelSize: Tokens.fontSizeSmall
        font.bold: true
        color: Greeter.pending?.tone === "error" ? Tokens.errorColor : Tokens.warningColor
    }

    component PowerButton: Item {
        id: button

        required property var modelData
        readonly property bool selected: Greeter.selectedId === modelData.id
        readonly property bool pending: Greeter.pendingId === modelData.id
        readonly property color tone: modelData.tone === "error" ? Tokens.errorColor : modelData.tone === "warning" ? Tokens.warningColor : Tokens.accentColor
        // Room around the box for the countdown ring
        readonly property real ringGap: Tokens.padding

        implicitWidth: Tokens.powerBoxSize + ringGap * 2
        implicitHeight: implicitWidth
        scale: mouse.pressed ? 0.96 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Tokens.animDurationShort
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Tokens.powerBoxSize
            height: width
            radius: Tokens.radiusLarge
            color: button.selected ? button.tone : mouse.containsMouse ? Tokens.cardHoverColor : Tokens.cardColor

            Behavior on color {
                ColorAnimation {
                    duration: Tokens.animDurationShort
                }
            }

            Text {
                anchors.centerIn: parent
                text: button.pending ? Math.ceil(Greeter.remaining / 1000) : button.modelData.glyph
                font.family: Tokens.font
                font.pixelSize: Tokens.fontSizeIcon
                font.bold: button.pending
                color: button.selected ? Tokens.textReverseColor : mouse.containsMouse ? button.tone : Tokens.textColor

                Behavior on color {
                    ColorAnimation {
                        duration: Tokens.animDurationShort
                    }
                }
            }
        }

        // Fills up while the countdown runs
        Loader {
            anchors.fill: parent
            active: button.pending

            sourceComponent: ProgressRing {
                value: (1 - Greeter.pendingProgress) * 100
                strokeWidth: Math.max(2, Tokens.padding / 2)
                color: button.tone
                trackColor: Qt.alpha(button.tone, 0.2)
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Greeter.powerClicked(button.modelData.id);
                Greeter.focusRequested();
            }
        }
    }
}
