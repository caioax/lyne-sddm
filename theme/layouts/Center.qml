pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Layout "center" (the lock screen's template of the same name): clock,
// avatar, user and password in the middle, the session bottom left and the
// power buttons bottom right
Item {
    id: root

    property bool shown: false

    opacity: shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.animDurationLong
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.shown ? -Tokens.fontSizeIconLarge : 0
        spacing: Tokens.spacing * 2

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: Tokens.animDurationLong
                easing.type: Tokens.animPopupEasing
            }
        }

        Clock {
            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            implicitHeight: Tokens.spacing * 2
        }

        Avatar {
            Layout.alignment: Qt.AlignHCenter
            user: Greeter.user
        }

        UserSwitcher {
            Layout.alignment: Qt.AlignHCenter
        }

        PasswordField {
            Layout.alignment: Qt.AlignHCenter
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
