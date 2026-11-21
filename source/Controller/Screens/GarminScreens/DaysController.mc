import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;

class DaysController extends WatchUi.Menu2InputDelegate {
    var _menu as DaysMenu;

    function initialize(menu as DaysMenu) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var key = item.getId();
        if (!(key instanceof String)) {
            throw new Lang.UnexpectedTypeException("Day ID must be String", null, null);
        }
        var selected = Properties.getValue(key);
        if (!(selected instanceof Boolean)) {
            throw new Lang.UnexpectedTypeException("Day setting must be Boolean: " + key, null, null);
        }
        waterApp().save(key, !selected);
        _menu.refresh();
    }
}
