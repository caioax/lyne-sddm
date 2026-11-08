import QtQuick

// The current time in `now`, updated on the minute: it wakes up at the next
// minute instead of polling every second
Timer {
    id: root

    property date now: new Date()

    interval: (60 - now.getSeconds()) * 1000 - now.getMilliseconds() + 50
    running: true
    repeat: true
    onTriggered: now = new Date()
}
