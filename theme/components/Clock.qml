import QtQuick
import QtQuick.Layouts
import ".."

// Time and date, ticking on the minute
ColumnLayout {
    id: root

    property date now: new Date()

    spacing: 0

    Timer {
        // Wakes up at the next minute instead of polling every second
        interval: (60 - root.now.getSeconds()) * 1000 - root.now.getMilliseconds() + 50
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Tokens.locale.toString(root.now, Tokens.clockFormat)
        font.family: Tokens.font
        font.pixelSize: Tokens.clockSize
        font.bold: true
        color: Tokens.textColor
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Tokens.locale.toString(root.now, Tokens.dateFormat)
        font.family: Tokens.font
        font.pixelSize: Tokens.dateSize
        color: Tokens.subtextColor
    }
}
