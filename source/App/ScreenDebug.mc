import Toybox.Lang;
import Toybox.WatchUi;

module ScreenDebug {
    const ENABLED = DebugConfig.SCREEN_ENABLED;
    // water, reminder, goalReached, goal, serving, interval, startTime, endTime, settings, days
    const SCREEN = DebugConfig.SCREEN;

    (:debug)
    function initialView() as [WatchUi.Views, WatchUi.InputDelegates]? {
        if (!ENABLED) {
            return null;
        }
        if (SCREEN.equals("water")) {
            var water = new WaterView();
            return [water, water.controller];
        }
        if (SCREEN.equals("reminder")) {
            var reminder = new ReminderView();
            return [reminder, reminder.controller];
        }
        if (SCREEN.equals("goalReached")) {
            var completed = new GoalReachedView();
            return [completed, completed.controller];
        }
        if (SCREEN.equals("settings")) {
            var settings = new SettingsMenu();
            return [settings, new SettingsController(settings)];
        }
        if (SCREEN.equals("days")) {
            var days = new DaysMenu();
            return [days, new DaysController(days)];
        }

        var key = "";
        var title = Rez.Strings.Goal;
        if (SCREEN.equals("goal")) {
            key = "goalMl";
            title = Rez.Strings.Goal;
        } else if (SCREEN.equals("serving")) {
            key = "servingMl";
            title = Rez.Strings.Serving;
        } else if (SCREEN.equals("interval")) {
            key = "intervalMinutes";
            title = Rez.Strings.Interval;
        } else if (SCREEN.equals("startTime")) {
            key = "startTime";
            title = Rez.Strings.StartHour;
        } else if (SCREEN.equals("endTime")) {
            key = "endTime";
            title = Rez.Strings.EndHour;
        } else {
            throw new Lang.UnexpectedTypeException("Unknown debug screen: " + SCREEN, null, null);
        }
        var value = Config.settingValue(key);
        if (!(value instanceof Number)) {
            throw new Lang.UnexpectedTypeException("Debug setting must be Number: " + key, null, null);
        }
        var controller = SettingsController.createEditorController(key, text(title), value);
        return [SettingsController.createEditorView(controller), controller];
    }

    (:release)
    function initialView() as [WatchUi.Views, WatchUi.InputDelegates]? {
        return null;
    }
}
