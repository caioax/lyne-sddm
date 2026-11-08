pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Layout "cards" (the lock screen's template of the same name, with what a
// login screen knows): three glass cards side by side. The users of the
// machine and its name; the clock with the password; the session and the
// power buttons
Item {
    id: root

    property bool shown: false

    opacity: shown ? 1 : 0
    scale: shown ? 1 : Tokens.animPopupFromScale

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.animDurationLong
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Tokens.animDurationLong
            easing.type: Tokens.animPopupEasing
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing * 2

        // ========== USERS + HOST ==========
        Card {
            Layout.preferredWidth: Tokens.cardsSideWidth

            Heading {
                text: qsTr("Users")
            }

            Repeater {
                model: Greeter.users

                UserRow {
                    Layout.fillWidth: true
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Pill {
                visible: Greeter.hostName !== ""
                icon: "\u{f0322}"
                text: Greeter.hostName
                interactive: false
            }
        }

        // ========== CLOCK + PASSWORD ==========
        Card {
            Clock {
                Layout.alignment: Qt.AlignHCenter
                size: Tokens.cardsClockSize
            }

            Item {
                implicitHeight: Tokens.spacing
            }

            Avatar {
                Layout.alignment: Qt.AlignHCenter
                user: Greeter.user
                size: Tokens.cardsAvatarSize
            }

            UserSwitcher {
                Layout.alignment: Qt.AlignHCenter
            }

            PasswordField {
                Layout.alignment: Qt.AlignHCenter
                fieldWidth: Tokens.cardsFieldWidth
            }
        }

        // ========== SESSION + POWER ==========
        Card {
            Layout.preferredWidth: Tokens.cardsSideWidth

            Heading {
                text: qsTr("Session")
            }

            SessionPicker {
                opensDown: true
                maxWidth: Tokens.cardsSideWidth - Tokens.cardsPadding * 2
            }

            Item {
                Layout.fillHeight: true
            }

            PowerButtons {
                Layout.fillWidth: true
                rows: true
            }
        }
    }

    // Glass card with a column inside; the side cards stretch to the middle
    component Card: Rectangle {
        default property alias content: column.data

        Layout.fillHeight: true
        implicitWidth: column.implicitWidth + Tokens.cardsPadding * 2
        implicitHeight: column.implicitHeight + Tokens.cardsPadding * 2
        radius: Tokens.cardsRadius
        color: Tokens.cardColor
        border.width: 1
        border.color: Tokens.cardBorderColor

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: Tokens.cardsPadding
            spacing: Tokens.spacing
        }
    }

    component Heading: Text {
        font.family: Tokens.font
        font.pixelSize: Tokens.fontSizeLarge
        font.bold: true
        color: Tokens.textColor
    }

    // One user: picture and name, the chosen one highlighted; a click picks it
    component UserRow: Rectangle {
        id: row

        required property var modelData
        required property int index
        readonly property bool current: index === Greeter.userIndex

        implicitWidth: rowLayout.implicitWidth + Tokens.padding * 3
        implicitHeight: rowLayout.implicitHeight + Tokens.padding
        radius: Tokens.radiusLarge
        color: current ? Qt.alpha(Tokens.accentColor, 0.14) : mouse.containsMouse ? Tokens.cardHoverColor : Qt.alpha(Tokens.cardHoverColor, 0)
        border.width: 1
        border.color: Qt.alpha(Tokens.accentColor, current ? 0.6 : 0)

        Behavior on color {
            ColorAnimation {
                duration: Tokens.animDurationShort
            }
        }

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding
            anchors.rightMargin: Tokens.padding * 2
            spacing: Tokens.spacing

            Avatar {
                Layout.topMargin: Tokens.padding / 2
                Layout.bottomMargin: Tokens.padding / 2
                user: row.modelData
                size: Tokens.listAvatarSize
            }

            Text {
                Layout.fillWidth: true
                text: row.modelData.realName || row.modelData.name
                elide: Text.ElideRight
                font.family: Tokens.font
                font.pixelSize: Tokens.fontSizeNormal
                font.bold: row.current
                color: row.current ? Tokens.textColor : Tokens.subtextColor
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Greeter.selectUser(row.index);
                Greeter.focusRequested();
            }
        }
    }
}
