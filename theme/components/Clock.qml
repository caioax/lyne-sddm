import QtQuick
import QtQuick.Layouts
import ".."

// Time and date, ticking on the minute. `size` is the time's pixel size (the
// date follows it); `alignment` lines both up left, center or right
ColumnLayout {
    id: root

    property real size: Tokens.clockSize
    property int alignment: Qt.AlignHCenter
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
        Layout.alignment: root.alignment
        text: Tokens.locale.toString(root.now, Tokens.clockFormat)
        font.family: Tokens.font
        font.pixelSize: root.size
        font.bold: true
        color: Tokens.textColor
    }

    Text {
        Layout.alignment: root.alignment
        text: Tokens.locale.toString(root.now, Tokens.dateFormat)
        font.family: Tokens.font
        font.pixelSize: Math.max(Tokens.fontSizeLarge, Math.round(root.size / 5))
        color: Tokens.subtextColor
    }
}
