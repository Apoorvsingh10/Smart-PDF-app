import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

Item {
    id: root
    anchors.fill: parent

    function show(message, type) {
        toastLabel.text = message
        
        // Set colors and icon based on type
        if (type === "error") {
            toastRect.bgColor = Theme.errorContainer
            toastLabel.color = Theme.error
            toastIcon.text = "✕"
            toastIcon.color = Theme.error
        } else if (type === "success") {
            toastRect.bgColor = Theme.successContainer
            toastLabel.color = Theme.success
            toastIcon.text = "✓"
            toastIcon.color = Theme.success
        } else {
            toastRect.bgColor = Theme.surfaceContainerHighest
            toastLabel.color = Theme.surfaceForeground
            toastIcon.text = "ℹ"
            toastIcon.color = Theme.primary
        }
        
        showAnimation.start()
        hideTimer.restart()
    }

    Rectangle {
        id: toastRect
        property color bgColor: Theme.surfaceContainerHighest
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.bottomNavHeight + Theme.spacingLarge
        width: Math.min(parent.width - 32, toastContent.width + Theme.spacingLarge * 2)
        height: 52
        radius: Theme.radiusFull
        color: bgColor
        opacity: 0
        scale: 0.8

        // Shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            z: -1
            radius: parent.radius + 1
            color: "transparent"
            
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 4
                radius: parent.radius
                color: Theme.shadowMedium
            }
        }

        Behavior on bgColor {
            ColorAnimation { duration: Theme.animationFast }
        }

        RowLayout {
            id: toastContent
            anchors.centerIn: parent
            spacing: Theme.spacingSmall

            // Icon badge
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                color: Qt.rgba(toastIcon.color.r, toastIcon.color.g, toastIcon.color.b, 0.2)

                Label {
                    id: toastIcon
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeBody
                    font.weight: Font.Bold
                    color: Theme.primary
                    text: "ℹ"
                }
            }

            Label {
                id: toastLabel
                font.pixelSize: Theme.fontSizeBody
                font.weight: Font.Medium
                color: Theme.surfaceForeground
            }
        }
    }

    ParallelAnimation {
        id: showAnimation
        
        NumberAnimation {
            target: toastRect
            property: "opacity"
            to: 1
            duration: Theme.animationNormal
            easing.type: Easing.OutCubic
        }
        
        NumberAnimation {
            target: toastRect
            property: "scale"
            to: 1
            duration: Theme.animationNormal
            easing.type: Easing.OutBack
        }
        
        NumberAnimation {
            target: toastRect
            property: "anchors.bottomMargin"
            from: Theme.bottomNavHeight
            to: Theme.bottomNavHeight + Theme.spacingLarge
            duration: Theme.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: hideAnimation
        
        NumberAnimation {
            target: toastRect
            property: "opacity"
            to: 0
            duration: Theme.animationFast
            easing.type: Easing.InCubic
        }
        
        NumberAnimation {
            target: toastRect
            property: "scale"
            to: 0.8
            duration: Theme.animationFast
        }
        
        NumberAnimation {
            target: toastRect
            property: "anchors.bottomMargin"
            to: Theme.bottomNavHeight
            duration: Theme.animationFast
        }
    }

    Timer {
        id: hideTimer
        interval: 3500
        onTriggered: hideAnimation.start()
    }
}
