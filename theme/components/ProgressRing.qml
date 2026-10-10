pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import ".."

// Circular progress, `value` 0..100, from 12 o'clock clockwise
Item {
    id: root

    property real value: 0
    property real strokeWidth: Tokens.padding
    property color color: Tokens.accentColor
    property color trackColor: Tokens.surface2Color

    readonly property real _radius: (Math.min(width, height) - strokeWidth) / 2

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(100, root.value)) / 100
            }
        }
    }
}
