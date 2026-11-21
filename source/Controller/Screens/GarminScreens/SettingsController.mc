import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsController extends WatchUi.Menu2InputDelegate {
    var _menu as SettingsMenu;

    function initialize(menu as SettingsMenu) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var key = item.getId();
        if (!(key instanceof String)) {
            throw new Lang.UnexpectedTypeException("Setting ID must be String", null, null);
        }
        if (key.equals("days")) {
            var menu = new DaysMenu();
            WatchUi.pushView(menu, new DaysController(menu), WatchUi.SLIDE_UP);
            return;
        }
        var value = Properties.getValue(key);
        if (value instanceof Boolean) {
            waterApp().save(key, !value);
            _menu.refresh();
        } else if (value instanceof Number) {
            var label = item.getLabel();
            var title = label instanceof String ? label : text(Rez.Strings.Settings);
            var controller = createEditorController(key, title, value);
            WatchUi.pushView(createEditorView(controller), controller, WatchUi.SLIDE_UP);
        } else {
            throw new Lang.UnexpectedTypeException("Unsupported setting value: " + key, null, null);
        }
    }

    function createEditorController(key as String, title as String, value as Number) as NumberController {
        if (key.equals("startTime") || key.equals("endTime")) {
            return new TimeController(key, title, value);
        }
        if (key.equals("intervalMinutes")) {
            return new IntervalController(title, value);
        }
        if (key.equals("goalMl")) {
            return new GoalController(title, value);
        }
        throw new Lang.UnexpectedTypeException("Unknown numeric setting: " + key, null, null);
    }

    function createEditorView(controller as NumberController) as LayoutView {
        if (controller instanceof TimeController) {
            return new TimeView(controller);
        }
        if (controller instanceof IntervalController) {
            return new IntervalView(controller);
        }
        if (controller instanceof GoalController) {
            return new GoalView(controller);
        }
        throw new Lang.UnexpectedTypeException("Unsupported editor controller: " + controller.key, null, null);
    }
}
