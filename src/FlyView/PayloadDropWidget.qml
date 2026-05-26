import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: root

    Layout.preferredWidth:  ScreenTools.defaultFontPixelHeight * 12
    Layout.preferredHeight: Layout.preferredWidth

    radius:         width / 2
    color:          Qt.rgba(0, 0, 0, 0.45)
    border.width:   1
    border.color:   qgcPal.text

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var _dropStates:    [0, 0, 0, 0, 0, 0]
    property int _pendingIndex:  -1

    readonly property int _dropReady:    0
    readonly property int _dropPending:  1
    readonly property int _dropComplete: 2
    readonly property int _dropDisabled: 3

    signal dropCompleted(int dropIndex)

    QGCPalette {
        id: qgcPal
    }

    function dropState(index) {
        return _dropStates[index]
    }

    function setDropState(index, state) {
        var states = _dropStates.slice()
        states[index] = state
        _dropStates = states
    }

    function requestDrop(index) {
        if (!_activeVehicle || dropState(index) === _dropDisabled) {
            return
        }

        _pendingIndex = index
        setDropState(index, _dropPending)
        confirmDropDialog.open()
    }

    function resetPendingDrop() {
        if (_pendingIndex >= 0 && dropState(_pendingIndex) === _dropPending) {
            setDropState(_pendingIndex, _dropReady)
        }
        _pendingIndex = -1
    }

    function completeDrop() {
        if (_pendingIndex < 0 || !_activeVehicle) {
            resetPendingDrop()
            return
        }

        var dropIndex = _pendingIndex
        _activeVehicle.sendPayloadDrop(dropIndex + 1)
        setDropState(dropIndex, _dropComplete)
        dropCompleted(dropIndex)
        _pendingIndex = -1
        QGroundControl.showMessageDialog(root, qsTr("Payload Dropping"), qsTr("Payload Dropped"), Dialog.Ok)
    }

    QGCLabel {
        anchors.centerIn:       parent
        text:                   qsTr("Payload Dropping")
        color:                  qgcPal.text
        font.bold:              true
        horizontalAlignment:    Text.AlignHCenter
        width:                  parent.width * 0.45
        wrapMode:               Text.WordWrap
    }

    Repeater {
        model: 6

        Rectangle {
            id: dropButton

            required property int index

            readonly property real angle:  (index * 60) - 90
            readonly property real buttonPositionRadius: root.width * 0.36

            x: (root.width / 2)  + (buttonPositionRadius * Math.cos(angle * Math.PI / 180)) - (width / 2)
            y: (root.height / 2) + (buttonPositionRadius * Math.sin(angle * Math.PI / 180)) - (height / 2)

            width:                  ScreenTools.defaultFontPixelHeight * 3
            height:                 width
            radius:                 width / 2
            opacity:                root.dropState(dropButton.index) === root._dropDisabled ? 0.35 : 1
            color: {
                switch (root.dropState(dropButton.index)) {
                case root._dropPending:
                    return "skyblue"
                case root._dropComplete:
                    return "red"
                case root._dropDisabled:
                    return Qt.rgba(1, 1, 1, 0.18)
                default:
                    return "green"
                }
            }
            border.width: 1
            border.color: root.dropState(dropButton.index) === root._dropPending ? "red" : "white"

            QGCLabel {
                anchors.centerIn:       parent
                text:                   (index + 1).toString()
                color:                  "white"
                font.bold:              true
                font.pointSize:         ScreenTools.smallFontPointSize
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
            }

            MouseArea {
                anchors.fill:   parent
                enabled:        root.dropState(dropButton.index) !== root._dropDisabled
                onClicked:      root.requestDrop(dropButton.index)
            }

            Timer {
                id:         disableTimer
                interval:   3000
                repeat:     false

                onTriggered: root.setDropState(dropButton.index, root._dropDisabled)
            }

            Connections {
                target: root

                function onDropCompleted(dropIndex) {
                    if (dropIndex === dropButton.index) {
                        disableTimer.restart()
                    }
                }
            }
        }
    }

    MessageDialog {
        id:      confirmDropDialog
        title:   qsTr("Payload Dropping")
        text:    qsTr("Are you sure?")
        buttons: MessageDialog.Yes | MessageDialog.No

        onButtonClicked: function(button, role) {
            switch (button) {
            case MessageDialog.Yes:
                root.completeDrop()
                confirmDropDialog.close()
                break
            case MessageDialog.No:
                root.resetPendingDrop()
                confirmDropDialog.close()
                break
            }
        }
    }

    MouseArea {
        anchors.fill:       parent
        acceptedButtons:    Qt.RightButton
        onPressed: (mouse) => {
            if (globals.guidedControllerFlyView) {
                globals.guidedControllerFlyView.isPayloadWidgetClick = true
                resetTimer.restart()
            }
            mouse.accepted = false
        }
    }

    Timer {
        id:         resetTimer
        interval:   500
        repeat:     false
        onTriggered: {
            if (globals.guidedControllerFlyView) {
                globals.guidedControllerFlyView.isPayloadWidgetClick = false
            }
        }
    }
}
