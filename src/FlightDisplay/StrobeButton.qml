/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QGroundControl
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools

QGCButton {
    id:         strobeButton
    text:       qsTr("Strobe")
    checkable:  true
    checked:    _strobeFact ? _strobeFact.value === 3 : false
    enabled:    _strobeFact !== null

    property var _strobeFact: globals.activeVehicle ? globals.activeVehicle.getParameterFact(-1, "UAVCAN_LGT_STROB", false) : null

    onClicked: {
        if (_strobeFact) {
            _strobeFact.value = checked ? 3 : 0
        }
    }
}
