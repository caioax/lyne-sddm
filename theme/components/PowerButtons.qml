pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Bottom right: suspend, reboot and shut down as square buttons (the lock
// screen's "square" PowerButton). A first click selects, a second runs it;
// reboot and shut down count down first, with the seconds in the box, a
// ring filling around it and a line below (Esc cancels). `rows` stacks them
// as full-width lines with their labels instead (the lock screen's "row"
// variant, for narrow cards), the seconds at the end of the pending one
ColumnLayout {
    id: root

    property bool rows: false

    spacing: Tokens.padding

    RowLayout {
        id: buttons

        visible: !root.rows
        Layout.alignment: Qt.AlignHCenter
        spacing: 0

        Repeater {
            model: root.rows ? [] : Greeter.actions

            PowerButton {}
        }
    }

    ColumnLayout {
        visible: root.rows
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            model: root.rows ? Greeter.actions : []

            PowerRow {
                Layout.fillWidth: true
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: buttons.implicitWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        visible: Greeter.pending !== null && !root.rows
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
        // The lock screen's square button counts the gap twice in height
        // (its icon box and the button both add it): kept for parity
        implicitHeight: Tokens.powerBoxSize + ringGap * 4
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
            anchors.centerIn: parent
            width: button.implicitWidth
            height: width
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

    // A line with the action's box, its label and the seconds while it
    // counts down; no fill at rest (it sits on a card)
    component PowerRow: Rectangle {
        id: line

        required property var modelData
        readonly property bool selected: Greeter.selectedId === modelData.id
        readonly property bool pending: Greeter.pendingId === modelData.id
        readonly property color tone: modelData.tone === "error" ? Tokens.errorColor : modelData.tone === "warning" ? Tokens.warningColor : Tokens.accentColor
        readonly property real ringGap: Tokens.padding / 2

        implicitWidth: lineRow.implicitWidth + Tokens.padding * 3
        implicitHeight: lineRow.implicitHeight + Tokens.padding
        radius: Tokens.radiusLarge
        color: selected ? Qt.alpha(tone, 0.14) : lineMouse.containsMouse ? Tokens.cardHoverColor : Qt.alpha(Tokens.cardHoverColor, 0)
        border.width: 1
        border.color: Qt.alpha(tone, selected ? 0.6 : 0)
        scale: lineMouse.pressed ? 0.96 : 1

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

        Behavior on scale {
            NumberAnimation {
                duration: Tokens.animDurationShort
            }
        }

        RowLayout {
            id: lineRow

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding
            anchors.rightMargin: Tokens.padding * 2
            spacing: Tokens.spacing

            Item {
                implicitWidth: Tokens.powerRowBoxSize + line.ringGap * 2
                implicitHeight: implicitWidth

                Rectangle {
                    anchors.centerIn: parent
                    width: Tokens.powerRowBoxSize
                    height: width
                    radius: Tokens.radiusLarge
                    color: line.selected ? line.tone : Tokens.surface1Color

                    Behavior on color {
                        ColorAnimation {
                            duration: Tokens.animDurationShort
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: line.modelData.glyph
                        font.family: Tokens.font
                        font.pixelSize: Tokens.fontSizeIconSmall
                        color: line.selected ? Tokens.textReverseColor : lineMouse.containsMouse ? line.tone : Tokens.textColor
                    }
                }

                Loader {
                    anchors.fill: parent
                    active: line.pending

                    sourceComponent: ProgressRing {
                        value: (1 - Greeter.pendingProgress) * 100
                        strokeWidth: Math.max(2, Tokens.padding / 2)
                        color: line.tone
                        trackColor: Qt.alpha(line.tone, 0.2)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: line.modelData.label
                elide: Text.ElideRight
                font.family: Tokens.font
                font.pixelSize: Tokens.fontSizeNormal
                font.bold: line.selected
                color: line.selected ? Tokens.textColor : Tokens.subtextColor
            }

            Text {
                visible: line.pending
                text: Math.ceil(Greeter.remaining / 1000) + "s"
                font.family: Tokens.font
                font.pixelSize: Tokens.fontSizeSmall
                font.bold: true
                color: line.tone
            }
        }

        MouseArea {
            id: lineMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Greeter.powerClicked(line.modelData.id);
                Greeter.focusRequested();
            }
        }
    }
}
