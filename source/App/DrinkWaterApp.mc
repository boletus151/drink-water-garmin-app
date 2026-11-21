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
        if (showGoalReached()) {
            return new GoalReachedView();
        }
        return reminder ? new ReminderView() : new WaterView();
    }

    (:typecheck(disableBackgroundCheck))
    function showGoalReached() as Boolean {
        var now = Time.now();
        var config = Config.readAt(now);
        return config.error == null && !scheduleError && config.goalReached(now);
    }

    (:typecheck(disableBackgroundCheck))
    function refreshRootView() as Boolean {
        var view = visibleRoot;
        if (view != null) {
            var completed = showGoalReached();
            var isCompleted = view instanceof GoalReachedView;
            var isReminder = view instanceof ReminderView;
            var isMain = view instanceof WaterView;
            var matches = completed ? isCompleted : reminder ? isReminder : isMain;
            if (!matches) {
                var nextView = createRootView();
                WatchUi.switchToView(nextView, nextView.controller, WatchUi.SLIDE_IMMEDIATE);
                return true;
            }
        }
        return false;
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
            var now = Time.now();
            var config = Config.readAt(now);
            reminder = (!(previous instanceof Number) || data > previous) &&
                config.enabled && config.error == null && !config.goalReached(now);
            Storage.setValue("lastReminder", data);
            refreshRootView();
            WatchUi.requestUpdate();
        }
    }

    (:typecheck(disableBackgroundCheck))
    function onSettingsChanged() as Void {
        reschedule();
        refreshRootView();
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

    (:typecheck(disableBackgroundCheck))
    function recordIntake() as Boolean {
        var now = Time.now();
        var config = Config.readAt(now);
        if (config.error != null) {
            System.println("DrinkWater: " + config.error);
            WatchUi.requestUpdate();
            return false;
        }
        Storage.setValue("dailyIntake", {
            "day" => Intake.dayKey(Toybox.Time.Gregorian.info(now, Time.FORMAT_SHORT)),
            "totalMl" => config.consumedMl + config.servingMl
        });
        reminder = false;
        reschedule();
        refreshRootView();
        WatchUi.requestUpdate();
        return true;
    }

}
