pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Layout "corner": a big clock top right and a compact login card bottom
// left (user, host, password, session) over the sharp wallpaper, which
// blurs while typing
Item {
    id: root

    property bool shown: false

    readonly property bool typing: Greeter.buffer !== "" || Greeter.authenticating || Greeter.failed
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
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.cornerMargin
        alignment: Qt.AlignRight
        size: Tokens.cornerClockSize
        shadow: !root.typing
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.cornerMargin
        width: card.implicitWidth + Tokens.cardsPadding * 2
        height: card.implicitHeight + Tokens.cardsPadding * 2
        radius: Tokens.cardsRadius
        color: Tokens.cardColor
        border.width: 1
        border.color: Tokens.cardBorderColor

        ColumnLayout {
            id: card

            anchors.fill: parent
            anchors.margins: Tokens.cardsPadding
            spacing: Tokens.spacing * 1.5

            RowLayout {
                spacing: Tokens.spacing * 1.5

                Avatar {
                    user: Greeter.user
                    size: Tokens.cornerAvatarSize
                }

                ColumnLayout {
                    spacing: 0

                    UserSwitcher {}

                    Text {
                        visible: text !== ""
                        text: Greeter.hostName
                        font.family: Tokens.font
                        font.pixelSize: Tokens.fontSizeSmall
                        color: Tokens.subtextColor
                    }
                }
            }

            PasswordField {
                fieldWidth: Tokens.cardsFieldWidth
            }

            SessionPicker {
                maxWidth: Tokens.cardsFieldWidth
            }
        }
    }

    PowerButtons {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.cornerMargin
    }
}
