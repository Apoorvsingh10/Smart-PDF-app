import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import PDF_ToolKit 1.0

Item {
    id: root
    width: childrenRect.width
    height: childrenRect.height

    property alias nameText: nameLabel.text
    property alias emailText: emailLabel.text
    property alias photoSource: userImage.source

    anchors.rightMargin: Theme.spacingMedium
    anchors.topMargin: Theme.spacingMedium

    RowLayout {
        id: profileLayout
        anchors.fill: parent
        spacing: Theme.spacingSmall

        Image {
            id: userImage
            width: Theme.iconSizeLarge
            height: Theme.iconSizeLarge
            source: root.photoSource ? root.photoSource : "qrc:/PDF_ToolKit/resources/icons/default_user.svg" // Placeholder for a default user icon
            fillMode: Image.PreserveAspectCrop
            clip: true
            sourceSize.width: Theme.iconSizeLarge
            sourceSize.height: Theme.iconSizeLarge

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: Theme.outlineVariant
                border.width: 1
            }
        }

        ColumnLayout {
            spacing: Theme.spacingTiny
            Label {
                id: nameLabel
                text: AuthManager.userName
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.onSurface
                verticalAlignment: Text.AlignVCenter
            }
            Label {
                id: emailLabel
                text: AuthManager.userEmail
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.onSurfaceVariant
                verticalAlignment: Text.AlignVCenter
            }
        }

        Image {
            source: "qrc:/PDF_ToolKit/resources/icons/arrow_down.svg" // Placeholder for a dropdown arrow icon
            sourceSize.width: Theme.iconSizeSmall
            sourceSize.height: Theme.iconSizeSmall
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
            opacity: 0.6
        }
    }

    MouseArea {
        anchors.fill: parent
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
                Image {
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                    source: root.photoSource ? root.photoSource : "qrc:/PDF_ToolKit/resources/icons/default_user.svg"
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    sourceSize.width: Theme.iconSizeMedium
                    sourceSize.height: Theme.iconSizeMedium

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.color: Theme.outlineVariant
                        border.width: 1
                    }
                }
                ColumnLayout {
                    Label {
                        text: AuthManager.userName
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.onSurface
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Label {
                        text: AuthManager.userEmail
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.onSurfaceVariant
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
