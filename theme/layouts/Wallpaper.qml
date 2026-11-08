pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Layout "wallpaper" (the lock screen's template of the same name): the
// wallpaper stays sharp with the clock in the top left corner; typing
// raises the password bar from the bottom and blurs the background
Item {
    id: root

    property bool shown: false

    readonly property bool typing: Greeter.buffer !== "" || Greeter.authenticating || Greeter.failed || Greeter.pendingId !== ""
    // Read by Main: sharp until something is typed
    readonly property bool blurred: typing

    opacity: shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.animDurationLong
            easing.type: Easing.OutCubic
        }
    }

    Clock {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Tokens.wallpaperMargin
        alignment: Qt.AlignLeft
        size: Tokens.wallpaperClockSize
    }

    // Hint while idle
    Pill {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.wallpaperMargin
        icon: "\u{f030c}"
        text: qsTr("Type your password to log in")
        interactive: false
        opacity: root.typing ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.animDuration
            }
        }
    }

    // Password bar: rises from below the edge while typing
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.typing ? parent.height - height - Tokens.wallpaperMargin : parent.height
        width: barRow.implicitWidth + Tokens.padding * 8
        height: barRow.implicitHeight + Tokens.padding * 6
        radius: Tokens.cardsRadius
        color: Tokens.barColor
        opacity: root.typing ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: Tokens.animDurationLong
                easing.type: Tokens.animPopupEasing
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.animDuration
            }
        }

        RowLayout {
            id: barRow

            anchors.centerIn: parent
            spacing: Tokens.spacing * 2

            Avatar {
                Layout.alignment: Qt.AlignTop
                user: Greeter.user
                size: Tokens.barAvatarSize
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                spacing: Tokens.spacing

                // Who is logging in, when there is a choice
                UserSwitcher {
                    visible: Greeter.users.length > 1
                    Layout.alignment: Qt.AlignHCenter
                }

                PasswordField {}
            }

            PowerButtons {
                Layout.alignment: Qt.AlignTop
            }
        }
    }

    SessionPicker {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.wallpaperMargin
    }

    // Power buttons stay reachable in the corner while idle
    PowerButtons {
        visible: !root.typing
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.wallpaperMargin
    }
}
