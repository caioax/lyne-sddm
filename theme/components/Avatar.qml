pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import ".."

// The user's picture: avatars/<user>.png in the theme (written by the
// lyne-dots sync), then the account icon unless it's SDDM's default face,
// then a silhouette
Item {
    id: root

    property var user: null
    property real size: Tokens.avatarSize

    readonly property var sources: {
        if (!user)
            return [];
        const list = [Tokens.path("avatars/" + user.name + ".png")];
        if (user.icon !== "" && !user.icon.endsWith("/faces/.face.icon"))
            list.push(user.icon);
        return list;
    }
    property int sourceIndex: 0

    onSourcesChanged: sourceIndex = 0

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Tokens.surface1Color
    }

    Image {
        id: image

        anchors.fill: parent
        visible: false
        source: root.sources[root.sourceIndex] ?? ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        onStatusChanged: {
            if (status === Image.Error && root.sourceIndex < root.sources.length)
                root.sourceIndex++;
        }
    }

    MultiEffect {
        anchors.fill: parent
        visible: image.status === Image.Ready
        source: image
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: width / 2
        }
    }

    // md-account
    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: "\u{f0004}"
        font.family: Tokens.font
        font.pixelSize: root.size / 2
        color: Tokens.subtextColor
    }
}
