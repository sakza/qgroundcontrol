import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

QGCGroupBox {
    id:                     root
    Layout.fillWidth:       true
    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 35
    heading:                qsTr("Keyboard Flight Modes")
    headingDescription:     qsTr("Pair a key on a connected keyboard with a flight mode of the active vehicle.")

    property var    _bindingsFact:  QGroundControl.settingsManager.flightModeSettings.keyboardFlightModeBindings
    property var    _vehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property var    _bindings:      _parseBindings()
    property var    _flightModes:   _vehicle ? _vehicle.flightModes : []
    property int    _capturedKey:   0

    function _parseBindings() {
        try {
            var parsed = JSON.parse(_bindingsFact.rawValue)
            return Array.isArray(parsed) ? parsed : []
        } catch (e) {
            return []
        }
    }

    function _saveBindings(bindings) {
        _bindingsFact.rawValue = JSON.stringify(bindings)
    }

    function _isModifierKey(key) {
        return key === Qt.Key_Shift || key === Qt.Key_Control || key === Qt.Key_Alt || key === Qt.Key_Meta
    }

    function _addBinding() {
        var bindings = _bindings.filter(binding => binding.key !== _capturedKey)
        bindings.push({ "key": _capturedKey, "mode": modeCombo.currentText })
        _saveBindings(bindings)
        _capturedKey = 0
    }

    function _removeBinding(key) {
        _saveBindings(_bindings.filter(binding => binding.key !== key))
    }

    Shortcut {
        id:         capturedKeyName
        enabled:    false
        sequence:   root._capturedKey
    }

    Repeater {
        model: root._bindings

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth

            Shortcut {
                id:         boundKeyName
                enabled:    false
                sequence:   modelData.key
            }

            QGCLabel {
                Layout.fillWidth:   true
                text:               qsTr("%1: %2").arg(boundKeyName.nativeText).arg(modelData.mode)
            }

            QGCButton {
                text:       qsTr("Remove")
                onClicked:  root._removeBinding(modelData.key)
            }
        }
    }

    QGCLabel {
        visible:    root._bindings.length === 0
        text:       qsTr("No keys paired")
    }

    FocusScope {
        id:                 captureScope
        Layout.fillWidth:   true
        implicitHeight:     captureButton.implicitHeight

        Keys.onPressed: (event) => {
            if (!captureButton.capturing || root._isModifierKey(event.key)) {
                return
            }
            root._capturedKey = event.key | event.modifiers
            captureButton.capturing = false
            event.accepted = true
        }

        QGCButton {
            id:             captureButton
            anchors.fill:   parent
            text:           capturing ? qsTr("Press a key...") :
                                        (root._capturedKey ? qsTr("Key: %1").arg(capturedKeyName.nativeText) : qsTr("Capture key"))

            property bool capturing: false

            onClicked: {
                capturing = true
                captureScope.forceActiveFocus()
            }
        }
    }

    LabelledComboBox {
        id:                 modeCombo
        Layout.fillWidth:   true
        label:              qsTr("Flight Mode")
        model:              root._flightModes
        enabled:            root._flightModes.length > 0
    }

    QGCLabel {
        visible:    !root._vehicle
        text:       qsTr("Connect a vehicle to choose from its flight modes")
    }

    QGCButton {
        text:       qsTr("Pair Key")
        enabled:    root._capturedKey !== 0 && modeCombo.currentText !== ""
        onClicked:  root._addBinding()
    }
}
