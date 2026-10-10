pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "components"

// One per screen. The primary screen shows the lock screen's "center"
// template: clock, avatar, user and password in the middle, the session
// bottom left and the power buttons bottom right. Other screens show only
// the clock (each screen has its own engine, so they can't share the input)
Item {
    id: root

    property bool ready: false
    readonly property bool shown: ready && !Greeter.succeeded

    Component.onCompleted: {
        Qt.callLater(() => ready = true);
        // The keyboard goes to the active window: make it the primary one
        if (primaryScreen)
            Window.window?.requestActivate();
    }

    Background {
        anchors.fill: parent
        revealed: root.shown
    }

    // Clicks anywhere close the session list and take the keyboard back
    MouseArea {
        anchors.fill: parent
        onClicked: {
            sessions.open = false;
            input.forceActiveFocus();
        }
    }

    Item {
        anchors.fill: parent
        visible: primaryScreen
        opacity: root.shown ? 1 : 0

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
            id: sessions

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

    // Other screens: just the time
    Clock {
        visible: !primaryScreen
        anchors.centerIn: parent
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.animDurationLong
                easing.type: Easing.OutCubic
            }
        }
    }

    // Takes every key; the field above only draws Greeter.buffer
    TextInput {
        id: input

        width: 1
        height: 1
        opacity: 0
        enabled: primaryScreen
        focus: primaryScreen
        echoMode: TextInput.Password
        text: Greeter.buffer

        onTextEdited: Greeter.buffer = text

        // Enter logs in (or picks the highlighted session), Esc backs out
        // of whatever is open; F1 sessions, F2 next user, F10/F11/F12
        // suspend/reboot/shut down (press again to run)
        Keys.onPressed: event => {
            event.accepted = true;
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (sessions.open)
                    sessions.pick();
                else
                    Greeter.login();
                break;
            case Qt.Key_Escape:
                if (sessions.open)
                    sessions.open = false;
                else if (Greeter.selectedId !== "")
                    Greeter.cancelPower();
                else
                    Greeter.buffer = "";
                break;
            case Qt.Key_Up:
            case Qt.Key_Down:
                if (sessions.open)
                    sessions.move(event.key === Qt.Key_Up ? -1 : 1);
                break;
            case Qt.Key_F1:
                sessions.toggle();
                break;
            case Qt.Key_F2:
                Greeter.cycleUser(1);
                break;
            case Qt.Key_F10:
            case Qt.Key_F11:
            case Qt.Key_F12:
                {
                    const id = {
                        [Qt.Key_F10]: "suspend",
                        [Qt.Key_F11]: "reboot",
                        [Qt.Key_F12]: "shutdown"
                    }[event.key];
                    if (Greeter.actions.some(a => a.id === id))
                        Greeter.powerClicked(id);
                    break;
                }
            case Qt.Key_CapsLock:
                Greeter.capsLockToggled();
                event.accepted = false;
                break;
            default:
                Greeter.guessCapsLock(event.text, (event.modifiers & Qt.ShiftModifier) !== 0);
                event.accepted = false;
            }
        }

        Connections {
            target: Greeter

            function onBufferChanged() {
                if (input.text !== Greeter.buffer)
                    input.text = Greeter.buffer;
            }

            function onFocusRequested() {
                input.forceActiveFocus();
            }
        }
    }
}
