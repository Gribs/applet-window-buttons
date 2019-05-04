/*
*  Copyright 2018 Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of applet-window-buttons
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.7
import QtQml.Models 2.2
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.taskmanager 0.1 as TaskManager

import org.kde.appletdecoration 0.1 as AppletDecoration

import "../code/tools.js" as ModelTools

Item {
    id: root
    clip: true

    Layout.fillHeight: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? true : false
    Layout.fillWidth: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? false : true

    Layout.minimumWidth: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? animatedMinimumWidth : -1
    Layout.minimumHeight: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? -1 : animatedMinimumHeight
    Layout.preferredHeight: Layout.minimumHeight
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumHeight: Layout.minimumHeight
    Layout.maximumWidth: Layout.minimumWidth

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.onFormFactorChanged: plasmoid.configuration.formFactor = plasmoid.formFactor;

    property int animatedMinimumWidth: minimumWidth
    property int animatedMinimumHeight: minimumHeight

    readonly property bool plasma515: AppletDecoration.Environment.plasmaDesktopVersion >= AppletDecoration.Environment.makeVersion(5,15,0)

    readonly property bool mustHide: {
        if (visibility === AppletDecoration.Types.ActiveWindow && !existsWindowActive) {
            return true;
        }
        if (visibility === AppletDecoration.Types.ActiveMaximizedWindow && !isActiveWindowMaximized) {
            return true;
        }

        return false;
    }
    readonly property int containmentType: plasmoid.configuration.containmentType
    readonly property int disabledMaximizedBorders: plasmoid.configuration.disabledMaximizedBorders
    readonly property int visibility: plasmoid.configuration.visibility

    readonly property int minimumWidth: {
        if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            if (mustHide && !plasmoid.userConfiguring && !latteInEditMode){
                return 0;
            }
        }

        return plasmoid.formFactor === PlasmaCore.Types.Horizontal ? buttonsArea.width : -1;
    }

    readonly property int minimumHeight: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            if (mustHide && !plasmoid.userConfiguring && !latteInEditMode){
                return 0;
            }
        }

        return plasmoid.formFactor === PlasmaCore.Types.Horizontal ? -1 : buttonsArea.height
    }

    readonly property string buttonsStr: plasmoid.configuration.buttons

    Plasmoid.status: {
        if (mustHide) {
            if ((plasmoid.formFactor === PlasmaCore.Types.Horizontal && animatedMinimumWidth === 0)
                    || (plasmoid.formFactor === PlasmaCore.Types.Vertical && animatedMinimumHeight === 0)) {
                return PlasmaCore.Types.HiddenStatus;
            }
        }

        return PlasmaCore.Types.ActiveStatus;
    }


    // START visual properties
    property int thickPadding: {
        if (auroraeThemeEngine.isEnabled && plasmoid.configuration.useDecorationMetrics) {
            return plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                        ((root.height - auroraeThemeEngine.buttonHeight) / 2) - 1 :
                        ((root.width - auroraeThemeEngine.buttonHeight) / 2) - 1;
        }

        return plasmoid.configuration.thicknessMargin;
    }

    property int lengthFirstMargin: plasmoid.configuration.lengthFirstMargin
    property int lengthLastMargin: plasmoid.configuration.lengthLastMargin

    property int lengthFirstPadding: Math.min(lengthFirstMargin, lengthMidPadding)
    property int lengthMidPadding: spacing / 2
    property int lengthLastPadding: Math.min(lengthLastMargin, lengthMidPadding)

    property int spacing: {
        if (auroraeThemeEngine.isEnabled && plasmoid.configuration.useDecorationMetrics) {
            return auroraeThemeEngine.buttonSpacing;
        }

        return plasmoid.configuration.spacing;
    }
    // END visual properties

    // START window properties

    //! make sure that on startup it will always be shown
    readonly property bool existsWindowActive: (activeTaskItem && tasksRepeater.count > 0 && activeTaskItem.isActive)
                                               || containmentIdentifierTimer.running
    readonly property bool isActiveWindowPinned: activeTaskItem && existsWindowActive && activeTaskItem.isOnAllDesktops
    readonly property bool isActiveWindowMaximized: activeTaskItem && existsWindowActive && activeTaskItem.isMaximized
    readonly property bool isActiveWindowKeepAbove: activeTaskItem && existsWindowActive && activeTaskItem.isKeepAbove

    property bool hasDesktopsButton: false
    property bool hasMaximizedButton: false
    property bool hasKeepAboveButton: false

    property Item activeTaskItem
    // END Window properties

    // START decoration properties
    property string currentPlugin: plasmoid.configuration.useCurrentDecoration ?
                                       decorations.currentPlugin : plasmoid.configuration.selectedPlugin
    property string currentTheme: plasmoid.configuration.useCurrentDecoration ?
                                      decorations.currentTheme : plasmoid.configuration.selectedTheme
    property string currentScheme: enforceLattePalette && plasmoid.configuration.selectedScheme === "kdeglobals"
                                   ? latteBridge.palette.scheme : plasmoid.configuration.selectedScheme
    // END decoration properties

    //BEGIN Latte Dock Communicator
    property QtObject latteBridge: null // current Latte v0.9 API

    onLatteBridgeChanged: {
        if (latteBridge) {
            plasmoid.configuration.containmentType = AppletDecoration.Types.Latte;
            latteBridge.actions.setProperty(plasmoid.id, "latteSideColoringEnabled", false);
        }
    }
    //END  Latte Dock Communicator
    //BEGIN Latte based properties
    //!   This applet is a special case and thus the latteBridge.applyPalette is not used.
    //!   the applet relys totally to Latte to paint itself correctly at all cases,
    //!   even when Latte informs the applets that need to use the default plasma theme.
    readonly property bool enforceLattePalette: latteBridge && latteBridge.palette
    readonly property bool latteInEditMode: latteBridge && latteBridge.inEditMode
    //END Latte based properties

    //START Behaviors
    Behavior on animatedMinimumWidth {
        enabled: plasmoid.configuration.slideAnimation && plasmoid.formFactor===PlasmaCore.Types.Horizontal
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }

    Behavior on animatedMinimumHeight {
        enabled: plasmoid.configuration.slideAnimation && plasmoid.formFactor===PlasmaCore.Types.Vertical
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }
    //END Behaviors

    onButtonsStrChanged: initButtons();

    onContainmentTypeChanged: {
        if (containmentType === AppletDecoration.Types.Plasma && disabledMaximizedBorders !== 1) { /*SystemDecision*/
            windowSystem.setDisabledMaximizedBorders(disabledMaximizedBorders);
        }
    }

    onDisabledMaximizedBordersChanged: {
        if (containmentType === AppletDecoration.Types.Plasma && disabledMaximizedBorders !== 1) { /*SystemDecision*/
            windowSystem.setDisabledMaximizedBorders(disabledMaximizedBorders);
        }
    }

    Connections{
        target: !auroraeThemeEngine.isEnabled ? root : null
        onThickPaddingChanged: initButtons();
    }

    Connections {
        target: bridgeItem
        onPluginChanged: initButtons();
    }

    Connections {
        target: buttonsRepeater
        onCountChanged: discoverButtons();
    }

    Component.onCompleted: {
        initButtons();
        containmentIdentifierTimer.start();
    }

    property var tasksPreparedArray: []

    ListModel {
        id: controlButtonsModel
    }

    // To get current activity name
    TaskManager.ActivityInfo {
        id: activityInfo
    }

    // To get virtual desktop name
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
        screenGeometry: plasmoid.screenGeometry
        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop

        filterByScreen: plasmoid.configuration.filterByScreen
        filterByVirtualDesktop: true
        filterByActivity: true
    }

    Repeater{
        id: tasksRepeater
        model:DelegateModel {
            model: tasksModel
            delegate: Item{
                id: task
                readonly property string title: display
                readonly property bool isMinimized: IsMinimized === true ? true : false
                readonly property bool isMaximized: IsMaximized === true ? true : false
                readonly property bool isActive: IsActive === true ? true : false
                readonly property bool isOnAllDesktops: IsOnAllVirtualDesktops === true ? true : false
                readonly property bool isKeepAbove: IsKeepAbove === true ? true : false

                onIsActiveChanged: {
                    if (isActive) {
                        root.activeTaskItem = task;
                    }
                }
            }
        }
    }

    ///Decoration Items
    AppletDecoration.Bridge {
        id: bridgeItem
        plugin: currentPlugin
        theme: currentTheme
    }

    AppletDecoration.Settings {
        id: settingsItem
        bridge: bridgeItem.bridge
        borderSizesIndex: 0 // Normal
    }

    AppletDecoration.DecorationsModel {
        id: decorations
    }

    AppletDecoration.AuroraeTheme {
        id: auroraeThemeEngine
        theme: isEnabled ? currentTheme : ""

        readonly property bool isEnabled: decorations.isAurorae(currentPlugin, currentTheme);
    }

    AppletDecoration.WindowSystem {
        id: windowSystem
    }

    ///functions
    function initButtons() {
        if (!buttonsRecreator.running){
            buttonsRecreator.start();
        }
    }

    function initializeControlButtonsModel() {
        console.log("recreating buttons");
        var buttonsList = buttonsStr.split('|');

        ModelTools.initializeControlButtonsModel(buttonsList, tasksPreparedArray, controlButtonsModel, true);
    }

    function discoverButtons() {
        var hasMax = false;
        var hasPin = false;
        var hasKeepAbove = false;

        for (var i=0; i<tasksPreparedArray.length; ++i) {
            if (tasksPreparedArray[i].buttonType === AppletDecoration.Types.Maximize) {
                hasMax = true;
            } else if (tasksPreparedArray[i].buttonType === AppletDecoration.Types.OnAllDesktops) {
                hasPin = true;
            } else if (tasksPreparedArray[i].buttonType === AppletDecoration.Types.KeepAbove) {
                hasKeepAbove = true;
            }
        }

        hasMaximizedButton = hasMax;
        hasDesktopsButton = hasPin;
        hasKeepAboveButton = hasKeepAbove;
    }

    function performActiveWindowAction(windowOperation) {
        if (windowOperation === AppletDecoration.Types.ActionClose) {
            toggleClose();
        } else if (windowOperation === AppletDecoration.Types.ToggleMaximize) {
            toggleMaximized();
        } else if (windowOperation === AppletDecoration.Types.ToggleMinimize) {
            toggleMinimized();
        } else if (windowOperation === AppletDecoration.Types.TogglePinToAllDesktops) {
            togglePinToAllDesktops();
        } else if (windowOperation === AppletDecoration.Types.ToggleKeepAbove){
            toggleKeepAbove();
        }
    }

    function toggleMaximized() {
        tasksModel.requestToggleMaximized(tasksModel.activeTask);
    }

    function toggleMinimized() {
        tasksModel.requestToggleMinimized(tasksModel.activeTask);
    }

    function toggleClose() {
        tasksModel.requestClose(tasksModel.activeTask);
    }

    function togglePinToAllDesktops() {
        if (root.plasma515) {
            tasksModel.requestVirtualDesktops(tasksModel.activeTask, 0);
        } else {
            tasksModel.requestVirtualDesktop(tasksModel.activeTask, 0);
        }
    }
    
    function toggleKeepAbove(){
        tasksModel.requestToggleKeepAbove(tasksModel.activeTask);
    }

    ///START Visual Items

    Grid {
        id: buttonsArea

        rowSpacing: 0
        columnSpacing: 0

        rows: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 1 : 0
        columns: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 0 : 1

        readonly property int buttonThickness: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                                                   root.height - 2 * thickPadding :
                                                   root.width - 2 * thickPadding

        Repeater {
            id: buttonsRepeater
            model: controlButtonsModel
            delegate: auroraeThemeEngine.isEnabled ? auroraeButton : pluginButton
        }
    }

    Component {
        id: pluginButton
        AppletDecoration.Button {
            id: cButton
            width: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                       buttonsArea.buttonThickness + padding.left + padding.right :
                       buttonsArea.buttonThickness + 2 * thickPadding

            height: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                        buttonsArea.buttonThickness + 2 * thickPadding :
                        buttonsArea.buttonThickness + padding.top + padding.bottom


            bridge: bridgeItem.bridge
            settings: settingsItem
            scheme: root.currentScheme
            type: buttonType
            isActive: {
                //!   FIXME: Disabled because it shows an error from c++ theme when its value is changed
                //!   and breaks in some cases the buttons coloring through the schemeFile
                //if (root.visibility === AppletDecoration.Types.AlwaysVisible && !root.existsWindowActive){
                //    return false;
                //}

                return true;
            }
            isOnAllDesktops: root.isActiveWindowPinned
            isMaximized: root.isActiveWindowMaximized
            isKeepAbove: root.isActiveWindowKeepAbove

            readonly property int firstPadding: {
                if (index === 0) {
                    //! first button
                    return lengthFirstMargin;
                } else {
                    return lengthMidPadding;
                }
            }

            readonly property int lastPadding: {
                if (index>=0 && index === buttonsRepeater.count - 1) {
                    //! last button
                    return lengthLastMargin;
                } else {
                    return lengthMidPadding;
                }
            }

            padding{
                left: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? firstPadding : thickPadding
                right: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? lastPadding : thickPadding
                top: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? thickPadding : firstPadding
                bottom: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? thickPadding : lastPadding
            }

            onClicked: {
                root.performActiveWindowAction(windowOperation);
            }

            /* Rectangle{
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: "red"
            }

            Rectangle{
                x: cButton.padding.left
                y: cButton.padding.top
                width: cButton.width - cButton.padding.left - cButton.padding.right
                height: cButton.height - cButton.padding.top - cButton.padding.bottom

                color: "transparent"
                border.width: 1
                border.color: "blue"
            } */
        }
    }

    Component {
        id: auroraeButton
        AppletDecoration.AuroraeButton {
            id: aButton
            width: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                       auroraeTheme.buttonRatio*buttonsArea.buttonThickness + leftPadding + rightPadding :
                       buttonsArea.buttonThickness + 2 * thickPadding

            height: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                        buttonsArea.buttonThickness + 2 * thickPadding :
                        buttonsArea.buttonThickness + topPadding + bottomPadding

            readonly property int firstPadding: {
                if (index === 0) {
                    //! first button
                    return lengthFirstMargin;
                } else {
                    return lengthMidPadding;
                }
            }

            readonly property int lastPadding: {
                if (index>=0 && index === buttonsRepeater.count - 1) {
                    //! last button
                    return lengthLastMargin;
                } else {
                    return lengthMidPadding;
                }
            }

            leftPadding: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? firstPadding : thickPadding
            rightPadding: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? lastPadding : thickPadding
            topPadding: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? thickPadding : firstPadding
            bottomPadding: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? thickPadding : lastPadding

            isActive: true
            isOnAllDesktops: root.isActiveWindowPinned
            isMaximized: root.isActiveWindowMaximized
            isKeepAbove: root.isActiveWindowKeepAbove
            buttonType: model.buttonType
            auroraeTheme: auroraeThemeEngine

            onClicked: {
                root.performActiveWindowAction(windowOperation);
            }

            /*  Rectangle{
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: "red"
            }

            Rectangle{
                x: aButton.leftPadding
                y: aButton.topPadding
                width: aButton.width - aButton.leftPadding - aButton.rightPadding
                height: aButton.height - aButton.topPadding - aButton.bottomPadding

                color: "transparent"
                border.width: 1
                border.color: "blue"
            } */
        }
    }
    ///END Visual Items

    //! this timer is used in order to not call too many times the recreation
    //! of buttons with no reason.
    Timer{
        id: buttonsRecreator
        interval: 200
        onTriggered: initializeControlButtonsModel();
    }

    //! this timer is used in order to identify in which containment the applet is in
    //! it should be called only the first time an applet is created and loaded because
    //! afterwards the applet has no way to move between different processes such
    //! as Plasma and Latte
    Timer{
        id: containmentIdentifierTimer
        interval: 5000
        onTriggered: {
            if (latteBridge) {
                plasmoid.configuration.containmentType = AppletDecoration.Types.Latte;
            } else {
                plasmoid.configuration.containmentType = AppletDecoration.Types.Plasma;
            }
        }
    }
}
