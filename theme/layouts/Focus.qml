pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Layout "focus": only a big clock over the sharp wallpaper; typing blurs
// it, shrinks the clock and brings the avatar and the password up under it
Item {
    id: root

    property bool shown: false

    readonly property bool typing: Greeter.buffer !== "" || Greeter.authenticating || Greeter.failed || Greeter.pendingId !== "" || Greeter.selectedId !== ""
    // Read by Main: sharp until something is typed
    readonly property bool blurred: typing

    opacity: shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.animDurationLong
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.typing ? -Tokens.fontSizeIconLarge * 2 : 0
        spacing: Tokens.spacing * 2

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: Tokens.animDurationLong
                easing.type: Tokens.animPopupEasing
            }
        }

        Clock {
            Layout.alignment: Qt.AlignHCenter
            size: root.typing ? Tokens.clockSize : Tokens.focusClockSize
            shadow: !root.typing

            Behavior on size {
                NumberAnimation {
                    duration: Tokens.animDurationLong
                    easing.type: Tokens.animPopupEasing
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing * 2
            opacity: root.typing ? 1 : 0
            scale: root.typing ? 1 : Tokens.animPopupFromScale

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.animDuration
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Tokens.animDurationLong
                    easing.type: Tokens.animPopupEasing
                }
            }

            Avatar {
                Layout.alignment: Qt.AlignHCenter
                user: Greeter.user
                size: Tokens.focusAvatarSize
            }

            UserSwitcher {
                Layout.alignment: Qt.AlignHCenter
            }

            PasswordField {
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // Hint while idle
    Pill {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.edgeMargin
        icon: "\u{f030c}"
        text: qsTr("Start typing to log in")
        interactive: false
        opacity: root.typing ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.animDuration
            }
        }
    }

    SessionPicker {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.edgeMargin
    }

    PowerButtons {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.edgeMargin
    }
}
