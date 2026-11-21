import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

(:background)
class DrinkWaterApp extends Application.AppBase {
    var reminder as Boolean = false;
    var scheduleError as Boolean = false;
    var visibleRoot as RootView? = null;

    function initialize() {
        AppBase.initialize();
    }

    // These UI callbacks run only in the foreground; the app class also hosts the service entry.
    (:typecheck(disableBackgroundCheck))
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var now = Time.now();
        var target = Schedule.debugEventTime(Config.read(), now,
            Background.getLastTemporalEventTime(), Config.DEBUG);
        Storage.setValue("debugReminderTime", target != null ? target.value() : null);
        if (target != null) {
            System.println("DrinkWater DEBUG: aviso en " + (target.value() - now.value()).toString() + " s");
        }
        reschedule();
        var view = createRootView();
        return [view, view.controller];
    }

    (:typecheck(disableBackgroundCheck))
    function createRootView() as RootView {
        return reminder ? new ReminderView() : new WaterView();
    }

    (:typecheck(disableBackgroundCheck))
    function refreshRootView() as Void {
        var view = visibleRoot;
        if (view != null && reminder != (view instanceof ReminderView)) {
            var nextView = createRootView();
            WatchUi.switchToView(nextView, nextView.controller, WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new WaterService()];
    }

    function onStop(state as Dictionary?) as Void {
        reschedule();
    }

    (:typecheck(disableBackgroundCheck))
    function onBackgroundData(data as Application.PersistableType) as Void {
        if (data instanceof Number) {
            var previous = Storage.getValue("lastReminder");
            reminder = !(previous instanceof Number) || data > previous;
            Storage.setValue("lastReminder", data);
            refreshRootView();
            WatchUi.requestUpdate();
        }
    }

    (:typecheck(disableBackgroundCheck))
    function onSettingsChanged() as Void {
        reschedule();
        WatchUi.requestUpdate();
    }

    function reschedule() as Void {
        scheduleError = false;
        try {
            Schedule.arm(Config.read(), Time.now().add(new Time.Duration(1)));
        } catch (ex instanceof Background.InvalidBackgroundTimeException) {
            System.println("DrinkWater: " + ex.getErrorMessage());
            Background.deleteTemporalEvent();
            scheduleError = true;
        }
    }

    (:typecheck(disableBackgroundCheck))
    function save(key as String, value as Properties.ValueType) as Void {
        Properties.setValue(key, value);
        reminder = false;
        reschedule();
        refreshRootView();
        WatchUi.requestUpdate();
    }

}
