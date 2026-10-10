pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Password pill (from the lyne-dots LockInput): a dot per typed character
// (Greeter.buffer, typed into Main's hidden input) followed by a blinking
// caret, a spinner while the login is checked, a shake on failure, and the
// Caps Lock / error line below. The arrow submits
ColumnLayout {
    id: root

    spacing: Tokens.spacing

    Rectangle {
        id: field

        property real shakeX: 0

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Tokens.fieldWidth
        implicitHeight: Tokens.fieldHeight
        radius: height / 2
        color: Tokens.cardColor
        border.width: 1
        // Accent while ready: typing goes here without clicking
        border.color: Greeter.failed ? Tokens.errorColor : Qt.alpha(Tokens.accentColor, Greeter.buffer !== "" ? 0.8 : 0.45)

        transform: Translate {
            x: field.shakeX
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Tokens.animDurationShort
            }
        }

        // The dots: a fixed row where only the one just typed pops. Past
        // what fits, the last dot pops again for each new character
        Row {
            id: dots

            readonly property int capacity: Math.max(1, Math.floor((width - Tokens.spacing + spacing) / (Tokens.dotSize + spacing)))
            readonly property int shownCount: Math.min(Greeter.buffer.length, capacity)
            property int lastLength: 0

            anchors.left: parent.left
            anchors.right: submit.left
            anchors.leftMargin: field.height / 2
            anchors.rightMargin: Tokens.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.padding

            Connections {
                target: Greeter

                function onBufferChanged() {
                    const length = Greeter.buffer.length;
                    if (length > dots.lastLength && length > 0) {
                        const dot = dotRepeater.itemAt(dots.shownCount - 1);
                        if (dot)
                            dot.pop();
                    }
                    dots.lastLength = length;
                }
            }

            Repeater {
                id: dotRepeater

                model: dots.capacity

                Rectangle {
                    id: dot

                    required property int index

                    function pop() {
                        popAnim.restart();
                    }

                    visible: index < dots.shownCount
                    width: Tokens.dotSize
                    height: width
                    radius: width / 2
                    color: Tokens.textColor

                    SequentialAnimation {
                        id: popAnim

                        NumberAnimation {
                            target: dot
                            property: "scale"
                            from: 0.4
                            to: 1.25
                            duration: Tokens.animDurationShort
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: dot
                            property: "scale"
                            to: 1
                            duration: Tokens.animDurationShort
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }

            // Blinking caret after the dots: the field always takes input
            Rectangle {
                visible: !Greeter.authenticating
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(2, Tokens.padding / 3)
                height: Tokens.fontSizeNormal * 1.3
                radius: width / 2
                color: Tokens.accentColor

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true

                    NumberAnimation {
                        to: 1
                        duration: 0
                    }
                    PauseAnimation {
                        duration: Tokens.animDurationLong + Tokens.animDuration
                    }
                    NumberAnimation {
                        to: 0
                        duration: Tokens.animDuration
                    }
                    PauseAnimation {
                        duration: Tokens.animDurationLong
                    }
                }
            }

            Text {
                visible: Greeter.buffer === ""
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: Tokens.padding
                text: Greeter.authenticating ? qsTr("Checking…") : qsTr("Type your password")
                font.family: Tokens.font
                font.pixelSize: Tokens.fontSizeNormal
                color: Greeter.authenticating ? Tokens.accentColor : Tokens.mutedColor
            }
        }

        // Clicking the field doesn't need to do anything (it's always
        // focused), so it answers with a glow and takes the keyboard back
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: {
                glow.restart();
                Greeter.focusRequested();
            }
        }

        Rectangle {
            id: glowRing

            anchors.fill: parent
            anchors.margins: -Tokens.padding / 2
            radius: height / 2
            color: Qt.alpha(Tokens.accentColor, 0)
            border.width: Tokens.padding / 2
            border.color: Tokens.accentColor
            opacity: 0

            NumberAnimation {
                id: glow

                target: glowRing
                property: "opacity"
                from: 0.6
                to: 0
                duration: Tokens.animDurationLong
                easing.type: Easing.OutCubic
            }
        }

        // Submit, or the spinner while the login is checked
        Rectangle {
            id: submit

            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - Tokens.padding * 2
            height: width
            radius: width / 2
            color: Greeter.buffer !== "" ? Tokens.accentColor : submitMouse.containsMouse ? Tokens.cardHoverColor : Qt.alpha(Tokens.cardHoverColor, 0)

            Behavior on color {
                ColorAnimation {
                    duration: Tokens.animDurationShort
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !Greeter.authenticating
                text: "\u{f0054}"
                font.family: Tokens.font
                font.pixelSize: Tokens.fontSizeIconSmall
                color: Greeter.buffer !== "" ? Tokens.textReverseColor : Tokens.mutedColor
            }

            Spinner {
                anchors.centerIn: parent
                running: Greeter.authenticating
            }

            MouseArea {
                id: submitMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Greeter.login();
                    Greeter.focusRequested();
                }
            }
        }

        SequentialAnimation {
            id: shake

            NumberAnimation {
                target: field
                property: "shakeX"
                to: Tokens.spacing * 1.5
                duration: Tokens.animDurationShort / 2
            }
            NumberAnimation {
                target: field
                property: "shakeX"
                to: -Tokens.spacing * 1.2
                duration: Tokens.animDurationShort / 2
            }
            NumberAnimation {
                target: field
                property: "shakeX"
                to: Tokens.spacing * 0.8
                duration: Tokens.animDurationShort / 2
            }
            NumberAnimation {
                target: field
                property: "shakeX"
                to: 0
                duration: Tokens.animDurationShort / 2
            }
        }

        Connections {
            target: Greeter

            function onFailedChanged() {
                if (Greeter.failed)
                    shake.restart();
            }
        }
    }

    // Caps Lock and the last error
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: Tokens.fontSizeNormal * 1.5
        spacing: Tokens.spacing * 2

        Text {
            visible: Greeter.capsLock
            text: "\u{f0632}  " + qsTr("Caps Lock is on")
            font.family: Tokens.font
            font.pixelSize: Tokens.fontSizeSmall
            color: Tokens.warningColor
        }

        Text {
            visible: Greeter.failed
            text: Greeter.failMessage + (Greeter.attempts > 1 ? " " + qsTr("(%1 attempts)").arg(Greeter.attempts) : "")
            font.family: Tokens.font
            font.pixelSize: Tokens.fontSizeSmall
            color: Tokens.errorColor
        }
    }
}
