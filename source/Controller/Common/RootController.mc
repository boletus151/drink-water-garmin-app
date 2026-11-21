import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;

class RootController extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        var enabled = Properties.getValue("enabled");
        if (!(enabled instanceof Boolean)) {
            throw new Lang.UnexpectedTypeException("enabled must be Boolean", null, null);
        }
        waterApp().save("enabled", !enabled);
        return true;
    }

    function onMenu() as Boolean {
        return openSettings();
    }

    function onPreviousPage() as Boolean {
        return openSettings();
    }

    function openSettings() as Boolean {
        var menu = new SettingsMenu();
        WatchUi.pushView(menu, new SettingsController(menu), WatchUi.SLIDE_UP);
        return true;
    }
}
