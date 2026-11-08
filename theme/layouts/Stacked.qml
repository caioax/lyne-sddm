pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Layout "stacked": huge hours over minutes left of the middle (the
// minutes in the accent color), a divider, and the date, the user and the
// password on the right
Item {
    id: root

    property bool shown: false

    // clockFormat split at its first colon ("HH:mm" gives "HH" and "mm")
    readonly property var parts: {
        const format = Tokens.clockFormat;
        const at = format.indexOf(":");
        return at < 0 ? [format, "mm"] : [format.slice(0, at), format.slice(at + 1)];
    }

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

    ColumnLayout {
        anchors.right: parent.horizontalCenter
        anchors.rightMargin: Tokens.edgeMargin * 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: -Tokens.stackedOverlap

        Digits {
            text: Tokens.locale.toString(ticker.now, root.parts[0])
        }

        Digits {
            text: Tokens.locale.toString(ticker.now, root.parts[1])
            color: Tokens.accentColor
        }
    }

    Rectangle {
        anchors.left: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: root.height * 0.4
        radius: 1
        color: Tokens.cardBorderColor
    }

    ColumnLayout {
        anchors.left: parent.horizontalCenter
        anchors.leftMargin: Tokens.edgeMargin * 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing * 2

        Text {
            text: Tokens.locale.toString(ticker.now, Tokens.dateFormat)
            font.family: Tokens.font
            font.pixelSize: Tokens.fontSizeIconLarge
            color: Tokens.subtextColor
        }

        Item {
            implicitHeight: Tokens.spacing * 2
        }

        RowLayout {
            spacing: Tokens.spacing * 2

            Avatar {
                user: Greeter.user
                size: Tokens.stackedAvatarSize
            }

            UserSwitcher {}
        }

        PasswordField {}
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

    component Digits: Text {
        Layout.alignment: Qt.AlignRight
        font.family: Tokens.font
        font.pixelSize: Tokens.stackedDigitSize
        font.bold: true
        color: Tokens.textColor
    }
}
