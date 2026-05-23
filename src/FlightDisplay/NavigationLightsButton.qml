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
    id:                 navigationLightsButton
    Layout.fillWidth:   true
    text:               qsTr("Navigation Lights")
    checkable:          true
    
    // Styling: Blue when ON, Translucent (0.5 opacity) when OFF
    backgroundColor:    checked ? "blue" : "transparent"
    opacity:            checked ? 1.0 : 0.5
    textColor:          "white"

    onClicked: {
        if (globals.activeVehicle) {
            globals.activeVehicle.setNavigationLights(checked)
        }
    }
}
