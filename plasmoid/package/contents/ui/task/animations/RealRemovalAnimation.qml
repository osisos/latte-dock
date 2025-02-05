/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
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

import QtQuick 2.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.latte.core 0.2 as LatteCore

SequentialAnimation {
    id: taskRealRemovalAnimation
    PropertyAction { target: taskItem; property: "ListView.delayRemove"; value: true }
    PropertyAction { target: taskItem; property: "inAnimation"; value: true }
    PropertyAction { target: taskItem; property: "inAddRemoveAnimation"; value: true }
    PropertyAction { target: taskItem; property: "inRemoveStage"; value: true }

    //Animation Add/Remove (1) - when is window with no launcher in current activity, animations enabled
    //Animation Add/Remove (4) - the user removes a launcher, animation enabled
    property bool animation1: ( (tasksModel.launcherPosition(taskItem.launcherUrl) === -1 /*no-launcher*/
                                 && tasksModel.launcherPosition(taskItem.launcherUrlWithIcon) === -1)
                               || ((!taskItem.launchers.inCurrentActivity(taskItem.launcherUrl)/*no-launcher-in-current-activity*/
                                    && !taskItem.launchers.inCurrentActivity(taskItem.launcherUrlWithIcon)))
                               && !taskItem.isStartup
                               && LatteCore.WindowSystem.compositingActive)

    property bool animation4: (tasksExtendedManager.launchersToBeRemovedCount /*update trigger*/
                               && (tasksExtendedManager.isLauncherToBeRemoved(taskItem.launcherUrl)
                                 || tasksExtendedManager.isLauncherToBeRemoved(taskItem.launcherUrlWithIcon))
                               && !taskItem.isStartup
                               && LatteCore.WindowSystem.compositingActive)

    property bool enabledAnimation: (animation1 || animation4)
                                    && (taskItem.animations.newWindowSlidingEnabled)
                                    && !taskItem.inBouncingAnimation
                                    && !taskItem.isSeparator
                                    && taskItem.visible

    readonly property string needLengthEvent: taskRealRemovalAnimation + "_realremoval"

    ScriptAction{
        script:{
            //! When a window is removed and afterwards its launcher must be shown immediately!
            if (!enabledAnimation && taskItem.isWindow && !taskItem.isSeparator
                    && (taskItem.launchers.inCurrentActivity(taskItem.launcherUrl)
                        || taskItem.launchers.inCurrentActivity(taskItem.launcherUrlWithIcon))
                    && !tasksExtendedManager.immediateLauncherExists(taskItem.launcherUrl)){
                tasksExtendedManager.addImmediateLauncher(taskItem.launcherUrl);
            }

            //trying to fix the ListView nasty behavior
            //during the removal the anchoring for ListView children changes a lot
            var previousTask = icList.childAtIndex(taskItem.lastValidIndex-1);

            //! When removing a task and there are surrounding separators then the hidden spacers
            //! are updated immediately for the neighbour tasks. In such case in order to not break
            //! the removal animation a small margin must applied
            var spacer = taskItem.headItemIsSeparator ? -(2+taskItem.metrics.totals.lengthEdge) : ( taskItem.headItemIsSeparator ? (2+taskItem.metrics.totals.lengthEdge)/2 : 0);

            if (!taskItem.inBouncingAnimation && !animation4) {
                //! real slide-out case
                var taskInListPos = mapToItem(icList, 0, 0);
                taskItem.parent = icList;

                if (root.vertical) {
                    taskItem.anchors.top = icList.top;
                    taskItem.anchors.topMargin = taskInListPos.y + spacer;

                    if (root.location===PlasmaCore.Types.LeftEdge) {
                        taskItem.anchors.left = icList.left;
                    } else {
                        taskItem.anchors.right = icList.right;
                    }
                } else {
                    taskItem.anchors.left = icList.left;
                    taskItem.anchors.leftMargin = taskInListPos.x + spacer;

                    if (root.location===PlasmaCore.Types.TopEdge) {
                        taskItem.anchors.top = icList.top;
                    } else {
                        taskItem.anchors.bottom = icList.bottom;
                    }
                }
            } else if (previousTask !== undefined && !previousTask.isStartup && !previousTask.inBouncingAnimation ) {
                // bouncing case
                if (root.vertical) {
                    taskItem.anchors.top = previousTask.bottom;
                    taskItem.anchors.topMargin = spacer;
                } else {
                    taskItem.anchors.left = previousTask.right;
                    taskItem.anchors.leftMargin = spacer;
                }
            }

            //console.log("1." + taskItem.launcherUrl + " - " + taskItem.launchers.inCurrentActivity(taskItem.launcherUrl) + "__" +
            //            animation1 + ":" + animation4 + "=>" + taskRealRemovalAnimation.enabledAnimation);
            //console.log("2." + taskItem.isLauncher);

            taskItem.animations.needLength.addEvent(needLengthEvent);

            if (wrapper.mScale > 1 && !taskRealRemovalAnimation.enabledAnimation
                    && !taskItem.inBouncingAnimation && LatteCore.WindowSystem.compositingActive) {
                tasksExtendedManager.setFrozenTask(taskItem.launcherUrl, wrapper.mScale);
            }
        }
    }

    //Ghost animation that acts as a delayer in case there is a bouncing animation
    //taking place
    PropertyAnimation {
        target: wrapper
        property: "opacity"
        to: 1

        //this duration must be a bit less than the bouncing animation. Otherwise the
        //smooth transition between removals is breaking
        duration:  taskItem.inBouncingAnimation  && !taskItem.isSeparator? 4*launcherSpeedStep + 50 : 0
        easing.type: Easing.InQuad

        property int launcherSpeedStep: 0.8 * taskItem.animations.speedFactor.current * taskItem.animations.duration.large
    }
    //end of ghost animation

    PropertyAnimation {
        target: wrapper
        property: "mScale"
        to: 1
        duration: taskRealRemovalAnimation.enabledAnimation ? showWindowAnimation.speed : 0
        easing.type: Easing.InQuad
    }

    //PropertyAction { target: wrapper; property: "opacity"; value: isWindow ? 0 : 1 }
    //animation mainly for launchers removal and startups
    ParallelAnimation{
        id: removalAnimation

        // property int speed: (IsStartup && !taskItem.visible)? 0 : 400
        //property int speed: 400
        NumberAnimation {
            target: wrapper;
            property: "opacity";
            to: 0;
            duration: taskRealRemovalAnimation.enabledAnimation ? 1.35*showWindowAnimation.speed : 0
            easing.type: Easing.InQuad
        }

        PropertyAnimation {
            target: wrapper
            property: (icList.orientation === Qt.Vertical) ? "tempScaleWidth" : "tempScaleHeight"
            to: 0
            duration: taskRealRemovalAnimation.enabledAnimation ? 1.35*showWindowAnimation.speed : 0
            easing.type: Easing.InQuad
        }
    }

    //smooth move into place the surrounding tasks
    PropertyAnimation {
        target: wrapper
        property: (icList.orientation === Qt.Vertical) ? "tempScaleHeight" : "tempScaleWidth"
        to: 0
        duration: taskRealRemovalAnimation.enabledAnimation ? 1.35*showWindowAnimation.speed : 0
        easing.type: Easing.InQuad
    }

    ScriptAction{
        script:{
            if (showWindowAnimation.animationSent){
                //console.log("SAFETY REMOVAL 1: animation removing ended");
                showWindowAnimation.animationSent = false;
                taskItem.animations.needLength.removeEvent(showWindowAnimation.needLengthEvent);
            }

            taskItem.animations.needLength.removeEvent(needLengthEvent);

            if(tasksExtendedManager.isLauncherToBeRemoved(taskItem.launcherUrl) && taskItem.isLauncher) {
                tasksExtendedManager.removeToBeRemovedLauncher(taskItem.launcherUrl);
            }

            if (windowsPreviewDlg.visible && windowsPreviewDlg.mainItem.parentTask === taskItem
                    && isWindow && !isGroupParent){
                hidePreview();
            }

            if (root.showWindowsOnlyFromLaunchers || root.disableAllWindowsFunctionality) {
                if (root.vertical) {
                    taskItem.anchors.top = undefined;
                    taskItem.anchors.topMargin = 0;
                } else {
                    taskItem.anchors.left = undefined;
                    taskItem.anchors.leftMargin = 0;
                }
            }

            taskItem.visible = false;

            //send signal that the launcher is really removing
            if (taskItem.inBouncingAnimation) {
                tasksExtendedManager.removeWaitingLauncher(taskItem.launcherUrl);
                taskItem.parabolic.setDirectRenderingEnabled(false);
            }
        }
    }

    PropertyAction { target: taskItem; property: "inAnimation"; value: false }
    PropertyAction { target: taskItem; property: "inAddRemoveAnimation"; value: false }
    PropertyAction { target: taskItem; property: "inRemoveStage"; value: false }

    PropertyAction { target: taskItem; property: "ListView.delayRemove"; value: false }
}
