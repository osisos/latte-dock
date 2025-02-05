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

import QtQuick 2.1
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.latte.core 0.2 as LatteCore
import org.kde.latte.private.containment 0.1 as LatteContainment

import "../debugger" as Debugger

Item{
    id: layoutsContainer
    //! WorkAround: Do not use "visible" because when it becomes "false" the contained applets can hide/show their elements.
    //! That approach can create a conflict with Latte Tasks that after showing the view they reshow windows
    //! that were already shown before hiding.
    //! visible: !(latteView && latteView.visibility.isHidden)
    opacity: !(latteView && latteView.visibility.isHidden) ? 1 : 0

    readonly property bool isHidden: root.inStartup || (latteView && latteView.visibility && latteView.visibility.isHidden)

    property int currentSpot: -1000

    readonly property alias startLayout : _startLayout
    readonly property alias mainLayout: _mainLayout
    readonly property alias endLayout: _endLayout

    signal contentsLengthChanged();

    Binding {
        target: layoutsContainer
        property: "x"
        when: !visibilityManager.inLocationAnimation
        value: {
            if (root.behaveAsPlasmaPanel) {
                return 0;
            }

            if ( latteView && root.isHorizontal && root.panelAlignment === LatteCore.Types.Justify ){
                return ((latteView.width/2) - (root.maxLength/2) + background.offset);
            } else {
                if ((visibilityManager.inSlidingIn || visibilityManager.inSlidingOut) && root.isVertical){
                    return;
                }

                if (layoutsContainer.isHidden && root.isVertical) {
                    if (LatteCore.WindowSystem.compositingActive) {
                        return visibilityManager.slidingOutToPos;
                    } else {
                        if ((plasmoid.location===PlasmaCore.Types.LeftEdge)||(plasmoid.location===PlasmaCore.Types.TopEdge)) {
                            return visibilityManager.slidingOutToPos + 1;
                        } else {
                            return visibilityManager.slidingOutToPos - 1;
                        }
                    }
                } else {
                    return 0;
                }
            }
        }
    }

    Binding{
        target: layoutsContainer
        property: "y"
        when: !visibilityManager.inLocationAnimation
        value: {
            if (root.behaveAsPlasmaPanel) {
                return 0;
            }

            if ( latteView && root.isVertical && root.panelAlignment === LatteCore.Types.Justify ) {
                return ((latteView.height/2) - (root.maxLength/2) + background.offset);
            } else {
                if ((visibilityManager.inSlidingIn || visibilityManager.inSlidingOut) && root.isHorizontal){
                    return;
                }

                if (layoutsContainer.isHidden && root.isHorizontal) {
                    if (LatteCore.WindowSystem.compositingActive) {
                        return visibilityManager.slidingOutToPos;
                    } else {
                        if ((plasmoid.location===PlasmaCore.Types.LeftEdge)||(plasmoid.location===PlasmaCore.Types.TopEdge)) {
                            return visibilityManager.slidingOutToPos + 1;
                        } else {
                            return visibilityManager.slidingOutToPos - 1;
                        }
                    }
                } else {
                    return 0;
                }
            }
        }
    }

    width: root.isHorizontal && root.panelAlignment === LatteCore.Types.Justify ? root.maxLength : parent.width
    height: root.isVertical && root.panelAlignment === LatteCore.Types.Justify ? root.maxLength : parent.height
    z:10

    property bool animationSent: false
    property bool shouldCheckHalfs: (plasmoid.configuration.alignment === LatteCore.Types.Justify) && (_mainLayout.children>1)

    property int contentsWidth: root.isHorizontal ? _startLayout.width + _mainLayout.width + _endLayout.width :
                                                    Math.max(_startLayout.width, _mainLayout.width ,_endLayout.width)
    property int contentsHeight: root.isVertical ? _startLayout.height + _mainLayout.height + _endLayout.height :
                                                   Math.max(_startLayout.height, _mainLayout.height, _endLayout.height)


    readonly property int backgroundShadowTailLength: {
        if (root.behaveAsPlasmaPanel) {
            return 0;
        }

        if (root.panelAlignment === LatteCore.Types.Left) {
            return background.shadows.left;
        } else if (root.panelAlignment === LatteCore.Types.Right) {
            return background.shadows.right;
        } else if (root.panelAlignment === LatteCore.Types.Top) {
            return background.shadows.top;
        } else if (root.panelAlignment === LatteCore.Types.Bottom) {
            return background.shadows.bottom;
        }

        //! centered case
        return root.isHorizontal ? background.shadows.left : background.shadows.top;
    }

    readonly property int backgroundShadowHeadLength: {
        if (root.behaveAsPlasmaPanel) {
            return 0;
        }

        if (root.panelAlignment === LatteCore.Types.Left) {
            return background.shadows.right;
        } else if (root.panelAlignment === LatteCore.Types.Right) {
            return background.shadows.left;
        } else if (root.panelAlignment === LatteCore.Types.Top) {
            return background.shadows.bottom;
        } else if (root.panelAlignment === LatteCore.Types.Bottom) {
            return background.shadows.top;
        }

        //! centered case
        return root.isHorizontal ? background.shadows.right : background.shadows.bottom;
    }

    readonly property int backgroundTailLength: {
        if (root.panelAlignment === LatteCore.Types.Left) {
            return backgroundShadowTailLength + background.paddings.left;
        } else if (root.panelAlignment === LatteCore.Types.Right) {
            return backgroundShadowTailLength + background.paddings.right;
        } else if (root.panelAlignment === LatteCore.Types.Top) {
            return backgroundShadowTailLength + background.paddings.top;
        } else if (root.panelAlignment === LatteCore.Types.Bottom) {
            return backgroundShadowTailLength + background.paddings.bottom;
        }

        //! centered case
        return root.isHorizontal ? background.paddings.left : background.paddings.top; //shadow is already calculated
    }

    readonly property int backgroundHeadLength: {
        if (root.panelAlignment === LatteCore.Types.Left) {
            return backgroundShadowHeadLength + background.paddings.right;
        } else if (root.panelAlignment === LatteCore.Types.Right) {
            return backgroundShadowHeadLength + background.paddings.left;
        } else if (root.panelAlignment === LatteCore.Types.Top) {
            return backgroundShadowHeadLength + background.paddings.bottom;
        } else if (root.panelAlignment === LatteCore.Types.Bottom) {
            return backgroundShadowHeadLength + background.paddings.top;
        }

        //! centered case
        return root.isHorizontal ? background.paddings.right : background.paddings.bottom; //shadow is already calculated
    }

    onContentsWidthChanged: {
        if (root.isHorizontal){
            var firstHalfExited = false;
            var secondHalfExited = false;

            if (shouldCheckHalfs){
                firstHalfExited = ( (_startLayout.width + _mainLayout.width/2) >= root.maxLength/2 );
                secondHalfExited = ( (_endLayout.width + _mainLayout.width/2) >= root.maxLength/2 );
            }

            if (latteView && ((contentsWidth >= root.maxLength) || firstHalfExited || secondHalfExited)) {
                autosize.updateIconSize();
            }

            if (!animationSent) {
                animationSent = true;
                animations.needLength.addEvent(layoutsContainer);
            }

            contentsLengthChanged();

            delayUpdateMaskArea.start();
        }
    }

    onContentsHeightChanged: {
        if (root.isVertical){
            var firstHalfExited = false;
            var secondHalfExited = false;

            if (shouldCheckHalfs){
                firstHalfExited = ( (_startLayout.height + _mainLayout.height/2) >= root.maxLength/2 );
                secondHalfExited = ( (_endLayout.height + _mainLayout.height/2) >= root.maxLength/2 );
            }

            if (latteView && ((contentsHeight >= root.maxLength) || firstHalfExited || secondHalfExited)) {
                autosize.updateIconSize();
            }

            if (!animationSent) {
                animationSent = true;
                animations.needLength.removeEvent(layoutsContainer);
            }

            contentsLengthChanged();

            delayUpdateMaskArea.start();
        }
    }

    onXChanged: root.updateEffectsArea();
    onYChanged: root.updateEffectsArea();

    EnvironmentActions {
        active: root.scrollAction !== LatteContainment.Types.ScrollNone || root.dragActiveWindowEnabled || root.closeActiveWindowEnabled
        alignment: _mainLayout.alignment
    }

    AppletsContainer {
        id: _startLayout
        beginIndex: 0
        offset: backgroundTailLength
        alignment: {
            switch(plasmoid.location) {
            case PlasmaCore.Types.BottomEdge: return LatteCore.Types.BottomEdgeLeftAlign;
            case PlasmaCore.Types.TopEdge: return LatteCore.Types.TopEdgeLeftAlign;
            case PlasmaCore.Types.LeftEdge: return LatteCore.Types.LeftEdgeTopAlign;
            case PlasmaCore.Types.RightEdge: return LatteCore.Types.RightEdgeTopAlign;
            }

            return LatteCore.Types.BottomEdgeLeftAlign;
        }
    }

    AppletsContainer {
        id: _mainLayout
        z:10 //be on top of start and end layouts
        beginIndex: 100
        offset: {
            if (!centered) {
                //! it is used for Top/Bottom/Left/Right alignments when they show both background length shadows
                return background.offset + backgroundTailLength;
            }

            return (root.panelAlignment === LatteCore.Types.Justify) ? 0 : background.offset
        }

        readonly property bool centered: (root.panelAlignment === LatteCore.Types.Center) || (root.panelAlignment === LatteCore.Types.Justify)
        readonly property bool reversed: Qt.application.layoutDirection === Qt.RightToLeft

        //! do not update during dragging/moving applets inConfigureAppletsMode
        readonly property bool offsetUpdateIsBlocked: ((root.dragOverlay && root.dragOverlay.pressed) || layouter.appletsInParentChange)
        property bool isCoveredFromBothSideLayouts: false

        alignment: {
            if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
                if (centered) return LatteCore.Types.LeftEdgeCenterAlign;
                if (root.panelAlignment === LatteCore.Types.Top) return LatteCore.Types.LeftEdgeTopAlign;
                if (root.panelAlignment === LatteCore.Types.Bottom) return LatteCore.Types.LeftEdgeBottomAlign;
            }

            if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                if (centered) return LatteCore.Types.RightEdgeCenterAlign;
                if (root.panelAlignment === LatteCore.Types.Top) return LatteCore.Types.RightEdgeTopAlign;
                if (root.panelAlignment === LatteCore.Types.Bottom) return LatteCore.Types.RightEdgeBottomAlign;
            }

            if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
                if (centered) return LatteCore.Types.BottomEdgeCenterAlign;

                if ((root.panelAlignment === LatteCore.Types.Left && !reversed)
                        || (root.panelAlignment === LatteCore.Types.Right && reversed)) {
                    return LatteCore.Types.BottomEdgeLeftAlign;
                }

                if ((root.panelAlignment === LatteCore.Types.Right && !reversed)
                        || (root.panelAlignment === LatteCore.Types.Left && reversed)) {
                    return LatteCore.Types.BottomEdgeRightAlign;
                }
            }

            if (plasmoid.location === PlasmaCore.Types.TopEdge) {
                if (centered) return LatteCore.Types.TopEdgeCenterAlign;

                if ((root.panelAlignment === LatteCore.Types.Left && !reversed)
                        || (root.panelAlignment === LatteCore.Types.Right && reversed)) {
                    return LatteCore.Types.TopEdgeLeftAlign;
                }

                if ((root.panelAlignment === LatteCore.Types.Right && !reversed)
                        || (root.panelAlignment === LatteCore.Types.Left && reversed)) {
                    return LatteCore.Types.TopEdgeRightAlign;
                }
            }

            return LatteCore.Types.BottomEdgeCenterAlign;
        }

        transitions: Transition {
            enabled: root.editMode
            AnchorAnimation {
                duration: 0.8 * animations.duration.proposed
                easing.type: Easing.OutCubic
            }
        }

        Binding{
            target: _mainLayout
            property:"isCoveredFromBothSideLayouts"
            when: !_mainLayout.offsetUpdateIsBlocked && layouter.inNormalFillCalculationsState
            value: {
                if (!layouter.mainLayout.onlyInternalSplitters && !_mainLayout.offsetUpdateIsBlocked) {
                    //! one of side layouts goes underneath the main layout when the main layout contains valid applets
                    var limit = (root.maxLength - mainLayout.length)/2;
                    return ((startLayout.length > limit ) && (endLayout.length > limit));
                }

                //! start and end layouts length exceed the maximum length
                return (startLayout.length + endLayout.length) > (root.maxLength);
            }
        }
    }

    AppletsContainer {
        id: _endLayout
        beginIndex: 200
        offset: backgroundHeadLength
        alignment: {
            switch(plasmoid.location) {
            case PlasmaCore.Types.BottomEdge: return LatteCore.Types.BottomEdgeRightAlign;
            case PlasmaCore.Types.TopEdge: return LatteCore.Types.TopEdgeRightAlign;
            case PlasmaCore.Types.LeftEdge: return LatteCore.Types.LeftEdgeBottomAlign;
            case PlasmaCore.Types.RightEdge: return LatteCore.Types.RightEdgeBottomAlign;
            }

            return LatteCore.Types.BottomEdgeLeftAlign;
        }
    }

    Connections {
        target: metrics
        onIconSizeAnimationEnded: delayUpdateMaskArea.start();
    }

    //! Debug Elements
    Loader{
        anchors.top: startLayout.top
        anchors.horizontalCenter: startLayout.horizontalCenter
        active: debug.layouterEnabled

        readonly property Item debugLayout: layouter.startLayout

        sourceComponent: Debugger.Tag{
            background.color: "white"
            label.text: tagText
            label.color: "black"
            label.font.pointSize: 13
            readonly property int layoutLength: root.isHorizontal ? debugLayout.grid.width : debugLayout.grid.height

            readonly property string tagText: {
                return "normal:" + debugLayout.shownApplets + " / fill:" + debugLayout.fillApplets + " / reg_len:" + debugLayout.sizeWithNoFillApplets + " / tot_len:"+layoutLength;
            }
        }
    }

    Loader{
        anchors.top: endLayout.top
        anchors.horizontalCenter: endLayout.horizontalCenter
        active: debug.layouterEnabled

        readonly property Item debugLayout: layouter.endLayout

        sourceComponent: Debugger.Tag{
            background.color: "white"
            label.text: tagText
            label.color: "black"
            label.font.pointSize: 13
            readonly property int layoutLength: root.isHorizontal ? debugLayout.grid.width : debugLayout.grid.height

            readonly property string tagText: {
                return "normal:" + debugLayout.shownApplets + " / fill:" + debugLayout.fillApplets + " / reg_len:" + debugLayout.sizeWithNoFillApplets + " / tot_len:"+layoutLength;
            }
        }
    }

    Loader{
        anchors.top: mainLayout.top
        anchors.horizontalCenter: mainLayout.horizontalCenter
        active: debug.layouterEnabled
        z:70

        readonly property Item debugLayout: layouter.mainLayout

        sourceComponent: Debugger.Tag{
            background.color: "white"
            label.text: tagText
            label.color: "black"
            label.font.pointSize: 13
            readonly property int layoutLength: root.isHorizontal ? debugLayout.grid.width : debugLayout.grid.height

            readonly property string tagText: {
                return "normal:" + debugLayout.shownApplets + " / fill:" + debugLayout.fillApplets + " / reg_len:" + debugLayout.sizeWithNoFillApplets + " / tot_len:"+layoutLength;
            }
        }
    }

    Loader{
        anchors.top: mainLayout.top
        anchors.left: parent.left
        active: debug.layouterEnabled

        readonly property Item debugLayout: layoutsContainer

        sourceComponent: Debugger.Tag{
            background.color: "blue"
            label.text: tagText
            label.color: "yellow"
            label.font.pointSize: 13
            label.font.bold: true
            readonly property int layoutLength: root.isHorizontal ? debugLayout.width : debugLayout.height

            readonly property int layoutsLength: {
                if (root.isVertical) {
                    return layouter.startLayout.grid.height + layouter.mainLayout.grid.height + layouter.endLayout.grid.height;
                }

                return layouter.startLayout.grid.width + layouter.mainLayout.grid.width + layouter.endLayout.grid.width;
            }

            readonly property string tagText: {
                return "MAX:" + root.maxLength + " / MIN: " + root.minLength + " TOT:"+layoutLength + " / LAYS:"+ layoutsLength;
            }
        }
    }

    //! This timer is needed in order to update mask area after ContentsWidth/Height and iconSize changes
    Timer{
        id:delayUpdateMaskArea
        repeat:false;
        interval:300;

        onTriggered: {
            if (layoutsContainer.animationSent) {
                animations.needLength.removeEvent(layoutsContainer);
                layoutsContainer.animationSent = false;
            }

            visibilityManager.updateMaskArea();

            if (debug.timersEnabled) {
                console.log("LayoutsContainer timer: delayUpdateMaskArea called...");
            }
        }
    }
}
