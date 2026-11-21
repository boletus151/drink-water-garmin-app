import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsList {
    var _keys as Array<String> = [];

    function initialize() {
    }

    static function itemHeight() as Number {
        return Graphics.getFontHeight(Graphics.FONT_XTINY) * 2 +
            Theme.STACK_GAP + Theme.MENU_PADDING * 2;
    }

    function addSetting(menu as WatchUi.CustomMenu, key as String, title as ResourceId) as Void {
        menu.addItem(new SettingsItem(text(title), valueText(key), key));
        _keys.add(key);
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

    function refresh(menu as WatchUi.CustomMenu) as Void {
        for (var i = 0; i < _keys.size(); i += 1) {
            var item = menu.getItem(menu.findItemById(_keys[i]));
            if (item != null) {
                item.setSubLabel(valueText(_keys[i]));
            }
        }
    }
}
