import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:test)
function settingsMenusRefreshWithoutReadingNavigationAsProperty(logger as Test.Logger) as Boolean {
    var menu = new SettingsMenu(false);
    menu.refresh();
    var days = new SettingsMenu(true);
    days.refresh();
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
    config.days[1] = false;
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
    config.days = [false, true, false, false, false, false, false];
    var civil = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 21, :minute => 1, :second => 0
    });
    var now = Schedule.localMoment(civil.value(), Time.now());
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
function lateEventsDoNotReplayOldReminders(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var civil = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 9, :minute => 0, :second => 30
    });
    var now = Schedule.localMoment(civil.value(), Time.now());
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
    var civil = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 9, :minute => 10, :second => 1
    });
    var last = Schedule.localMoment(civil.value(), Time.now());
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
    var editor = new IntervalView(text(Rez.Strings.Interval), 60);
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
    var editor = new IntervalView(text(Rez.Strings.Interval), 15);
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
    var editor = new IntervalView(text(Rez.Strings.Interval), 5);
    Test.assertEqual(editor.value, 15);
    Test.assert(editor.error != null);
    editor.change(-1);
    Test.assertEqual(editor.value, 5);
    Test.assert(editor.goBack());
    Test.assertEqual(Properties.getValue("intervalMinutes"), previous);
    return true;
}

(:test)
function checkpointsDoNotDisplaceTheFirstReminder(logger as Test.Logger) as Boolean {
    var config = new WaterConfig();
    var civil = Gregorian.moment({
        :year => 2026, :month => 11, :day => 23, :hour => 7, :minute => 58, :second => 0
    });
    var now = Schedule.localMoment(civil.value(), Time.now());
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
