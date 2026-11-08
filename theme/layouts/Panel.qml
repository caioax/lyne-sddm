pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Layout "panel": a top bar like the lyne-dots one (the session on the
// left, time and date in the middle, the power buttons on the right) and a
// big avatar with the password in the middle
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

    Ticker {
        id: ticker
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.spacing
        height: Tokens.panelBarHeight
        radius: Tokens.radiusLarge
        color: Tokens.barColor
        border.width: 1
        border.color: Tokens.cardBorderColor

        SessionPicker {
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding * 2
            anchors.verticalCenter: parent.verticalCenter
            opensDown: true
        }

        Text {
            anchors.centerIn: parent
            text: Tokens.locale.toString(ticker.now, Tokens.clockFormat) + "  ·  " + Tokens.locale.toString(ticker.now, Tokens.dateFormat)
            font.family: Tokens.font
            font.pixelSize: Tokens.fontSizeLarge
            font.bold: true
            color: Tokens.textColor
        }

        // The ring and the seconds in the box show the countdown here
        PowerButtons {
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding
            anchors.verticalCenter: parent.verticalCenter
            showHint: false
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing * 2

        Avatar {
            Layout.alignment: Qt.AlignHCenter
            user: Greeter.user
            size: Tokens.panelAvatarSize
        }

        UserSwitcher {
            Layout.alignment: Qt.AlignHCenter
        }

        PasswordField {
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
