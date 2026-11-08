pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Layout "split": a side panel slides in with the clock, the user and the
// password (the session at its foot); the wallpaper stays sharp beside it
// and the power buttons sit in the corner
Item {
    id: root

    property bool shown: false
    readonly property bool blurred: false

    opacity: shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.animDurationLong
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: panel

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: root.shown ? 0 : -width
        width: Math.max(Tokens.splitPanelWidth, root.width * Tokens.splitPanelShare)
        color: Tokens.barColor

        Behavior on x {
            NumberAnimation {
                duration: Tokens.animDurationLong
                easing.type: Tokens.animPopupEasing
            }
        }

        // Edge line
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Tokens.cardBorderColor
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.edgeMargin
            spacing: Tokens.spacing * 2

            Clock {
                alignment: Qt.AlignLeft
                size: Tokens.splitClockSize
            }

            Item {
                implicitHeight: Tokens.spacing * 4
            }

            RowLayout {
                spacing: Tokens.spacing * 2

                Avatar {
                    user: Greeter.user
                    size: Tokens.splitAvatarSize
                }

                UserSwitcher {}
            }

            PasswordField {
                fieldWidth: panel.width - Tokens.edgeMargin * 2
            }
        }

        SessionPicker {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.edgeMargin
            maxWidth: panel.width - Tokens.edgeMargin * 2
        }
    }

    PowerButtons {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.edgeMargin
    }
}
