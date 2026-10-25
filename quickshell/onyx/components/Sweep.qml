// The iridescent sweep used for the prompt name, fetch logo and Arch glyph, as a horizontal
// Rectangle gradient (ice blue → violet → pink → peach).
import QtQuick

Gradient {
    orientation: Gradient.Horizontal
    GradientStop {
        position: 0
        color: "#8cd4e2"
    }
    GradientStop {
        position: 0.35
        color: "#9b8ce2"
    }
    GradientStop {
        position: 0.7
        color: "#e28cd4"
    }
    GradientStop {
        position: 1
        color: "#e2c58c"
    }
}
