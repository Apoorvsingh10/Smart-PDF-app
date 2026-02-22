import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

Rectangle {
    id: root
    property double progress: 0
    property string message: ""

    anchors.fill: parent
    color: "#80000000"
    z: 99

    // Fade in animation
    opacity: 0
    Component.onCompleted: opacity = 1

    Behavior on opacity {
        NumberAnimation { duration: Theme.animationNormal }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {} // Block clicks
    }

    // Overlay card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 320)
        height: contentColumn.height + Theme.spacingXLarge * 2
        radius: Theme.radiusLarge
        color: Theme.surface

        // Shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            z: -1
            radius: parent.radius + 2
            color: "transparent"
            
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 8
                radius: parent.radius
                color: Theme.shadowMedium
            }
        }

        // Entrance animation
        scale: 0.9
        Component.onCompleted: scale = 1

        Behavior on scale {
            NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutBack }
        }

        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            width: parent.width - Theme.spacingLarge * 2
            spacing: Theme.spacingLarge

            // Animated loading indicator
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64

                // Spinning ring
                Rectangle {
                    id: spinnerRing
                    anchors.centerIn: parent
                    width: 56
                    height: 56
                    radius: 28
                    color: "transparent"
                    border.width: 4
                    border.color: Theme.surfaceVariant

                    // Active arc
                    Rectangle {
                        width: 56
                        height: 56
                        radius: 28
                        color: "transparent"
                        border.width: 4
                        border.color: Theme.primary
                        
                        // Mask to show only partial arc
                        layer.enabled: true
                        layer.effect: Item {
                            // Simple rotation for visual effect
                        }

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                            running: true
                        }
                    }
                }

                // Center icon
                Rectangle {
                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    radius: 20
                    color: Theme.primaryContainer

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                        sourceSize.width: Theme.iconSizeMedium
                        sourceSize.height: Theme.iconSizeMedium
                    }
                }
            }

            // Message
            Label {
                Layout.fillWidth: true
                text: root.message
                font.pixelSize: Theme.fontSizeSubtitle
                font.weight: Font.Medium
                color: Theme.surfaceForeground
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            // Progress section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                // Progress bar with rounded ends
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Theme.surfaceVariant

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.gradientStart }
                            GradientStop { position: 1.0; color: Theme.gradientEnd }
                        }

                        Behavior on width {
                            NumberAnimation { duration: Theme.animationFast }
                        }
                    }
                }

                // Percentage
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(root.progress * 100) + "%"
                    font.pixelSize: Theme.fontSizeBody
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
            }
        }
    }
}
