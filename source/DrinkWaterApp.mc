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

    function initialize() {
        AppBase.initialize();
    }

    // These UI callbacks run only in the foreground; the app class also hosts the service entry.
    (:typecheck(disableBackgroundCheck))
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        reschedule();
        return [new WaterView(), new WaterDelegate()];
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
        WatchUi.requestUpdate();
    }
}
