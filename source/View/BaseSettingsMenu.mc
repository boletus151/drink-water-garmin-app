import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BaseSettingsMenu extends WatchUi.CustomMenu {
    var _count as Number = 0;

    function initialize(daysOnly as Boolean) {
        var itemHeight = Graphics.getFontHeight(Graphics.FONT_XTINY) * 2 +
            Theme.STACK_GAP + Theme.MENU_PADDING * 2;
        CustomMenu.initialize(itemHeight, Theme.BACKGROUND, {
            :focusItemHeight => itemHeight + Theme.MENU_FOCUS_PADDING * 2,
            :title => new SettingsTitle(daysOnly)
        });
    }

    function addSetting(key as String, title as ResourceId) as Void {
        addItem(new SettingsItem(text(title), valueText(key), key));
    }

    function valueText(key as String) as String {
        var value = Properties.getValue(key);
        if (key.equals("startTime") || key.equals("endTime")) {
            if (!(value instanceof Number)) {
                throw new Lang.UnexpectedTypeException("Time settings must be Number", null, null);
            }
            return clockText(value);
        }
        if (value instanceof Boolean) {
            return text(value ? Rez.Strings.Enabled : Rez.Strings.Disabled);
        }
        return value.toString();
    }

    function refresh() as Void {
        for (var i = 0; i < _count; i += 1) {
            var item = getItem(i);
            if (item != null) {
                var key = item.getId();
                if (key instanceof String && !key.equals("days")) {
                    item.setSubLabel(valueText(key));
                }
            }
        }
    }

    function onShow() as Void {
        refresh();
    }
}
