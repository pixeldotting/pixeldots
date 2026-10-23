import Quickshell

// Input-mask rectangle that follows a panel and collapses to nothing while the panel is hidden.
Region {
    required property Item panel

    x: panel.x
    y: panel.y
    width: panel.visible ? panel.width : 0
    height: panel.visible ? panel.height : 0
}
