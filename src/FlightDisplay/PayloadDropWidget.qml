/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.Vehicle

Rectangle {
    id:         root
    width:      column.width + (_margins * 2)
    height:     column.height + (_margins * 2)
    color:      Qt.rgba(0, 0, 0, 0.5)
    radius:     ScreenTools.defaultFontPixelHeight / 2
    border.color: "white"
    border.width: 1

    property bool _safetyOn:    true
    property bool _isDropping:  false
    property bool _pinRemoved:  false
    property real _margins:     ScreenTools.defaultFontPixelWidth

    on_SafetyOnChanged: {
        if (_safetyOn) {
            _pinRemoved = false
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        onActiveVehicleChanged: {
            _safetyOn = true
            _isDropping = false
            _pinRemoved = false
            dropHighlightTimer.stop()
        }
    }

    Timer {
        id:             dropHighlightTimer
        interval:       3000
        onTriggered:    _isDropping = false
    }

    Component {
        id: safetyConfirmationDialog
        QGCSimpleMessageDialog {
            title:      qsTr("Safety Switch")
            text:       qsTr("Are you sure?")
            buttons:    Dialog.Yes | Dialog.No
            onAccepted: _safetyOn = false
        }
    }

    Column {
        id:                 column
        anchors.centerIn:   parent
        spacing:            ScreenTools.defaultFontPixelHeight / 2
        
        // Payload Drop Label
        QGCLabel {
            text:               qsTr("Payload Drop")
            anchors.horizontalCenter: parent.horizontalCenter
            font.pointSize:     ScreenTools.smallFontPointSize
            font.bold:          true
            color:              "white"
        }

        // Safety Switch Rectangles
        Row {
            spacing: ScreenTools.defaultFontPixelWidth
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width:  ScreenTools.defaultFontPixelWidth * 6
                height: ScreenTools.defaultFontPixelHeight * 2
                color:  _safetyOn ? "green" : "#222"
                border.color: "white"
                border.width: _safetyOn ? 3 : 1
                radius: 4

                QGCLabel {
                    text:               qsTr("ON")
                    anchors.centerIn:   parent
                    color:              "white"
                    font.bold:          _safetyOn
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: if (!_isDropping) _safetyOn = true
                }
            }

            Rectangle {
                width:  ScreenTools.defaultFontPixelWidth * 6
                height: ScreenTools.defaultFontPixelHeight * 2
                color:  !_safetyOn ? "red" : "#222"
                border.color: "white"
                border.width: !_safetyOn ? 3 : 1
                radius: 4

                QGCLabel {
                    text:               qsTr("OFF")
                    anchors.centerIn:   parent
                    color:              "white"
                    font.bold:          !_safetyOn
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!_isDropping && _safetyOn) {
                            mainWindow.showMessageDialog(qsTr("Safety Switch for Dropping"), qsTr("Are you sure?"), Dialog.Yes | Dialog.No, function() { _safetyOn = false })
                        }
                    }
                }
            }
        }

        // Remove Pin Rectangle
        Rectangle {
            width:              (ScreenTools.defaultFontPixelWidth * 6 * 2) + ScreenTools.defaultFontPixelWidth
            height:             ScreenTools.defaultFontPixelHeight * 2
            color:              _pinRemoved ? "green" : (_safetyOn ? "#444" : "orange")
            border.color:       "white"
            border.width:       1
            radius:             4
            anchors.horizontalCenter: parent.horizontalCenter
            enabled:            !_safetyOn && !_isDropping
            opacity:            enabled ? 1.0 : 0.5

            QGCLabel {
                text:               qsTr("Remove Pin")
                anchors.centerIn:   parent
                color:              "white"
                font.bold:          true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var activeVehicle = QGroundControl.multiVehicleManager.activeVehicle
                    if (activeVehicle) {
                        mainWindow.showMessageDialog(qsTr("Remove Pin"), qsTr("Pin Removed"), Dialog.Ok, function() {
                            activeVehicle.removePin()
                            _pinRemoved = true
                        })
                    }
                }
            }
        }

        // DROP Circle
        Rectangle {
            id:             dropCircle
            width:          ScreenTools.defaultFontPixelHeight * 3.5
            height:         width
            radius:         width / 2
            // Highlight: Skyblue if dropping, Red if safety OFF and pin removed, Gray otherwise
            color:          _isDropping ? "skyblue" : ((!_safetyOn && _pinRemoved) ? "red" : "#444")
            // Border: White if safety OFF and pin removed or dropping, Red otherwise
            border.color:   ((!_safetyOn && _pinRemoved) || _isDropping) ? "white" : "red"
            border.width:   1
            opacity:        (!_safetyOn && _pinRemoved && !_isDropping) ? 1.0 : 0.5
            anchors.horizontalCenter: parent.horizontalCenter

            QGCLabel {
                text:               qsTr("DROP")
                anchors.centerIn:   parent
                font.bold:          true
                color:              "white"
                font.pointSize:     ScreenTools.defaultFontPointSize
            }

            MouseArea {
                anchors.fill: parent
                enabled:      !_safetyOn && !_isDropping && _pinRemoved
                onClicked: {
                    var activeVehicle = QGroundControl.multiVehicleManager.activeVehicle
                    if (activeVehicle) {
                        activeVehicle.payloadDrop()
                        _isDropping = true
                        _safetyOn = true // Turn safety back ON automatically
                        dropHighlightTimer.restart()
                        activeVehicle.showMessage(qsTr("Payload Dropped"))
                    }
                }
            }
        }
    }
}
