import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: root
    property string selectedFileName: ""

    text: selectedFileName || qsTr("Select File")
    icon.source: "qrc:/PDF_ToolKit/resources/icons/add.svg"
}
