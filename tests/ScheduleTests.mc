import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

(:test)
class ConfigProperties {
    var keys as Array<String> = ["schemaVersion", "enabled", "goalMl", "intervalMinutes",
        "startTime", "endTime", "day1", "day2", "day3", "day4", "day5", "day6", "day7", "servingMl"];
    var previous as Array<Properties.ValueType> = [];
    var previousIntake as Storage.ValueType = null;

    function initialize() {
        for (var i = 0; i < keys.size(); i += 1) {
            previous.add(Properties.getValue(keys[i]));
        }
        previousIntake = Storage.getValue("dailyIntake");
    }

    function reset() as Void {
        var values = [3, true, 2000, 60, 540, 1260,
            true, true, true, true, true, true, true, 100] as Array<Properties.ValueType>;
        for (var i = 0; i < keys.size(); i += 1) {
            Properties.setValue(keys[i], values[i]);
        }
        Storage.setValue("dailyIntake", null);
    }

    function restore() as Void {
        for (var i = 0; i < keys.size(); i += 1) {
            Properties.setValue(keys[i], previous[i]);
        }
        Storage.setValue("dailyIntake", previousIntake);
    }
}

(:test)
class LayoutDrawCounter extends WatchUi.Drawable {
    var count as Number = 0;

    static function buffer(height as Number) as Graphics.BufferedBitmap {
        return new Graphics.BufferedBitmap({
            :width => 240, :height => height
        });
    }

    function initialize(id as String) {
        Drawable.initialize({:identifier => id});
    }

    function draw(dc as Graphics.Dc) as Void {
        count += 1;
    }
}

(:test)
function verticalLayoutCentersVisibleRowsWithFixedSpacing(logger as Test.Logger) as Boolean {
    var dc = LayoutDrawCounter.buffer(240).getDc();
    var view = new LayoutView();
    view.setLayout(Rez.Layouts.ReminderLayout(dc));
    view.setVerticalLayout([], [["content"], ["remaining"]], [], 0, Theme.STACK_GAP);
    view.drawLayout(dc);
    var first = view.drawable("content") as StackText;
    var second = view.drawable("remaining") as StackText;
    var firstTop = first.locY - (first.measuredHeight / 2).toNumber();
    var secondTop = second.locY - (second.measuredHeight / 2).toNumber();
    Test.assertEqual(secondTop - firstTop - first.measuredHeight, Theme.STACK_GAP);
    var total = first.measuredHeight + Theme.STACK_GAP + second.measuredHeight;
    Test.assertEqual(firstTop, ((240 - total) / 2).toNumber());
    view.show("content", false);
    view.drawLayout(dc);
    Test.assertEqual(second.locY, 120);
    view.show("content", true);
    view.drawLayout(dc);
    Test.assertEqual(first.locY - (first.measuredHeight / 2).toNumber(), firstTop);
    return true;
}

(:test)
function verticalLayoutKeepsDigitsTogetherAndMeasuresWrappedText(logger as Test.Logger) as Boolean {
    var dc = LayoutDrawCounter.buffer(240).getDc();
    var view = new LayoutView();
    view.setEditorLayout(Rez.Layouts.TimeLayout(dc), dc,
        [["digit0", "digit1", "separator", "digit2", "digit3"], ["range"]]);
    view.drawLayout(dc);
    var digits = ["digit0", "digit1", "separator", "digit2", "digit3"];
    for (var i = 1; i < digits.size(); i += 1) {
        Test.assertEqual(view.drawable(digits[i]).locY, view.drawable(digits[0]).locY);
        Test.assert(view.drawable(digits[i]).locX > view.drawable(digits[i - 1]).locX);
    }
    var range = view.drawable("range") as StackText;
    range.setText("09:00 - 21:00");
    range.measure(dc, 200);
    var singleLineHeight = range.measuredHeight;
    range.measure(dc, 60);
    Test.assert(range.measuredHeight > singleLineHeight);
    Test.assert(range.measuredWidth <= 60);
    range.measure(dc, 200);
    Test.assertEqual(range.measuredHeight, singleLineHeight);
    return true;
}

(:test)
function xmlLayoutsRenderScreensAndKeepNextOutOfTheReminder(logger as Test.Logger) as Boolean {
    var buffer = LayoutDrawCounter.buffer(240);
    var dc = buffer.getDc();
    var main = new WaterView();
    main.onLayout(dc);
    main.onUpdate(dc);
    main.label("title").setText("Bebe Agua\nApp");
    main.drawLayout(dc);
    var title = main.drawable("title") as StackText;
    var goal = main.drawable("goal") as StackText;
    Test.assert(title.measuredHeight > Graphics.getFontHeight(Graphics.FONT_SMALL));
    Test.assert(goal.locY - (goal.measuredHeight / 2).toNumber() >=
        title.locY + (title.measuredHeight / 2).toNumber() + Theme.ROOT_STACK_GAP);
    Test.assert(main.findDrawableById("status") == null);
    Test.assert(main.findDrawableById("next") != null);
    Test.assert(main.findDrawableById("goal") != null);
    Test.assert(main.findDrawableById("consumed") != null);
    var reminder = new ReminderView();
    reminder.onLayout(dc);
    reminder.onUpdate(dc);
    Test.assert(reminder.findDrawableById("next") == null);
    Test.assert(reminder.findDrawableById("schedule") == null);
    Test.assert(reminder.findDrawableById("remaining") != null);
    var completed = new GoalReachedView();
    completed.onLayout(dc);
    completed.onUpdate(dc);
    Test.assert(completed._hidden.indexOf(completed.drawable("toggleHint")) >= 0);
    Test.assert(completed._hidden.indexOf(completed.drawable("menuHint")) >= 0);
    Test.assert(main._hidden.indexOf(main.drawable("toggleHint")) < 0);
    Test.assert(main._hidden.indexOf(main.drawable("menuHint")) < 0);
    var settings = new SettingsController(new SettingsMenu());
    var keys = ["goalMl", "intervalMinutes", "startTime", "endTime", "servingMl"];
    var values = [2000, 15, 570, 1260, 150];
    for (var i = 0; i < keys.size(); i += 1) {
        var controller = settings.createEditorController(keys[i], text(Rez.Strings.Settings), values[i]);
        var view = settings.createEditorView(controller);
        view.onLayout(dc);
        view.onUpdate(dc);
        if (i == 0) {
            Test.assert(view instanceof GoalView);
        } else if (i == 1) {
            Test.assert(view instanceof IntervalView);
        } else if (i == 4) {
            Test.assert(view instanceof ServingView);
        } else {
            Test.assert(view instanceof TimeView);
        }
    }
    return true;
}

(:test)
function completedGoalSelectsItsOwnScreenAndReturnsToMainWhenNoLongerReached(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    try {
        state.reset();
        app.visibleRoot = null;
        app.scheduleError = false;
        app.reminder = false;
        Properties.setValue("goalMl", 250);
        Properties.setValue("servingMl", 150);
        Test.assert(app.createRootView() instanceof WaterView);
        Test.assert(app.recordIntake());
        Test.assert(app.createRootView() instanceof WaterView);
        Test.assert(app.recordIntake());
        Test.assert(app.createRootView() instanceof GoalReachedView);
        app.reminder = true;
        Test.assert(app.createRootView() instanceof GoalReachedView);
        app.save("enabled", false);
        Test.assert(app.createRootView() instanceof GoalReachedView);
        app.save("goalMl", 350);
        Test.assert(app.createRootView() instanceof WaterView);
        app.save("goalMl", 250);
        Test.assert(app.createRootView() instanceof GoalReachedView);
        Storage.setValue("dailyIntake", {"day" => 19700101, "totalMl" => 300});
        Test.assert(app.createRootView() instanceof WaterView);
        var now = Time.now();
        Storage.setValue("dailyIntake", {
            "day" => Intake.dayKey(Gregorian.info(now, Time.FORMAT_SHORT)), "totalMl" => 300
        });
        Properties.setValue("servingMl", 125);
        Test.assert(app.createRootView() instanceof WaterView);
        Properties.setValue("servingMl", 150);
        app.scheduleError = true;
        Test.assert(app.createRootView() instanceof WaterView);
    } finally {
        state.restore();
        app.reschedule();
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}

(:test)
function sharedWaterFrameUpdatesWithoutScreenSpecificDrawables(logger as Test.Logger) as Boolean {
    var buffer = LayoutDrawCounter.buffer(240);
    var view = new LayoutView();
    WaterFrame.setLayout(view, [], buffer.getDc());
    var config = new WaterConfig();
    Test.assert(WaterFrame.update(view, config, false));
    config.error = text(Rez.Strings.UnsupportedVersion);
    Test.assert(!WaterFrame.update(view, config, false));
    view.drawLayout(buffer.getDc());
    Test.assert(!WaterFrame.update(view, config, true));
    view.drawLayout(buffer.getDc());
    config.error = null;
    Test.assert(WaterFrame.update(view, config, false));
    view.drawLayout(buffer.getDc());
    return true;
}

(:test)
function layoutVisibilitySkipsHiddenElementsAndResetsWithANewLayout(logger as Test.Logger) as Boolean {
    var buffer = LayoutDrawCounter.buffer(1);
    var view = new LayoutView();
    var first = new LayoutDrawCounter("first");
    var second = new LayoutDrawCounter("second");
    view.setLayout([first, second]);
    view.show("second", false);
    view.drawLayout(buffer.getDc());
    Test.assertEqual(first.count, 1);
    Test.assertEqual(second.count, 0);
    view.show("second", true);
    view.drawLayout(buffer.getDc());
    Test.assertEqual(second.count, 1);
    view.show("second", false);
    view.setLayout([second]);
    view.drawLayout(buffer.getDc());
    Test.assertEqual(second.count, 2);
    return true;
}

(:test)
function reminderUsesItsOwnViewAndSavingReturnsToTheMainView(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    var enabled = Properties.getValue("enabled");
    if (!(enabled instanceof Boolean)) {
        logger.error("El estado de los avisos no es booleano");
        return false;
    }
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    var previousLast = Storage.getValue("lastReminder");
    try {
        state.reset();
        app.visibleRoot = null;
        app.reminder = false;
        Test.assert(!(app.createRootView() instanceof ReminderView));
        Storage.setValue("lastReminder", null);
        app.onBackgroundData(100);
        Test.assert(app.createRootView() instanceof ReminderView);
        app.onBackgroundData(null);
        Test.assert(app.reminder);
        var last = Storage.getValue("lastReminder");
        Test.assert(last instanceof Number && last == 100);
        app.onBackgroundData(101);
        Test.assert(app.createRootView() instanceof ReminderView);
        app.onBackgroundData(101);
        Test.assert(!(app.createRootView() instanceof ReminderView));
        app.onBackgroundData(100);
        Test.assert(!app.reminder);
        app.onBackgroundData(102);
        app.save("enabled", enabled);
        Test.assert(!(app.createRootView() instanceof ReminderView));
    } finally {
        state.restore();
        Storage.setValue("lastReminder", previousLast);
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}

(:test)
function debugReminderTargetsNextMinuteAndRespectsMinimumSpacing(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var opened = new Time.Moment(1000000);
    var target = Schedule.debugEventTime(config, opened.add(new Time.Duration(1)), null, true);
    Test.assert(target != null);
    if (target != null) {
        Test.assertEqual(target.value(), 1000020);
    }
    target = Schedule.debugEventTime(config, opened.add(new Time.Duration(1)),
        new Time.Moment(opened.value() - 30), true);
    Test.assert(target != null);
    if (target != null) {
        Test.assertEqual(target.value(), opened.value() + 270);
    }
    target = Schedule.debugEventTime(config, new Time.Moment(1000020), null, true);
    Test.assert(target != null);
    if (target != null) {
        Test.assertEqual(target.value(), 1000020);
    }
    target = Schedule.debugEventTime(config, new Time.Moment(1000021), null, true);
    Test.assert(target != null);
    if (target != null) {
        Test.assertEqual(target.value(), 1000080);
    }
    Test.assert(Schedule.debugEventTime(config, opened, null, false) == null);
    config.enabled = false;
    Test.assert(Schedule.debugEventTime(config, opened, null, true) == null);
    config.enabled = true;
    config.error = text(Rez.Strings.InvalidSettings);
    Test.assert(Schedule.debugEventTime(config, opened, null, true) == null);
    return true;
}

(:test)
function debugReminderIgnoresScheduleButRejectsEarlyLateAndDisabledEvents(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var target = 1000060;
    var weekday = Gregorian.info(new Time.Moment(target), Time.FORMAT_SHORT).day_of_week as Number;
    config.days[Schedule.dayIndex(weekday)] = false;
    Test.assert(Schedule.dueKey(config, new Time.Moment(target)) == null);
    Test.assert(Schedule.debugDueKey(config, new Time.Moment(target - 1), target, true) == null);
    Test.assert(Schedule.debugDueKey(config, new Time.Moment(target), target, true) != null);
    Test.assert(Schedule.debugDueKey(config, new Time.Moment(target + 60), target, true) != null);
    Test.assert(Schedule.debugDueKey(config, new Time.Moment(target + 61), target, true) == null);
    Test.assert(Schedule.debugDueKey(config, new Time.Moment(target), target, false) == null);
    Test.assert(Schedule.debugDueKey(config, new Time.Moment(target), null, true) == null);
    config.enabled = false;
    Test.assert(Schedule.debugDueKey(config, new Time.Moment(target), target, true) == null);
    config.enabled = true;
    config.error = text(Rez.Strings.InvalidSettings);
    Test.assert(Schedule.debugDueKey(config, new Time.Moment(target), target, true) == null);
    return true;
}

(:test)
function debugRemindersRepeatAtTheEarliestLegalTime(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var first = new Time.Moment(1000020);
    var next = Schedule.debugEventTime(config, first.add(new Time.Duration(1)), first, true);
    Test.assert(next != null);
    if (next != null) {
        Test.assertEqual(next.value(), first.value() + 300);
        Test.assert(Schedule.debugDueKey(config, next, next.value(), true) != null);
        var delayed = next.add(new Time.Duration(37));
        var repeated = Schedule.debugEventTime(config, delayed.add(new Time.Duration(1)), delayed, true);
        Test.assert(repeated != null);
        if (repeated != null) {
            Test.assertEqual(repeated.value(), delayed.value() + 300);
        }
    }
    config.intakeDay = Intake.dayKey(Gregorian.info(first, Time.FORMAT_SHORT));
    config.consumedMl = 2000;
    Test.assert(Schedule.debugEventTime(config, first, first, true) == null);
    return true;
}

(:test)
function debugIntakeIsSeparateFromRealIntakeAndStillValidated(logger as Test.Logger) as Boolean {
    var previousReal = Storage.getValue("dailyIntake");
    var previousDebug = Storage.getValue("debugDailyIntake");
    var now = Time.now();
    var day = Intake.dayKey(Gregorian.info(now, Time.FORMAT_SHORT));
    try {
        Storage.setValue("dailyIntake", {"day" => day, "totalMl" => 500});
        Storage.setValue("debugDailyIntake", {"day" => day, "totalMl" => 1800});
        Test.assertEqual(Intake.readForMode(now, false).totalMl, 500);
        Test.assertEqual(Intake.readForMode(now, true).totalMl, 1800);
        Storage.setValue("debugDailyIntake", {"day" => day, "totalMl" => 2000});
        Test.assertEqual(Intake.readForMode(now, true).totalMl, 2000);
        Test.assertEqual(Intake.readForMode(now, false).totalMl, 500);
        Storage.setValue("debugDailyIntake", {"day" => day, "totalMl" => 1801});
        Test.assert(Intake.readForMode(now, true).error != null);
        Test.assert(Intake.readForMode(now, false).error == null);
    } finally {
        Storage.setValue("dailyIntake", previousReal);
        Storage.setValue("debugDailyIntake", previousDebug);
    }
    return true;
}

(:test)
function settingsMenusRefreshWithoutReadingNavigationAsProperty(logger as Test.Logger) as Boolean {
    var menu = new SettingsMenu();
    menu.refresh();
    var days = new DaysMenu();
    days.refresh();
    var names = [Rez.Strings.Monday, Rez.Strings.Tuesday, Rez.Strings.Wednesday,
                 Rez.Strings.Thursday, Rez.Strings.Friday, Rez.Strings.Saturday, Rez.Strings.Sunday];
    for (var i = 0; i < 7; i += 1) {
        var item = days.getItem(i);
        Test.assert(item != null);
        if (item != null) {
            var id = item.getId();
            var label = item.getLabel();
            Test.assert(id instanceof String && id.equals("day" + (i + 1).toString()));
            Test.assert(label instanceof String && label.equals(text(names[i])));
        }
    }
    return true;
}

(:test)
function startAndEndAreIncluded(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    Test.assert(Schedule.minuteOnDay(config, 2, 9 * 3600) == 540);
    Test.assert(Schedule.minuteOnDay(config, 2, 21 * 3600) == 1260);
    Test.assert(Schedule.minuteOnDay(config, 2, 21 * 3600 + 1) == null);
    return true;
}

(:test)
function cadenceDoesNotDrift(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    config.intervalMinutes = 17;
    Test.assert(Schedule.minuteOnDay(config, 2, 9 * 3600 + 1) == 557);
    Test.assert(Schedule.minuteOnDay(config, 2, 9 * 3600 + 17 * 60) == 557);
    Test.assert(Schedule.minuteOnDay(config, 2, 9 * 3600 + 17 * 60 + 1) == 574);
    config.endMinute = 600;
    Test.assert(Schedule.minuteOnDay(config, 2, 9 * 3600 + 51 * 60 + 1) == null);
    config.intervalMinutes = 15;
    Test.assert(config.validate() == null);
    Test.assert(Schedule.minuteOnDay(config, 2, 9 * 3600 + 1) == 555);
    return true;
}

(:test)
function invalidSettingsStopScheduling(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var goals = [49, 50, 10000, 10001];
    for (var i = 0; i < goals.size(); i += 1) {
        config.goalMl = goals[i];
        Test.assert((config.validate() == null) == (i == 1 || i == 2));
    }
    config.goalMl = 2000;
    var intervals = [14, 15, 60, 61];
    for (var i = 0; i < intervals.size(); i += 1) {
        config.intervalMinutes = intervals[i];
        Test.assert((config.validate() == null) == (i == 1 || i == 2));
    }
    config.intervalMinutes = 60;
    var windows = [[0, 1439], [-1, 1260], [540, 1440], [540, 540], [1260, 540]];
    for (var i = 0; i < windows.size(); i += 1) {
        config.startMinute = windows[i][0];
        config.endMinute = windows[i][1];
        Test.assert((config.validate() == null) == (i == 0));
    }
    config.startMinute = 0;
    config.endMinute = 1439;
    config.days = [false, false, false, false, false, false, false];
    config.error = config.validate();
    Test.assert(config.error != null);
    Test.assert(Schedule.minuteOnDay(config, 2, 0) == null);
    Test.assert(Schedule.next(config, Time.now()) == null);
    Test.assert(Schedule.dueKey(config, Time.now()) == null);
    Test.assert(Schedule.eventTime(config, Time.now(), null) == null);
    config.days[6] = true;
    config.error = null;
    Test.assert(config.validate() == null);
    return true;
}

(:test)
function nextSkipsToNextSelectedWeek(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    config.days = [true, false, false, false, false, false, false];
    var localClock = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 21, :minute => 1, :second => 0
    });
    var now = Schedule.momentFromLocalClock(localClock.value(), Time.now());
    if (now == null) {
        logger.error("No se pudo convertir la hora local");
        return false;
    }
    var nextTime = Schedule.next(config, now);
    if (nextTime == null) {
        logger.error("Falta el aviso de la siguiente semana");
        return false;
    }
    var info = Gregorian.info(nextTime, Time.FORMAT_SHORT);
    Test.assertEqual(info.day, 30);
    Test.assertEqual(info.hour, 9);
    Test.assertEqual(info.min, 0);
    config.enabled = false;
    Test.assert(Schedule.next(config, now) == null);
    return true;
}

(:test)
function mondayFirstDaysMatchCalendarForSchedulingAndDueReminders(logger as Test.Logger) as Boolean {
    for (var selected = 0; selected < 7; selected += 1) {
        var config = new WaterConfig();
        config.days = [false, false, false, false, false, false, false];
        config.days[selected] = true;
        for (var day = 0; day < 7; day += 1) {
            var localClock = Gregorian.moment({
                :year => 2026, :month => 11, :day => 23 + day, :hour => 9, :minute => 0, :second => 0
            });
            var now = Schedule.momentFromLocalClock(localClock.value(), Time.now());
            if (now == null) {
                logger.error("No se pudo convertir la hora local");
                return false;
            }
            var weekday = Gregorian.info(now, Time.FORMAT_SHORT).day_of_week as Number;
            Test.assert((Schedule.minuteOnDay(config, weekday, 9 * 3600) != null) == (day == selected));
            Test.assert((Schedule.dueKey(config, now) != null) == (day == selected));
            if (day == selected) {
                var nextTime = Schedule.next(config, now);
                Test.assert(nextTime != null);
                if (nextTime != null) {
                    Test.assertEqual(nextTime.value(), now.value());
                }
            }
        }
    }
    return true;
}

(:test)
function configReadsCurrentPropertiesWithoutMigratingSupportedSchemas(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    try {
        state.reset();
        Properties.setValue("enabled", false);
        Properties.setValue("goalMl", 750);
        Properties.setValue("intervalMinutes", 17);
        Properties.setValue("startTime", 570);
        Properties.setValue("endTime", 1170);
        var selected = [true, false, true, false, false, true, false] as Array<Boolean>;
        for (var day = 0; day < 7; day += 1) {
            Properties.setValue("day" + (day + 1).toString(), selected[day]);
        }
        for (var version = 1; version <= 3; version += 1) {
            Properties.setValue("schemaVersion", version);
            var config = Config.read();
            Test.assert(config.error == null);
            Test.assert(!config.enabled);
            Test.assertEqual(config.goalMl, 750);
            Test.assertEqual(config.intervalMinutes, 17);
            Test.assertEqual(config.startMinute, 570);
            Test.assertEqual(config.endMinute, 1170);
            Test.assertEqual(Properties.getValue("schemaVersion"), version);
            for (var day = 0; day < 7; day += 1) {
                Test.assertEqual(config.days[day], selected[day]);
                Test.assertEqual(Properties.getValue("day" + (day + 1).toString()), selected[day]);
            }
        }
    } finally {
        state.restore();
    }
    return true;
}

(:test)
function configRejectsUnsupportedSchemasAndWrongPropertyTypes(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    try {
        var versions = [0, 4, "3"] as Array<Properties.ValueType>;
        for (var i = 0; i < versions.size(); i += 1) {
            state.reset();
            Properties.setValue("schemaVersion", versions[i]);
            var error = Config.read().error;
            Test.assert(error != null && error.equals(text(Rez.Strings.UnsupportedVersion)));
        }
        for (var i = 1; i < state.keys.size(); i += 1) {
            state.reset();
            Properties.setValue(state.keys[i], "invalid");
            var config = Config.read();
            var error = config.error;
            Test.assert(error != null && error.equals(text(Rez.Strings.InvalidSettings)));
            Test.assert(Schedule.eventTime(config, Time.now(), null) == null);
            Test.assertEqual(Properties.getValue(state.keys[i]), "invalid");
        }
    } finally {
        state.restore();
    }
    return true;
}

(:test)
function configReportsInvalidStoredValuesWithoutReplacingThem(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    try {
        var keys = ["goalMl", "intervalMinutes", "startTime", "endTime"];
        var values = [10001, 14, -1, 1440];
        var errors = [Rez.Strings.InvalidGoal, Rez.Strings.InvalidInterval,
            Rez.Strings.InvalidHours, Rez.Strings.InvalidHours];
        for (var i = 0; i < keys.size(); i += 1) {
            state.reset();
            Properties.setValue(keys[i], values[i]);
            var error = Config.read().error;
            Test.assert(error != null && error.equals(text(errors[i])));
            Test.assertEqual(Properties.getValue(keys[i]), values[i]);
        }
        state.reset();
        for (var day = 1; day <= 7; day += 1) {
            Properties.setValue("day" + day.toString(), false);
        }
        var error = Config.read().error;
        Test.assert(error != null && error.equals(text(Rez.Strings.NoDays)));
        Properties.setValue("day7", true);
        Test.assert(Config.read().error == null);
    } finally {
        state.restore();
    }
    return true;
}

(:test)
function dueKeysStayStableWithinToleranceAndRejectEventsOutsideTheWindow(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var localClock = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 9, :minute => 0, :second => 0
    });
    var now = Schedule.momentFromLocalClock(localClock.value(), Time.now());
    if (now == null) {
        logger.error("No se pudo convertir la hora local");
        return false;
    }
    var key = Schedule.dueKey(config, now);
    Test.assert(key != null);
    Test.assert(Schedule.dueKey(config, new Time.Moment(now.value() - 1)) == null);
    Test.assert(Schedule.dueKey(config, now.add(new Time.Duration(60))) == key);
    Test.assert(Schedule.dueKey(config, now.add(new Time.Duration(61))) == null);
    var end = now.add(new Time.Duration(12 * 3600));
    var endKey = Schedule.dueKey(config, end);
    Test.assert(endKey != null);
    Test.assert(Schedule.dueKey(config, end.add(new Time.Duration(59))) == endKey);
    Test.assert(Schedule.dueKey(config, end.add(new Time.Duration(60))) == null);
    config.intervalMinutes = 17;
    config.endMinute = 600;
    Test.assert(Schedule.dueKey(config, now.add(new Time.Duration(51 * 60))) != null);
    Test.assert(Schedule.dueKey(config, now.add(new Time.Duration(60 * 60))) == null);
    config.enabled = false;
    Test.assert(Schedule.dueKey(config, now) == null);
    return true;
}

(:test)
function minimumSpacingDefersNearbyReminder(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    config.intervalMinutes = 15;
    var localClock = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 9, :minute => 10, :second => 1
    });
    var last = Schedule.momentFromLocalClock(localClock.value(), Time.now());
    if (last == null) {
        logger.error("No se pudo convertir la hora local");
        return false;
    }
    var event = Schedule.eventTime(config, last.add(new Time.Duration(1)), last);
    if (event == null) {
        logger.error("Se ha perdido el siguiente aviso");
        return false;
    }
    Test.assertEqual(event.value() - last.value(), 300);
    var info = Gregorian.info(event, Time.FORMAT_SHORT);
    Test.assertEqual(info.min, 15);
    Test.assertEqual(info.sec, 1);
    Test.assert(Schedule.dueKey(config, event) != null);
    return true;
}

(:test)
function minimumSpacingSkipsSlotsBeyondToleranceOrTheEndMinute(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    config.intervalMinutes = 15;
    var localClock = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 9, :minute => 15, :second => 0
    });
    var slot = Schedule.momentFromLocalClock(localClock.value(), Time.now());
    if (slot == null) {
        logger.error("No se pudo convertir la hora local");
        return false;
    }
    var delays = [60, 61];
    var expected = [60, 15 * 60];
    for (var i = 0; i < delays.size(); i += 1) {
        var last = new Time.Moment(slot.value() - 300 + delays[i]);
        var event = Schedule.eventTime(config, last.add(new Time.Duration(1)), last);
        Test.assert(event != null);
        if (event != null) {
            Test.assertEqual(event.value(), slot.value() + expected[i]);
            Test.assert(Schedule.dueKey(config, event) != null);
        }
    }
    config.endMinute = 555;
    var next = Schedule.respectMinimumSpacing(config, slot, slot.add(new Time.Duration(60)));
    Test.assert(next != null);
    if (next != null) {
        var info = Gregorian.info(next, Time.FORMAT_SHORT);
        Test.assertEqual(info.day, 24);
        Test.assertEqual(info.hour, 9);
        Test.assertEqual(info.min, 0);
    }
    return true;
}

(:test)
function nextReminderCrossesYearAndLeapDayBoundaries(logger as Test.Logger) as Boolean {
    var dates = [[2026, 12, 31, 2027, 1, 1], [2028, 2, 28, 2028, 2, 29]];
    var config = new WaterConfig();
    for (var i = 0; i < dates.size(); i += 1) {
        var date = dates[i];
        var localClock = Gregorian.moment({
            :year => date[0], :month => date[1], :day => date[2],
            :hour => 21, :minute => 1, :second => 0
        });
        var now = Schedule.momentFromLocalClock(localClock.value(), Time.now());
        if (now == null) {
            logger.error("No se pudo convertir la hora local");
            return false;
        }
        var next = Schedule.next(config, now);
        Test.assert(next != null);
        if (next != null) {
            var info = Gregorian.info(next, Time.FORMAT_SHORT);
            Test.assertEqual(info.year, date[3]);
            Test.assertEqual(info.month, date[4]);
            Test.assertEqual(info.day, date[5]);
            Test.assertEqual(info.hour, 9);
            Test.assertEqual(info.min, 0);
            Test.assert(next.value() > now.value());
        }
    }
    return true;
}

(:test)
function goalButtonsClampAtBothLimitsAndSavingPersistsTheDraft(logger as Test.Logger) as Boolean {
    var previous = Properties.getValue("goalMl");
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    try {
        app.visibleRoot = null;
        var goal = new GoalController(text(Rez.Strings.Goal), 50);
        Test.assert(goal.onNextPage());
        Test.assertEqual(goal.value, 50);
        Test.assert(goal.onPreviousPage());
        Test.assertEqual(goal.value, 100);
        goal = new GoalController(text(Rez.Strings.Goal), 10000);
        Test.assert(goal.onPreviousPage());
        Test.assertEqual(goal.value, 10000);
        Test.assert(goal.onNextPage());
        Test.assertEqual(goal.value, 9950);
        Test.assertEqual(Properties.getValue("goalMl"), previous);
        goal.save();
        Test.assertEqual(Properties.getValue("goalMl"), 9950);
    } finally {
        Properties.setValue("goalMl", previous);
        app.reschedule();
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}

(:test)
function togglesPersistAndRefreshMenusWithoutChangingOtherSettings(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    try {
        state.reset();
        app.visibleRoot = null;
        var root = new WaterController();
        Test.assert(root.onSelect());
        Test.assertEqual(Properties.getValue("enabled"), false);
        var settings = new SettingsMenu();
        var enabledItem = settings.getItem(settings.findItemById("enabled"));
        Test.assert(enabledItem != null);
        if (enabledItem != null) {
            new SettingsController(settings).onSelect(enabledItem);
            Test.assertEqual(Properties.getValue("enabled"), true);
            var label = enabledItem.getSubLabel();
            Test.assert(label instanceof String && label.equals(text(Rez.Strings.Enabled)));
        }
        var days = new DaysMenu();
        var monday = days.getItem(0);
        Test.assert(monday != null);
        if (monday != null) {
            new DaysController(days).onSelect(monday);
            Test.assertEqual(Properties.getValue("day1"), false);
            var label = monday.getSubLabel();
            Test.assert(label instanceof String && label.equals(text(Rez.Strings.Disabled)));
            new DaysController(days).onSelect(monday);
            Test.assertEqual(Properties.getValue("day1"), true);
        }
        Test.assertEqual(Properties.getValue("day2"), true);
        Test.assertEqual(Properties.getValue("goalMl"), 2000);
        Test.assertEqual(Properties.getValue("intervalMinutes"), 60);
        Test.assertEqual(Properties.getValue("startTime"), 540);
        Test.assertEqual(Properties.getValue("endTime"), 1260);
    } finally {
        state.restore();
        app.reschedule();
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}

(:test)
function intervalEditorConfirmsEachDigitOnTheSameView(logger as Test.Logger) as Boolean {
    var editor = new IntervalController(text(Rez.Strings.Interval), 60);
    for (var i = 0; i < 5; i += 1) {
        editor.change(-1);
    }
    Test.assertEqual(editor.value, 10);
    Test.assert(!editor.confirm());
    Test.assertEqual(editor.activeDigit, 1);
    for (var i = 0; i < 5; i += 1) {
        editor.change(1);
    }
    Test.assertEqual(editor.value, 15);
    Test.assert(editor.confirm());
    return true;
}

(:test)
function intervalEditorRejectsInvalidValuesAndAllowsCorrection(logger as Test.Logger) as Boolean {
    var editor = new IntervalController(text(Rez.Strings.Interval), 15);
    Test.assert(!editor.confirm());
    editor.change(-1);
    Test.assertEqual(editor.value, 14);
    Test.assert(!editor.confirm());
    Test.assert(editor.error != null);
    Test.assert(!editor.goBack());
    for (var i = 0; i < 5; i += 1) {
        editor.change(1);
    }
    Test.assert(!editor.confirm());
    for (var i = 0; i < 3; i += 1) {
        editor.change(-1);
    }
    Test.assertEqual(editor.value, 61);
    Test.assert(!editor.confirm());
    editor.change(-1);
    Test.assertEqual(editor.value, 60);
    Test.assert(editor.confirm());
    return true;
}

(:test)
function intervalEditorDoesNotPersistLegacyValuesOrCancelledDrafts(logger as Test.Logger) as Boolean {
    var previous = Properties.getValue("intervalMinutes");
    var editor = new IntervalController(text(Rez.Strings.Interval), 5);
    Test.assertEqual(editor.value, 15);
    Test.assert(editor.error != null);
    editor.change(-1);
    Test.assertEqual(editor.value, 5);
    Test.assert(editor.goBack());
    Test.assertEqual(Properties.getValue("intervalMinutes"), previous);
    return true;
}

(:test)
function timeEditorRestrictsHourDigitsAndResetsInvalidUnits(logger as Test.Logger) as Boolean {
    var editor = new TimeController("startTime", text(Rez.Strings.StartHour), 19 * 60 + 30);
    editor.change(1);
    Test.assertEqual(editor.value, 2030);
    Test.assert(!editor.confirm());
    editor.change(-1);
    Test.assertEqual(editor.value, 2330);
    editor.change(1);
    Test.assertEqual(editor.value, 2030);
    Test.assert(!editor.goBack());
    editor.change(1);
    Test.assertEqual(editor.value, 30);
    editor.change(-1);
    Test.assertEqual(editor.value, 2030);
    editor.change(-1);
    Test.assertEqual(editor.value, 1030);
    Test.assert(!editor.confirm());
    editor.change(-1);
    Test.assertEqual(editor.value, 1930);
    Test.assert(!editor.goBack());
    editor.change(1);
    Test.assertEqual(editor.value, 2030);
    Test.assert(!editor.confirm());
    Test.assert(!editor.confirm());
    Test.assert(!editor.confirm());
    Test.assert(editor.confirm());
    var midnight = new TimeController("endTime", text(Rez.Strings.EndHour), 0);
    for (var i = 0; i < 3; i += 1) {
        Test.assert(!midnight.confirm());
    }
    Test.assert(midnight.confirm());
    return true;
}

(:test)
function timeEditorWrapsMinutesWithinValidDigitRanges(logger as Test.Logger) as Boolean {
    var editor = new TimeController("endTime", text(Rez.Strings.EndHour), 1439);
    Test.assert(!editor.confirm());
    Test.assert(!editor.confirm());
    editor.change(1);
    Test.assertEqual(editor.value, 2309);
    Test.assert(!editor.confirm());
    editor.change(1);
    Test.assertEqual(editor.value, 2300);
    Test.assert(editor.confirm());
    Test.assert(!editor.goBack());
    editor.change(-1);
    Test.assert(!editor.confirm());
    editor.change(-1);
    Test.assertEqual(editor.value, 2359);
    Test.assert(editor.confirm());
    return true;
}

(:test)
function combinedTimesCancelWithoutChangingStoredValuesOrGoalEditor(logger as Test.Logger) as Boolean {
    var menu = new SettingsMenu();
    var delegate = new SettingsController(menu);
    var keys = ["startTime", "endTime"];
    for (var i = 0; i < keys.size(); i += 1) {
        var previous = Properties.getValue(keys[i]);
        if (!(previous instanceof Number)) {
            logger.error("El horario guardado no es numerico");
            return false;
        }
        var editor = delegate.createEditorController(keys[i], text(Rez.Strings.Settings), previous);
        Test.assert(editor instanceof TimeController);
        editor.change(1);
        for (var digit = 0; digit < 3; digit += 1) {
            Test.assert(!editor.confirm());
        }
        for (var digit = 0; digit < 3; digit += 1) {
            Test.assert(!editor.goBack());
        }
        Test.assert(editor.goBack());
        Test.assertEqual(Properties.getValue(keys[i]), previous);
    }
    var aboveRange = new TimeController("startTime", text(Rez.Strings.StartHour), 1440);
    Test.assertEqual(aboveRange.value, 2359);
    Test.assert(aboveRange.error != null);
    Test.assert(aboveRange.goBack());
    var belowRange = new TimeController("endTime", text(Rez.Strings.EndHour), -1);
    Test.assertEqual(belowRange.value, 0);
    Test.assert(belowRange.error != null);
    Test.assert(belowRange.goBack());
    var goal = delegate.createEditorController("goalMl", text(Rez.Strings.Goal), 2000);
    Test.assert(!(goal instanceof DigitController));
    goal.change(1);
    Test.assertEqual(goal.value, 2050);
    Test.assert(goal.confirm());
    return true;
}

(:test)
function timesSaveMinutesFromMidnightAndRefreshMenu(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    try {
        state.reset();
        app.visibleRoot = null;
        Properties.setValue("startTime", 570);
        Properties.setValue("endTime", 1305);
        var menu = new SettingsMenu();
        var delegate = new SettingsController(menu);
        var start = delegate.createEditorController("startTime", text(Rez.Strings.StartHour), 570);
        var end = delegate.createEditorController("endTime", text(Rez.Strings.EndHour), 1305);
        start.change(1);
        start.confirm();
        start.confirm();
        start.confirm();
        start.change(1);
        Test.assert(start.confirm());
        start.save();
        end.confirm();
        end.change(-1);
        end.confirm();
        end.confirm();
        end.change(1);
        Test.assert(end.confirm());
        end.save();
        menu.refresh();
        var startItem = menu.getItem(menu.findItemById("startTime"));
        var endItem = menu.getItem(menu.findItemById("endTime"));
        var startLabel = startItem != null ? startItem.getSubLabel() : null;
        var endLabel = endItem != null ? endItem.getSubLabel() : null;
        var config = Config.read();
        Test.assert(config.error == null);
        Test.assert(startLabel instanceof String && startLabel.equals("19:31"));
        Test.assert(endLabel instanceof String && endLabel.equals("20:46"));
        Test.assertEqual(Properties.getValue("startTime"), 19 * 60 + 31);
        Test.assertEqual(Properties.getValue("endTime"), 20 * 60 + 46);
        Test.assertEqual(config.startMinute, 19 * 60 + 31);
        Test.assertEqual(config.endMinute, 20 * 60 + 46);
    } finally {
        state.restore();
        app.reschedule();
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}

(:test)
function checkpointsRunOnlyWhenTheyLeaveFiveMinutesBeforeTheReminder(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var localClock = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 7, :minute => 55, :second => 0
    });
    var now = Schedule.momentFromLocalClock(localClock.value(), Time.now());
    if (now == null) {
        logger.error("No se pudo convertir la hora local");
        return false;
    }
    var checkpoint = Schedule.eventTime(config, now, null);
    var nearby = Schedule.eventTime(config, now.add(new Time.Duration(1)), null);
    var afterRecentEvent = Schedule.eventTime(config, now, now);
    Test.assert(checkpoint != null && nearby != null && afterRecentEvent != null);
    if (checkpoint != null && nearby != null && afterRecentEvent != null) {
        Test.assertEqual(checkpoint.value(), now.value() + 3600);
        Test.assert(Schedule.dueKey(config, checkpoint) == null);
        Test.assertEqual(nearby.value(), now.value() + 3900);
        Test.assertEqual(afterRecentEvent.value(), nearby.value());
        Test.assert(Schedule.dueKey(config, nearby) != null);
    }
    config.enabled = false;
    Test.assert(Schedule.eventTime(config, now, null) == null);
    return true;
}

(:test)
function servingEditorUsesOnlyFiftyMlStepsAndPersistsTheSelection(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    try {
        state.reset();
        app.visibleRoot = null;
        var settings = new SettingsController(new SettingsMenu());
        var editor = settings.createEditorController("servingMl", text(Rez.Strings.Serving), 100);
        Test.assert(editor instanceof ServingController);
        Test.assert(editor.onNextPage());
        Test.assertEqual(editor.value, 100);
        for (var expected = 150; expected <= 250; expected += 50) {
            Test.assert(editor.onPreviousPage());
            Test.assertEqual(editor.value, expected);
        }
        Test.assert(editor.onPreviousPage());
        Test.assertEqual(editor.value, 250);
        Test.assert(editor.onNextPage());
        Test.assertEqual(editor.value, 200);
        Test.assertEqual(Properties.getValue("servingMl"), 100);
        editor.save();
        Test.assertEqual(Config.read().servingMl, 200);
        var menu = new SettingsMenu();
        menu.refresh();
        var record = menu.getItem(menu.findItemById("recordIntake"));
        var amount = record != null ? record.getSubLabel() : null;
        Test.assert(amount instanceof String && amount.equals("200 ml"));
        var invalid = new ServingController(text(Rez.Strings.Serving), 125);
        Test.assert(invalid.error != null);
        invalid.change(1);
        Test.assertEqual(invalid.value, 150);
        Test.assert(invalid.confirm());
        Test.assertEqual(Properties.getValue("servingMl"), 200);
    } finally {
        state.restore();
        app.reschedule();
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}

(:test)
function servingValidationRejectsOutOfRangeAndIntermediateAmounts(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    try {
        state.reset();
        var amounts = [99, 100, 125, 150, 175, 200, 250, 251];
        var valid = [false, true, false, true, false, true, true, false];
        for (var i = 0; i < amounts.size(); i += 1) {
            Properties.setValue("servingMl", amounts[i]);
            var config = Config.read();
            Test.assert((config.error == null) == valid[i]);
            if (!valid[i]) {
                var error = config.error;
                Test.assert(error != null && error.equals(text(Rez.Strings.InvalidServing)));
                Test.assert(Schedule.eventTime(config, Time.now(), null) == null);
            }
            Test.assertEqual(Properties.getValue("servingMl"), amounts[i]);
        }
    } finally {
        state.restore();
    }
    return true;
}

(:test)
function dailyIntakePersistsAndResetsOnLocalCalendarBoundaries(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    try {
        state.reset();
        var dates = [[2026, 12, 31, 2027, 1, 1], [2028, 2, 28, 2028, 2, 29]];
        for (var i = 0; i < dates.size(); i += 1) {
            var date = dates[i];
            var eveningClock = Gregorian.moment({
                :year => date[0], :month => date[1], :day => date[2],
                :hour => 23, :minute => 59, :second => 59
            });
            var morningClock = Gregorian.moment({
                :year => date[3], :month => date[4], :day => date[5],
                :hour => 0, :minute => 0, :second => 0
            });
            var evening = Schedule.momentFromLocalClock(eveningClock.value(), Time.now());
            var morning = Schedule.momentFromLocalClock(morningClock.value(), Time.now());
            Test.assert(evening != null && morning != null);
            if (evening != null && morning != null) {
                var day = date[0] * 10000 + date[1] * 100 + date[2];
                Storage.setValue("dailyIntake", {"day" => day, "totalMl" => 2000});
                var first = Config.readAt(evening);
                var reopened = Config.readAt(evening);
                Test.assertEqual(first.consumedMl, 2000);
                Test.assertEqual(reopened.consumedMl, 2000);
                Test.assert(first.goalReached(evening));
                var nextDay = Config.readAt(morning);
                Test.assertEqual(nextDay.consumedMl, 0);
                Test.assert(!nextDay.goalReached(morning));
                Test.assert(nextDay.enabled);
            }
        }
    } finally {
        state.restore();
    }
    return true;
}

(:test)
function reachingOrExceedingGoalSkipsTodayButKeepsFutureReminders(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    config.goalMl = 500;
    var localClock = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 9, :minute => 0, :second => 0
    });
    var now = Schedule.momentFromLocalClock(localClock.value(), Time.now());
    Test.assert(now != null);
    if (now == null) {
        logger.error("No se pudo convertir la hora local");
        return false;
    }
    config.intakeDay = 20261123;
    config.consumedMl = 450;
    Test.assert(Schedule.dueKey(config, now) != null);
    var belowGoal = Schedule.next(config, now);
    Test.assert(belowGoal != null && belowGoal.value() == now.value());
    for (var total = 500; total <= 550; total += 50) {
        config.consumedMl = total;
        Test.assert(Schedule.dueKey(config, now) == null);
        Test.assert(Schedule.debugDueKey(config, now, now.value(), true) == null);
        Test.assert(Schedule.debugEventTime(config, now, null, true) == null);
        var next = Schedule.next(config, now);
        Test.assert(next != null);
        if (next != null) {
            var info = Gregorian.info(next, Time.FORMAT_SHORT);
            Test.assertEqual(info.day, 24);
            Test.assertEqual(info.hour, 9);
            Test.assertEqual(info.min, 0);
            Test.assert(Schedule.dueKey(config, next) != null);
            Test.assert(Schedule.debugEventTime(config, next, null, true) != null);
        }
        var event = Schedule.eventTime(config, now, null);
        Test.assert(event != null);
        if (event != null) {
            Test.assert(Schedule.dueKey(config, event) == null);
        }
    }
    config.goalMl = 600;
    Test.assert(Schedule.dueKey(config, now) != null);
    config.goalMl = 500;
    config.days = [true, false, false, false, false, false, false];
    var nextWeek = Schedule.next(config, now);
    Test.assert(nextWeek != null);
    if (nextWeek != null) {
        Test.assertEqual(Gregorian.info(nextWeek, Time.FORMAT_SHORT).day, 30);
    }
    config.enabled = false;
    Test.assert(Schedule.next(config, now) == null);
    if (nextWeek != null) {
        Test.assert(Schedule.dueKey(config, nextWeek) == null);
    }
    return true;
}

(:test)
function intakeMenuFlashesOnlySavedServingsAndClearsOnHide(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    var menu = new SettingsMenu();
    var controller = new SettingsController(menu);
    try {
        state.reset();
        app.visibleRoot = null;
        Properties.setValue("servingMl", 125);
        controller.onSelect(menu._record);
        Test.assert(!menu._record.intakeFeedback);
        Test.assertEqual(Intake.read(Time.now()).totalMl, 0);

        Properties.setValue("servingMl", 150);
        controller.onSelect(menu._record);
        Test.assert(menu._record.intakeFeedback);
        Test.assert(menu._header.intakeFeedback);
        Test.assertEqual(Config.read().consumedMl, 150);
        controller.onSelect(menu._record);
        Test.assert(!menu._record.intakeFeedback);
        Test.assertEqual(Config.read().consumedMl, 300);
        menu.onHide();
        menu.showIntakeFeedback();
        menu.finishIntakeFeedback();
        Test.assert(!menu._record.intakeFeedback);
        Test.assert(!menu._header.intakeFeedback);
        menu.flashIntake();
        menu.onHide();
        Test.assert(!menu._record.intakeFeedback);
        Test.assert(!menu._header.intakeFeedback);
    } finally {
        menu.onHide();
        state.restore();
        app.reschedule();
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}

(:test)
function recordingUsesSavedAmountAndIgnoresStaleWakeData(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    var previousLast = Storage.getValue("lastReminder");
    try {
        state.reset();
        app.visibleRoot = null;
        Properties.setValue("goalMl", 250);
        Properties.setValue("servingMl", 150);
        app.reminder = true;
        Test.assert(app.recordIntake());
        Test.assert(!app.reminder);
        Test.assertEqual(Config.read().consumedMl, 150);
        Test.assert(app.recordIntake());
        var now = Time.now();
        var completed = Config.readAt(now);
        Test.assertEqual(completed.consumedMl, 300);
        Test.assert(completed.goalReached(now));
        Test.assertEqual(Properties.getValue("enabled"), true);
        Storage.setValue("lastReminder", null);
        app.onBackgroundData(100);
        Test.assert(!app.reminder);
        Properties.setValue("servingMl", 125);
        Test.assert(!app.recordIntake());
        Test.assertEqual(Intake.read(now).totalMl, 300);
        Properties.setValue("servingMl", 250);
        Properties.setValue("enabled", false);
        Test.assert(app.recordIntake());
        Test.assertEqual(Config.read().consumedMl, 550);
        Test.assertEqual(Properties.getValue("enabled"), false);
        Storage.setValue("dailyIntake", {"day" => 19700101, "totalMl" => 2000});
        Test.assert(app.recordIntake());
        Test.assertEqual(Config.read().consumedMl, 250);
    } finally {
        state.restore();
        Storage.setValue("lastReminder", previousLast);
        app.reschedule();
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}

(:test)
function invalidIntakeStorageIsReportedAndNotOverwritten(logger as Test.Logger) as Boolean {
    var state = new ConfigProperties();
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousError = app.scheduleError;
    var previousRoot = app.visibleRoot;
    try {
        state.reset();
        app.visibleRoot = null;
        var now = Time.now();
        var day = Intake.dayKey(Gregorian.info(now, Time.FORMAT_SHORT));
        var invalid = ["invalid", {"day" => day, "totalMl" => -100},
            {"day" => day, "totalMl" => 125}, {"day" => "invalid", "totalMl" => 100}]
            as Array<Storage.ValueType>;
        for (var i = 0; i < invalid.size(); i += 1) {
            Storage.setValue("dailyIntake", invalid[i]);
            var config = Config.readAt(now);
            var error = config.error;
            Test.assert(error != null && error.equals(text(Rez.Strings.InvalidIntake)));
            Test.assert(Schedule.eventTime(config, now, null) == null);
            Test.assert(!app.recordIntake());
            var unchanged = Config.readAt(now).error;
            Test.assert(unchanged != null && unchanged.equals(text(Rez.Strings.InvalidIntake)));
        }
    } finally {
        state.restore();
        app.reschedule();
        app.reminder = previousReminder;
        app.scheduleError = previousError;
        app.visibleRoot = previousRoot;
    }
    return true;
}
