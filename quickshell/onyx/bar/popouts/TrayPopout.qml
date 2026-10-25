pragma ComponentBehavior: Bound
// A tray client's DBus menu as onyx rows: separators as hairlines, checkable items with a
// state mark, submenus flattened one level. Clicking an entry triggers it and closes the popout.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.components

Column {
    id: root

    required property var host
    required property SystemTrayItem item

    width: 220
    spacing: 10

    QsMenuOpener {
        id: opener
        menu: root.item.menu
    }

    function markFor(e: var): string {
        if (e.buttonType === QsMenuButtonType.CheckBox)
            return e.checkState === Qt.Checked ? "✓" : "";
        if (e.buttonType === QsMenuButtonType.RadioButton)
            return e.checkState === Qt.Checked ? "●" : "○";
        return e.hasChildren ? "›" : "";
    }

    // title first ("Discord"), tooltip second, the raw item id only as a last resort
    readonly property string appName: root.item.title || root.item.tooltipTitle || (root.item.id || "tray").replace(/_status_icon.*$/, "").replace(/[_-]+/g, " ")

    PopoutHeader {
        label: root.appName.toLowerCase()
        value: root.item.tooltipTitle && root.item.tooltipTitle.toLowerCase() !== root.appName.toLowerCase() ? root.item.tooltipTitle : ""
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: opener.children

            Item {
                id: row
                required property var modelData
                width: parent.width
                height: modelData.isSeparator ? 9 : 30

                Hairline {
                    visible: row.modelData.isSeparator
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                }

                PopRow {
                    visible: !row.modelData.isSeparator
                    text: row.modelData.text.replace(/&/g, "")
                    trailing: root.markFor(row.modelData)
                    enabled: row.modelData.enabled
                    opacity: row.modelData.enabled ? 1 : 0.45
                    onClicked: {
                        if (row.modelData.hasChildren)
                            return;
                        row.modelData.triggered();
                        root.host.closePopout();
                    }
                }
            }
        }

        PopRow {
            visible: opener.children.values.length === 0
            text: "no menu"
            enabled: false
        }
    }

    PopCta {
        text: "click the icon to open " + root.appName
    }
}
