pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick

// Login state of one screen (each SDDM screen has its own QML engine, so
// its own copy): the chosen user and session, the typed password, the last
// failure, Caps Lock, and the power actions with their countdown. In test
// mode logins are faked and every power action shows
Item {
    id: root

    // ========================================================================
    // USERS AND SESSIONS
    // ========================================================================
    // [{ name, realName, icon, needsPassword }] from userModel
    readonly property var users: _users
    property int userIndex: Math.max(0, userModel.lastIndex)
    readonly property var user: users[userIndex] ?? null

    // [{ name, file }] from sessionModel
    readonly property var sessions: _sessions
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    readonly property var session: sessions[sessionIndex] ?? null

    property var _users: []
    property var _sessions: []

    function cycleUser(step: int): void {
        if (users.length < 2)
            return;
        userIndex = (userIndex + step + users.length) % users.length;
        buffer = "";
        failed = false;
    }

    // ========================================================================
    // PASSWORD
    // ========================================================================
    property string buffer: ""
    property bool authenticating: false
    property bool failed: false
    property string failMessage: ""
    property int attempts: 0
    // Login accepted: the screen fades out before the session starts
    property bool succeeded: false

    // Asks the hidden input to take the keyboard back
    signal focusRequested

    function login(): void {
        if (authenticating || succeeded || !user)
            return;
        authenticating = true;
        failed = false;
        if (Tokens.testMode)
            fakeLogin.restart();
        else
            sddm.login(user.name, buffer, sessionIndex);
    }

    function _fail(message: string): void {
        authenticating = false;
        attempts++;
        failMessage = message !== "" ? message : qsTr("Wrong password");
        buffer = "";
        // Re-set so the shake runs again on a repeated failure
        failed = false;
        failed = true;
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root._fail(root._info);
            root._info = "";
        }

        function onLoginSucceeded() {
            root.authenticating = false;
            root.succeeded = true;
        }

        // PAM messages (expired password, account locked...), shown with
        // the next failure
        function onInformationMessage(message) {
            root._info = message;
        }
    }

    property string _info: ""

    Timer {
        id: fakeLogin

        interval: Tokens.animDurationLong * 2
        onTriggered: {
            if (root.buffer === "test") {
                root.authenticating = false;
                root.succeeded = true;
            } else {
                root._fail("");
            }
        }
    }

    // ========================================================================
    // CAPS LOCK
    // ========================================================================
    // keyboard.capsLock works under X11; on Wayland (and in test mode) it
    // stays false, so the typed letters tell it too
    property var _capsGuess: undefined
    readonly property bool capsLock: _capsGuess !== undefined ? _capsGuess : keyboard.capsLock

    Connections {
        target: keyboard

        function onCapsLockChanged() {
            root._capsGuess = undefined;
        }
    }

    // A letter typed with or without Shift
    function guessCapsLock(text: string, shift: bool): void {
        if (text.length !== 1 || text.toUpperCase() === text.toLowerCase())
            return;
        const upper = text === text.toUpperCase();
        _capsGuess = upper !== shift;
    }

    function capsLockToggled(): void {
        if (_capsGuess !== undefined)
            _capsGuess = !_capsGuess;
    }

    // ========================================================================
    // POWER
    // ========================================================================
    // First click selects an action, a second one runs it; destructive ones
    // count down first (Esc cancels)
    readonly property var allActions: [
        {
            id: "suspend",
            label: qsTr("Suspend"),
            glyph: "\u{f0904}",
            tone: "accent",
            available: sddm.canSuspend
        },
        {
            id: "reboot",
            label: qsTr("Reboot"),
            glyph: "\u{f0709}",
            tone: "warning",
            destructive: true,
            progress: qsTr("Rebooting"),
            available: sddm.canReboot
        },
        {
            id: "shutdown",
            label: qsTr("Shut down"),
            glyph: "\u{f0425}",
            tone: "error",
            destructive: true,
            progress: qsTr("Shutting down"),
            available: sddm.canPowerOff
        }
    ]
    readonly property var actions: allActions.filter(a => a.available || Tokens.testMode)

    property string selectedId: ""
    property string pendingId: ""
    readonly property var pending: allActions.find(a => a.id === pendingId) ?? null
    property int remaining: 0
    readonly property real pendingProgress: pendingId !== "" && Tokens.powerCountdown > 0 ? remaining / (Tokens.powerCountdown * 1000) : 0

    function powerClicked(id: string): void {
        if (selectedId !== id) {
            cancelPower();
            selectedId = id;
            return;
        }
        const action = allActions.find(a => a.id === id);
        if (pendingId === id || !action.destructive || Tokens.powerCountdown <= 0) {
            _runPower(id);
            return;
        }
        pendingId = id;
        remaining = Tokens.powerCountdown * 1000;
        countdown.restart();
    }

    function cancelPower(): void {
        countdown.stop();
        pendingId = "";
        selectedId = "";
        remaining = 0;
    }

    function _runPower(id: string): void {
        cancelPower();
        if (Tokens.testMode) {
            console.log("lyne-sddm: test mode, skipping", id);
            return;
        }
        if (id === "suspend")
            sddm.suspend();
        else if (id === "reboot")
            sddm.reboot();
        else if (id === "shutdown")
            sddm.powerOff();
    }

    Timer {
        id: countdown

        interval: 100
        repeat: true
        onTriggered: {
            root.remaining = Math.max(0, root.remaining - interval);
            if (root.remaining === 0)
                root._runPower(root.pendingId);
        }
    }

    // ========================================================================
    // MODELS
    // ========================================================================
    Instantiator {
        id: userList

        model: userModel
        delegate: QtObject {
            required property string name
            required property string realName
            required property string icon
            required property bool needsPassword
        }
        onObjectAdded: root._users = root._collect(userList)
        onObjectRemoved: root._users = root._collect(userList)
    }

    Instantiator {
        id: sessionList

        model: sessionModel
        delegate: QtObject {
            required property string name
            required property string file
        }
        onObjectAdded: root._sessions = root._collect(sessionList)
        onObjectRemoved: root._sessions = root._collect(sessionList)
    }

    function _collect(instantiator: Instantiator): var {
        const list = [];
        for (let i = 0; i < instantiator.count; i++) {
            const object = instantiator.objectAt(i);
            if (object)
                list.push(object);
        }
        return list;
    }
}
