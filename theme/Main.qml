pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "components"

// One per screen. The primary screen shows the chosen layout (layouts/, the
// lock screen's templates); other screens show only the clock (each screen
// has its own engine, so they can't share the input). Keys go to the hidden
// input below whatever the layout
Item {
    id: root

    property bool ready: false
    readonly property bool shown: ready && !Greeter.succeeded

    Component.onCompleted: Qt.callLater(() => ready = true)

    // The keyboard goes to the active window: make it the primary one, even
    // with the pointer on another screen (X11 without a window manager).
    // The view only gets its window after this item completes
    Window.onWindowChanged: activate()

    function activate() {
        if (primaryScreen)
            Window.window?.requestActivate();
    }

    // The other screens' windows map after this one and the focus can land
    // there: ask again until the primary window is active, for a few seconds
    Timer {
        property int tries: 0

        interval: 250
        repeat: true
        running: primaryScreen && !(root.Window.window?.active ?? false) && tries < 20
        onTriggered: {
            tries++;
            root.activate();
        }
    }

    Background {
        anchors.fill: parent
        revealed: root.shown
        // Layouts may keep the wallpaper sharp (`blurred`); other screens blur
        blurred: !primaryScreen || (layout.item?.blurred ?? true)
    }

    // Clicks anywhere close the session list and take the keyboard back
    MouseArea {
        anchors.fill: parent
        onClicked: {
            Greeter.sessionsOpen = false;
            input.forceActiveFocus();
        }
    }

    // The primary screen's content: layouts/<Name>.qml from the layout token.
    // A layout is an Item with `shown` (set here) and, optionally, a
    // readonly `blurred` (false keeps the wallpaper sharp). A missing or
    // broken one falls back to center
    Loader {
        id: layout

        anchors.fill: parent
        active: primaryScreen
        source: Tokens.layoutSource

        onStatusChanged: {
            if (status === Loader.Error && Tokens.layout !== "center") {
                console.warn("lyne-sddm: layout", Tokens.layout, "not found, using center");
                source = Tokens.layoutUrl("center");
            }
        }

        Binding {
            target: layout.item
            property: "shown"
            value: root.shown
            when: layout.status === Loader.Ready
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
                if (Greeter.sessionsOpen)
                    Greeter.pickSession();
                else
                    Greeter.login();
                break;
            case Qt.Key_Escape:
                if (Greeter.sessionsOpen)
                    Greeter.sessionsOpen = false;
                else if (Greeter.selectedId !== "")
                    Greeter.cancelPower();
                else
                    Greeter.buffer = "";
                break;
            case Qt.Key_Up:
            case Qt.Key_Down:
                if (Greeter.sessionsOpen)
                    Greeter.moveSession(event.key === Qt.Key_Up ? -1 : 1);
                break;
            case Qt.Key_F1:
                Greeter.toggleSessions();
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
