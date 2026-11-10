// SPDX-License-Identifier: GPL-3.0-only
// Minimal page stack (Qt 5.6 safe, pure QtQuick).
//
// Replaces Controls 2 StackView for the push/pop/replace/clear/depth/
// currentItem/initialItem API used by the app (see js/util.js).
import QtQuick 2.6

Item {
    id: root

    property Item initialItem
    property Item currentItem
    property int depth: 0

    property var _stack: []

    function _attach(item) {
        var obj = (typeof item.createObject === "function")
                ? item.createObject(root) : item
        obj.parent = root
        obj.anchors.fill = root
        obj.visible = true
        return obj
    }

    function push(item) {
        if (currentItem)
            currentItem.visible = false
        var obj = _attach(item)
        _stack.push(obj)
        currentItem = obj
        depth = _stack.length
        return obj
    }

    function pop(item) {
        // No argument: pop a single level (back navigation).
        // Explicit null (see js/util.js): pop back to the initial item.
        if (item === undefined) {
            if (_stack.length > 1) {
                var obj = _stack.pop()
                obj.visible = false
            }
        } else {
            while (_stack.length > 1) {
                var popped = _stack.pop()
                popped.visible = false
            }
        }
        currentItem = _stack.length > 0 ? _stack[_stack.length - 1] : null
        if (currentItem)
            currentItem.visible = true
        depth = _stack.length
        return currentItem
    }

    function replace(item) {
        if (_stack.length > 0) {
            var old = _stack.pop()
            old.visible = false
        }
        return push(item)
    }

    function clear() {
        while (_stack.length > 0) {
            var obj = _stack.pop()
            obj.visible = false
        }
        currentItem = null
        depth = 0
    }

    Component.onCompleted: {
        if (initialItem)
            push(initialItem)
    }
}
