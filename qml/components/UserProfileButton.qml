import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import PDF_ToolKit 1.0

Rectangle {
    id: root
    width: profileLayout.width + Theme.spacingMedium * 2
    height: profileLayout.height + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    color: mouseArea.containsMouse ? Theme.cardSurfaceHover : "transparent"
    scale: mouseArea.pressed ? 0.97 : 1.0

    property alias nameText: nameLabel.text
    property alias emailText: emailLabel.text
    property alias photoSource: userImage.source

    anchors.rightMargin: Theme.spacingMedium
    anchors.topMargin: Theme.spacingMedium

    Behavior on color {
        ColorAnimation { duration: Theme.animationFast }
    }

    Behavior on scale {
        NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: profileLayout
        anchors.centerIn: parent
        spacing: Theme.spacingSmall

        // Circular profile image container
        Rectangle {
            width: Theme.iconSizeLarge
            height: Theme.iconSizeLarge
            radius: width / 2
            color: Theme.primaryContainer
            clip: true
            border.color: mouseArea.containsMouse ? Theme.primary : Theme.outlineVariant
            border.width: mouseArea.containsMouse ? 2 : 1

            Behavior on border.color {
                ColorAnimation { duration: Theme.animationFast }
            }

            Image {
                id: userImage
                anchors.fill: parent
                source: root.photoSource ? root.photoSource : ""
                fillMode: Image.PreserveAspectCrop
                visible: root.photoSource !== ""
                asynchronous: true
                cache: true
            }

            // Fallback icon
            Image {
                anchors.centerIn: parent
                width: Theme.iconSizeMedium
                height: Theme.iconSizeMedium
                source: "qrc:/PDF_ToolKit/resources/icons/default_user.svg"
                visible: !root.photoSource || root.photoSource === ""
                sourceSize.width: Theme.iconSizeMedium
                sourceSize.height: Theme.iconSizeMedium
            }
        }

        ColumnLayout {
            spacing: Theme.spacingTiny
            Label {
                id: nameLabel
                text: AuthManager.userName
                font.pixelSize: Theme.fontSizeCaption
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
                verticalAlignment: Text.AlignVCenter
            }
            Label {
                id: emailLabel
                text: AuthManager.userEmail
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.surfaceVariantForeground
                verticalAlignment: Text.AlignVCenter
            }
        }

        Image {
            id: arrowIcon
            source: "qrc:/PDF_ToolKit/resources/icons/arrow_down.svg"
            sourceSize.width: Theme.iconSizeSmall
            sourceSize.height: Theme.iconSizeSmall
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
            opacity: mouseArea.containsMouse ? 1 : 0.6
            rotation: profileMenu.visible ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
            }

            Behavior on opacity {
                NumberAnimation { duration: Theme.animationFast }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: profileMenu.open()
    }

    Menu {
        id: profileMenu
        x: root.width - width // Align menu to the right of the button
        y: root.height + Theme.spacingTiny // Position below the button
        width: 200 // Adjust as needed
        Material.elevation: 4

        background: Rectangle {
            implicitWidth: 220
            radius: Theme.radiusMedium
            color: Theme.surface
            border.width: 1
            border.color: Theme.outlineVariant

            // Shadow - similar to existing Menu shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                z: -1
                radius: parent.radius + 2
                color: Theme.shadowMedium
                anchors.topMargin: 4
            }
        }


        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingMedium
            spacing: Theme.spacingSmall

            RowLayout {
                spacing: Theme.spacingSmall

                // Circular profile image in menu
                Rectangle {
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                    radius: width / 2
                    color: Theme.primaryContainer
                    clip: true
                    border.color: Theme.outlineVariant
                    border.width: 1

                    Image {
                        anchors.fill: parent
                        source: root.photoSource ? root.photoSource : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: root.photoSource !== ""
                        asynchronous: true
                        cache: true
                    }

                    // Fallback icon
                    Image {
                        anchors.centerIn: parent
                        width: Theme.iconSizeSmall
                        height: Theme.iconSizeSmall
                        source: "qrc:/PDF_ToolKit/resources/icons/default_user.svg"
                        visible: !root.photoSource || root.photoSource === ""
                        sourceSize.width: Theme.iconSizeSmall
                        sourceSize.height: Theme.iconSizeSmall
                    }
                }
                ColumnLayout {
                    Label {
                        text: AuthManager.userName
                        font.pixelSize: Theme.fontSizeCaption
                        font.weight: Font.DemiBold
                        color: Theme.surfaceForeground
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Label {
                        text: AuthManager.userEmail
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.surfaceVariantForeground
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.outlineVariant
                opacity: 0.5
            }

            MenuItem {
                text: qsTr("Sign Out")
                icon.source: "qrc:/PDF_ToolKit/resources/icons/logout.svg" // Assuming a logout icon exists
                icon.color: Theme.error
                onTriggered: {
                    AuthManager.signOut()
                    profileMenu.close()
                }
            }
        }
    }
}
