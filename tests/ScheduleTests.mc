import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

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
function xmlLayoutsRenderScreensAndKeepNextOutOfTheReminder(logger as Test.Logger) as Boolean {
    var buffer = LayoutDrawCounter.buffer(240);
    var dc = buffer.getDc();
    var main = new WaterView();
    main.onLayout(dc);
    main.onUpdate(dc);
    Test.assert(main.findDrawableById("next") != null);
    var reminder = new ReminderView();
    reminder.onLayout(dc);
    reminder.onUpdate(dc);
    Test.assert(reminder.findDrawableById("next") == null);
    Test.assert(reminder.findDrawableById("schedule") == null);
    var goal = new GoalView(new GoalController(text(Rez.Strings.Goal), 2000));
    goal.onLayout(dc);
    goal.onUpdate(dc);
    var interval = new IntervalController(text(Rez.Strings.Interval), 15);
    var intervalView = new IntervalView(interval);
    intervalView.onLayout(dc);
    intervalView.onUpdate(dc);
    interval.confirm();
    interval.change(-1);
    Test.assert(!interval.confirm());
    intervalView.onUpdate(dc);
    interval.change(1);
    Test.assert(interval.confirm());
    intervalView.onUpdate(dc);
    var keys = ["startTime", "endTime"];
    for (var i = 0; i < keys.size(); i += 1) {
        var time = new TimeController(keys[i], text(Rez.Strings.Settings), 570);
        var timeView = new TimeView(time);
        timeView.onLayout(dc);
        for (var digit = 0; digit < 4; digit += 1) {
            timeView.onUpdate(dc);
            time.confirm();
        }
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
function xmlMenuVisualsRenderNavigationValuesAndResizedRows(logger as Test.Logger) as Boolean {
    var buffer = LayoutDrawCounter.buffer(62);
    var dc = buffer.getDc();
    var settingsTitle = new SettingsTitle(false);
    var daysTitle = new SettingsTitle(true);
    settingsTitle.draw(dc);
    daysTitle.draw(dc);
    var item = new SettingsItem(text(Rez.Strings.Days), null, "days");
    item.draw(dc);
    item.setSubLabel(text(Rez.Strings.Enabled));
    item.draw(dc);
    var focusedBuffer = LayoutDrawCounter.buffer(68);
    item.draw(focusedBuffer.getDc());
    item.setSubLabel(null);
    item.draw(dc);
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
function nativeLayoutsScaleTextAreasAndKeepHiddenZonesInPlace(logger as Test.Logger) as Boolean {
    var sizes = [[218, 218], [240, 240], [320, 320]];
    for (var i = 0; i < sizes.size(); i += 1) {
        var buffer = new Graphics.BufferedBitmap({:width => sizes[i][0], :height => sizes[i][1]});
        var dc = buffer.getDc();
        var view = new WaterView();
        view.onLayout(dc);
        view.onUpdate(dc);
        var next = view.label("next") as WatchUi.TextArea;
        var error = view.label("errorDetail") as WatchUi.TextArea;
        var hint = view.label("menuHint");
        var widthError = next.width - dc.getWidth() * 0.9;
        var heightError = error.height - dc.getHeight() * 0.24;
        Test.assert(widthError >= -1 && widthError <= 1);
        Test.assert(heightError >= -1 && heightError <= 1);
        Test.assert(view.label("content").locY < error.locY);
        Test.assert(error.locY + error.height <= hint.locY);
        var initialY = hint.locY;
        view.show("content", false);
        view.show("schedule", false);
        view.show("next", false);
        view.show("errorTitle", true);
        view.show("errorDetail", true);
        error.setText(text(Rez.Strings.UnsupportedVersion));
        view.drawLayout(dc);
        Test.assertEqual(hint.locY, initialY);
    }
    return true;
}

(:test)
function nativeDigitPositionsStayCenteredWhenEditing(logger as Test.Logger) as Boolean {
    var sizes = [218, 240, 320];
    for (var i = 0; i < sizes.size(); i += 1) {
        var buffer = new Graphics.BufferedBitmap({:width => sizes[i], :height => sizes[i]});
        var dc = buffer.getDc();
        var controller = new TimeController("endTime", text(Rez.Strings.EndHour), 570);
        var view = new TimeView(controller);
        view.onLayout(dc);
        view.onUpdate(dc);
        var first = view.label("digit0");
        var last = view.label("digit3");
        Test.assert(first instanceof WatchUi.Text);
        var rowCenterError = first.locX + last.locX - dc.getWidth();
        Test.assert(rowCenterError >= -2 && rowCenterError <= 2);
        var initialX = first.locX;
        var initialY = first.locY;
        var yError = initialY - dc.getHeight() * 0.4;
        Test.assert(yError >= -1 && yError <= 1);
        Test.assert(view.label("digit1").locX < view.label("separator").locX);
        Test.assert(view.label("separator").locX < view.label("digit2").locX);
        controller.change(1);
        controller.confirm();
        view.onUpdate(dc);
        Test.assertEqual(first.locX, initialX);
        Test.assertEqual(first.locY, initialY);
    }
    return true;
}

(:test)
function reminderUsesItsOwnViewAndSavingReturnsToTheMainView(logger as Test.Logger) as Boolean {
    var enabled = Properties.getValue("enabled");
    if (!(enabled instanceof Boolean)) {
        logger.error("El estado de los avisos no es booleano");
        return false;
    }
    var app = waterApp();
    var previousReminder = app.reminder;
    var previousLast = Storage.getValue("lastReminder");
    app.reminder = false;
    var main = app.createRootView();
    Storage.setValue("lastReminder", 100);
    app.onBackgroundData(101);
    var reminder = app.createRootView();
    app.onBackgroundData(101);
    var repeated = app.createRootView();
    app.onBackgroundData(102);
    app.save("enabled", enabled);
    var saved = app.createRootView();
    Storage.setValue("lastReminder", previousLast);
    app.reminder = previousReminder;
    app.refreshRootView();
    Test.assert(!(main instanceof ReminderView));
    Test.assert(reminder instanceof ReminderView);
    Test.assert(!(repeated instanceof ReminderView));
    Test.assert(!(saved instanceof ReminderView));
    return true;
}

(:test)
function debugReminderIsOneMinuteAfterOpeningAndRespectsMinimumSpacing(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var opened = new Time.Moment(1000000);
    var target = Schedule.debugEventTime(config, opened, null, true);
    Test.assert(target != null);
    if (target != null) {
        Test.assertEqual(target.value(), opened.value() + 60);
    }
    target = Schedule.debugEventTime(config, opened, new Time.Moment(opened.value() - 30), true);
    Test.assert(target != null);
    if (target != null) {
        Test.assertEqual(target.value(), opened.value() + 270);
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
function pendingDebugKeepsItsDeadlineAndExpiresWithoutRepeating(logger as Test.Logger) as Boolean {
    var previous = Storage.getValue("debugReminderTime");
    var config = new WaterConfig();
    Storage.setValue("debugReminderTime", 1000060);
    var first = Schedule.pendingDebug(config, new Time.Moment(1000001));
    var later = Schedule.pendingDebug(config, new Time.Moment(1000030));
    var expired = Schedule.pendingDebug(config, new Time.Moment(1000061));
    config.enabled = false;
    var disabled = Schedule.pendingDebug(config, new Time.Moment(1000001));
    Storage.setValue("debugReminderTime", previous);
    if (Config.DEBUG) {
        Test.assert(first != null && later != null);
        if (first != null && later != null) {
            Test.assertEqual(first.value(), 1000060);
            Test.assertEqual(later.value(), first.value());
        }
    } else {
        Test.assert(first == null && later == null);
    }
    Test.assert(expired == null && disabled == null);
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
function disabledAndExcludedDaysDoNotSchedule(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    config.days[0] = false;
    Test.assert(Schedule.minuteOnDay(config, 2, 0) == null);
    config.enabled = false;
    Test.assert(Schedule.minuteOnDay(config, 3, 0) == null);
    return true;
}

(:test)
function invalidSettingsStopScheduling(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    config.intervalMinutes = 14;
    config.error = config.validate();
    Test.assert(config.error != null);
    Test.assert(Schedule.minuteOnDay(config, 2, 0) == null);
    config.intervalMinutes = 61;
    Test.assert(config.validate() != null);
    config.intervalMinutes = 60;
    Test.assert(config.validate() == null);
    config.intervalMinutes = 15;
    config.startMinute = config.endMinute;
    Test.assert(config.validate() != null);
    config.startMinute = 540;
    config.days = [false, false, false, false, false, false, false];
    Test.assert(config.validate() != null);
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
function daysAreReadDirectlyWithoutMigratingStoredSelections(logger as Test.Logger) as Boolean {
    var previousVersion = Properties.getValue("schemaVersion");
    var previousDays = [] as Array<Properties.ValueType>;
    for (var i = 1; i <= 7; i += 1) {
        previousDays.add(Properties.getValue("day" + i.toString()));
    }
    var selected = [true, false, true, false, false, true, false] as Array<Boolean>;
    for (var day = 0; day < 7; day += 1) {
        Properties.setValue("day" + (day + 1).toString(), selected[day]);
    }
    var correct = true;
    for (var version = 1; version <= 3; version += 1) {
        Properties.setValue("schemaVersion", version);
        var config = Config.read();
        var storedVersion = Properties.getValue("schemaVersion");
        correct = correct && storedVersion instanceof Number && storedVersion == version;
        for (var day = 0; day < 7; day += 1) {
            var stored = Properties.getValue("day" + (day + 1).toString());
            correct = correct && config.days[day] == selected[day] &&
                stored instanceof Boolean && stored == selected[day];
        }
    }
    Properties.setValue("schemaVersion", 4);
    correct = correct && Config.read().error != null;
    Properties.setValue("schemaVersion", previousVersion);
    for (var i = 0; i < 7; i += 1) {
        Properties.setValue("day" + (i + 1).toString(), previousDays[i]);
    }
    Test.assert(correct);
    return true;
}

(:test)
function lateEventsDoNotReplayOldReminders(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var localClock = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 9, :minute => 0, :second => 30
    });
    var now = Schedule.momentFromLocalClock(localClock.value(), Time.now());
    if (now == null) {
        logger.error("No se pudo convertir la hora local");
        return false;
    }
    Test.assert(Schedule.dueKey(config, now) != null);
    Test.assert(Schedule.dueKey(config, now.add(new Time.Duration(31))) == null);
    var afterEnd = now.add(new Time.Duration(12 * 3600 + 60));
    Test.assert(Schedule.dueKey(config, afterEnd) == null);
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
    var keys = ["startTime", "endTime"];
    var previous = [] as Array<Properties.ValueType>;
    for (var i = 0; i < keys.size(); i += 1) {
        previous.add(Properties.getValue(keys[i]));
    }
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
    var startConfirmed = start.confirm();
    if (startConfirmed) {
        start.save();
    }
    end.confirm();
    end.change(-1);
    end.confirm();
    end.confirm();
    end.change(1);
    var endConfirmed = end.confirm();
    if (endConfirmed) {
        end.save();
    }
    menu.refresh();
    var startItem = menu.getItem(3);
    var endItem = menu.getItem(4);
    var daysItem = menu.getItem(5);
    var startLabel = startItem != null ? startItem.getSubLabel() : null;
    var endLabel = endItem != null ? endItem.getSubLabel() : null;
    var daysId = daysItem != null ? daysItem.getId() : null;
    var config = Config.read();
    var savedStart = Properties.getValue("startTime");
    var savedEnd = Properties.getValue("endTime");
    for (var i = 0; i < keys.size(); i += 1) {
        Properties.setValue(keys[i], previous[i]);
    }
    waterApp().reschedule();
    Test.assert(startConfirmed && endConfirmed);
    Test.assert(startLabel instanceof String && startLabel.equals("19:31"));
    Test.assert(endLabel instanceof String && endLabel.equals("20:46"));
    Test.assert(daysId instanceof String && daysId.equals("days"));
    Test.assertEqual(savedStart, 19 * 60 + 31);
    Test.assertEqual(savedEnd, 20 * 60 + 46);
    Test.assertEqual(config.startMinute, 19 * 60 + 31);
    Test.assertEqual(config.endMinute, 20 * 60 + 46);
    return true;
}

(:test)
function checkpointsDoNotDisplaceTheFirstReminder(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var localClock = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 7, :minute => 58, :second => 0
    });
    var now = Schedule.momentFromLocalClock(localClock.value(), Time.now());
    if (now == null) {
        logger.error("No se pudo convertir la hora local");
        return false;
    }
    var event = Schedule.eventTime(config, now, null);
    if (event == null) {
        logger.error("Falta el primer aviso");
        return false;
    }
    var info = Gregorian.info(event, Time.FORMAT_SHORT);
    Test.assertEqual(info.hour, 9);
    Test.assertEqual(info.min, 0);
    return true;
}
