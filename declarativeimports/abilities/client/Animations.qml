/*
*  Copyright 2020 Michail Vourlakos <mvourlakos@gmail.com>
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

import QtQuick 2.7

import org.kde.latte.abilities.definition 0.1 as AbilityDefinition

AbilityDefinition.Animations {
    id: _animations
    property Item bridge: null
    readonly property bool bridgeIsActive: bridge !== null

    active: ref.animations.active
    readonly property bool hasThicknessAnimation: ref.animations.hasThicknessAnimation //redefined to make it readonly and switchable

    //! animations tracking
    needBothAxis: ref.animations.needBothAxis
    needLength: ref.animations.needLength
    needThickness: ref.animations.needThickness

    //! animations properties
    duration: ref.animations.duration
    speedFactor: ref.animations.speedFactor

    //! parabolic effect animations
    hoverPixelSensitivity: ref.animations.hoverPixelSensitivity

    //! requirements
    requirements: local.requirements

    readonly property AbilityDefinition.Animations local: AbilityDefinition.Animations{}

    Item {
        id: ref
        readonly property Item animations: bridge ? bridge.animations.host : local
    }

    //! Bridge - Client assignment
    onBridgeIsActiveChanged: {
        if (bridgeIsActive) {
            bridge.animations.client = _animations;
        }
    }

    Component.onCompleted: {
        if (bridgeIsActive) {
            bridge.animations.client = _animations;
        }
    }

    Component.onDestruction: {
        if (bridgeIsActive) {
            bridge.animations.client = null;
        }
    }
}
