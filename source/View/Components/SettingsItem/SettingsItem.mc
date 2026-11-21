import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsItem extends WatchUi.CustomMenuItem {
    var _view as LayoutView;
    var intakeFeedback as Boolean = false;

    function initialize(label as String, subLabel as String?, key as String) {
        CustomMenuItem.initialize(key, {});
        setLabel(label);
        setSubLabel(subLabel);
        _view = new LayoutView();
    }

    function draw(dc as Graphics.Dc) as Void {
        var label = getLabel();
        var subLabel = getSubLabel();
        if (_view.updateLayoutSize(dc)) {
            _view.setLayout(Rez.Layouts.MenuItemLayout(dc));
            _view.setVerticalLayout([], [["label"], ["subLabel"], ["navigation"]], [], Theme.MENU_PADDING);
        }
        var hasSubLabel = subLabel != null;
        _view.show("background", !intakeFeedback);
        _view.show("focus", isFocused() && !intakeFeedback);
        if (intakeFeedback) {
            dc.setColor(Theme.INTAKE_FEEDBACK, Theme.INTAKE_FEEDBACK);
            dc.clear();
        }
        _view.show("label", hasSubLabel && label instanceof String);
        _view.show("navigation", !hasSubLabel && label instanceof String);
        _view.show("subLabel", subLabel instanceof String);
        if (label instanceof String) {
            _view.label("label").setText(label);
            _view.label("navigation").setText(label);
        }
        if (subLabel instanceof String) {
            _view.label("subLabel").setText(subLabel);
            _view.label("subLabel").setColor(isFocused() ? Theme.ACCENT : Theme.MUTED);
        }
        _view.drawLayout(dc);
    }
}
