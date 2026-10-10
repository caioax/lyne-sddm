pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Bottom left: the session pill, opening the list of sessions above it, and
// the keyboard layout pill (only with more than one layout), which cycles
RowLayout {
    id: root

    property bool open: false
    // Row under the keyboard while the list is open
    property int highlighted: Greeter.sessionIndex

    function toggle(): void {
        highlighted = Greeter.sessionIndex;
        open = !open;
    }

    function move(step: int): void {
        const count = Greeter.sessions.length;
        if (count > 0)
            highlighted = (highlighted + step + count) % count;
    }

    function pick(): void {
        Greeter.sessionIndex = highlighted;
        open = false;
    }

    spacing: Tokens.spacing

    Pill {
        id: sessionPill

        icon: "\u{f0379}"
        text: (Greeter.session?.name ?? "") + "  " + (root.open ? "\u{f0143}" : "\u{f0140}")
        accent: Tokens.accentColor
        active: root.open
        onClicked: {
            root.toggle();
            Greeter.focusRequested();
        }

        // Sessions, growing up from the pill
        Rectangle {
            id: list

            anchors.left: parent.left
            anchors.bottom: parent.top
            anchors.bottomMargin: Tokens.spacing
            width: Math.max(parent.width, column.implicitWidth + Tokens.padding * 2)
            height: column.implicitHeight + Tokens.padding * 2
            radius: Tokens.radiusLarge
            color: Tokens.cardColor
            border.width: 1
            border.color: Tokens.cardBorderColor
            transformOrigin: Item.BottomLeft
            visible: opacity > 0
            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : Tokens.animPopupFromScale

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Tokens.animDurationLong
                    easing.type: Tokens.animPopupEasing
                }
            }

            ColumnLayout {
                id: column

                anchors.fill: parent
                anchors.margins: Tokens.padding
                spacing: 0

                Repeater {
                    model: Greeter.sessions

                    Rectangle {
                        id: entry

                        required property var modelData
                        required property int index
                        readonly property bool current: index === Greeter.sessionIndex

                        Layout.fillWidth: true
                        implicitWidth: entryRow.implicitWidth + Tokens.padding * 4
                        implicitHeight: Tokens.pillHeight
                        radius: Tokens.radius
                        color: entryMouse.containsMouse || index === root.highlighted ? Tokens.cardHoverColor : Qt.alpha(Tokens.cardHoverColor, 0)

                        Behavior on color {
                            ColorAnimation {
                                duration: Tokens.animDurationShort
                            }
                        }

                        RowLayout {
                            id: entryRow

                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding * 2
                            anchors.rightMargin: Tokens.padding * 2
                            spacing: Tokens.spacing

                            Text {
                                Layout.fillWidth: true
                                text: entry.modelData.name
                                font.family: Tokens.font
                                font.pixelSize: Tokens.fontSizeNormal
                                font.bold: entry.current
                                color: entry.current ? Tokens.textColor : Tokens.subtextColor
                            }

                            Text {
                                visible: entry.current
                                text: "\u{f012c}"
                                font.family: Tokens.font
                                font.pixelSize: Tokens.fontSizeIconSmall
                                color: Tokens.accentColor
                            }
                        }

                        MouseArea {
                            id: entryMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.highlighted = entry.index
                            onClicked: {
                                root.highlighted = entry.index;
                                root.pick();
                                Greeter.focusRequested();
                            }
                        }
                    }
                }
            }
        }
    }

    Pill {
        readonly property var layouts: keyboard.layouts ?? []
        readonly property int current: keyboard.currentLayout

        visible: layouts.length > 1
        icon: "\u{f030c}"
        text: layouts[current]?.shortName ?? ""
        onClicked: {
            keyboard.currentLayout = (current + 1) % layouts.length;
            Greeter.focusRequested();
        }
    }
}
