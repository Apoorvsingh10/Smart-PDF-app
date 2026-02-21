import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

Rectangle {
    id: root
    property string selectedFileName: ""
    property color accentColor: Theme.primary
    signal clicked()

    implicitHeight: Theme.buttonHeight
    radius: Theme.radiusMedium
    color: mouseArea.containsMouse ? Theme.cardSurfaceHover : Theme.cardSurface
    border.width: 1
    border.color: mouseArea.containsMouse ? accentColor : Theme.outlineVariant
    scale: mouseArea.pressed ? 0.98 : 1.0

    Behavior on color {
        ColorAnimation { duration: Theme.animationFast }
    }

    Behavior on border.color {
        ColorAnimation { duration: Theme.animationFast }
    }

    Behavior on scale {
        NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
    }

    // Subtle shadow
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        z: -1
        radius: parent.radius + 1
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: mouseArea.containsMouse ? 4 : 2
            radius: parent.radius
            color: mouseArea.containsMouse ? Theme.shadowMedium : Theme.shadowLight
            opacity: mouseArea.containsMouse ? 1 : 0.5

            Behavior on anchors.topMargin {
                NumberAnimation { duration: Theme.animationFast }
            }

            Behavior on opacity {
                NumberAnimation { duration: Theme.animationFast }
            }
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.spacingSmall

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: Theme.radiusSmall
            color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)

            Image {
                anchors.centerIn: parent
                source: selectedFileName ? "qrc:/PDF_ToolKit/resources/icons/pdf.svg" : "qrc:/PDF_ToolKit/resources/icons/add.svg"
                sourceSize.width: Theme.iconSizeSmall
                sourceSize.height: Theme.iconSizeSmall
            }
        }

        Label {
            text: selectedFileName || qsTr("Select File")
            font.pixelSize: Theme.fontSizeBody
            font.weight: Font.Medium
            color: selectedFileName ? Theme.surfaceForeground : Theme.surfaceVariantForeground
            elide: Text.ElideMiddle
            Layout.maximumWidth: root.width - 80
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
