import Toybox.Background;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:background)
module Schedule {
    const MINIMUM_SECONDS = 300;
    const MAX_DELAY_SECONDS = 60;
    const CHECKPOINT_SECONDS = 3600;

    function earliestAllowedTime(earliest as Time.Moment, lastEvent as Time.Moment?) as Time.Moment {
        if (lastEvent != null && earliest.value() < lastEvent.value() + MINIMUM_SECONDS) {
            return lastEvent.add(new Time.Duration(MINIMUM_SECONDS));
        }
        return earliest;
    }

    function debugEventTime(config as WaterConfig, opened as Time.Moment,
                            lastEvent as Time.Moment?, debug as Boolean) as Time.Moment? {
        if (!debug || !config.enabled || config.error != null) {
            return null;
        }
        return earliestAllowedTime(opened.add(new Time.Duration(60)), lastEvent);
    }

    function debugDueKey(config as WaterConfig, now as Time.Moment,
                         target as Number?, debug as Boolean) as Number? {
        if (!debug || !config.enabled || config.error != null || target == null ||
            now.value() < target || now.value() - target > MAX_DELAY_SECONDS) {
            return null;
        }
        return localClockSeconds(Gregorian.info(now, Time.FORMAT_SHORT));
    }

    function pendingDebug(config as WaterConfig, earliest as Time.Moment) as Time.Moment? {
        if (!Config.DEBUG || !config.enabled || config.error != null) {
            return null;
        }
        var target = Storage.getValue("debugReminderTime");
        return target instanceof Number && target >= earliest.value() ? new Time.Moment(target) : null;
    }

    // Gregorian numbers Sunday as 1; settings run from Monday to Sunday.
    function dayIndex(weekday as Number) as Number {
        return (weekday + 5) % 7;
    }

    function minuteOnDay(config as WaterConfig, weekday as Number,
                         seconds as Number) as Number? {
        if (!config.enabled || config.error != null || !config.days[dayIndex(weekday)]) {
            return null;
        }
        var start = config.startMinute * 60;
        var step = config.intervalMinutes * 60;
        var slot = config.startMinute;
        if (seconds > start) {
            slot += ((seconds - start + step - 1) / step).toNumber() * config.intervalMinutes;
        }
        return slot <= config.endMinute ? slot : null;
    }

    // Encode local calendar fields as UTC for arithmetic; this is not a real timestamp.
    function localClockSeconds(info as Gregorian.Info) as Number {
        return Gregorian.moment({
            :year => info.year, :month => info.month as Number, :day => info.day,
            :hour => info.hour, :minute => info.min, :second => info.sec
        }).value();
    }

    function momentFromLocalClock(localClock as Number, reference as Time.Moment) as Time.Moment? {
        var referenceClock = localClockSeconds(Gregorian.info(reference, Time.FORMAT_SHORT));
        var offset = referenceClock - reference.value();
        var candidate = localClock - offset;
        for (var i = 0; i < 3; i += 1) {
            var actualClock = localClockSeconds(Gregorian.info(new Time.Moment(candidate), Time.FORMAT_SHORT));
            if (actualClock == localClock) {
                return new Time.Moment(candidate);
            }
            candidate += localClock - actualClock;
        }
        // A civil time skipped by a daylight-saving change has no corresponding instant.
        return null;
    }

    function next(config as WaterConfig, earliest as Time.Moment) as Time.Moment? {
        var info = Gregorian.info(earliest, Time.FORMAT_SHORT);
        var localClock = localClockSeconds(info);
        var localMidnight = localClock - info.hour * 3600 - info.min * 60 - info.sec;
        // Step through calendar dates, not elapsed 24-hour periods.
        for (var day = 0; day <= 7; day += 1) {
            var date = Gregorian.utcInfo(new Time.Moment(localMidnight + day * 86400), Time.FORMAT_SHORT);
            var seconds = day == 0 ? info.hour * 3600 + info.min * 60 + info.sec : 0;
            var weekday = date.day_of_week as Number;
            var slot = minuteOnDay(config, weekday, seconds);
            while (slot != null) {
                var result = momentFromLocalClock(localMidnight + day * 86400 + slot * 60, earliest);
                if (result != null && result.value() >= earliest.value()) {
                    return result;
                }
                slot = minuteOnDay(config, weekday, slot * 60 + 1);
            }
        }
        return null;
    }

    function dueKey(config as WaterConfig, now as Time.Moment) as Number? {
        if (!config.enabled || config.error != null) {
            return null;
        }
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var minute = info.hour * 60 + info.min;
        var weekday = info.day_of_week as Number;
        if (!config.days[dayIndex(weekday)] ||
            minute < config.startMinute || minute > config.endMinute) {
            return null;
        }
        var elapsed = (minute - config.startMinute) * 60 + info.sec;
        var remainder = elapsed % (config.intervalMinutes * 60);
        if (remainder > MAX_DELAY_SECONDS) {
            return null;
        }
        return localClockSeconds(info) - remainder;
    }

    function respectMinimumSpacing(config as WaterConfig, reminder as Time.Moment,
                                   allowed as Time.Moment) as Time.Moment? {
        if (reminder.value() >= allowed.value()) {
            return reminder;
        }
        if (allowed.value() - reminder.value() <= MAX_DELAY_SECONDS &&
            dueKey(config, allowed) != null) {
            return allowed;
        }
        return next(config, allowed);
    }

    function eventTime(config as WaterConfig, earliest as Time.Moment,
                       lastEvent as Time.Moment?) as Time.Moment? {
        var nextTime = next(config, earliest);
        if (nextTime == null) {
            return null;
        }
        var allowed = earliestAllowedTime(earliest, lastEvent);
        nextTime = respectMinimumSpacing(config, nextTime, allowed);
        if (nextTime == null) {
            return null;
        }
        // Do not let a checkpoint consume the five-minute window preceding a reminder.
        var checkpoint = allowed.value() + CHECKPOINT_SECONDS;
        if (nextTime.value() >= checkpoint + MINIMUM_SECONDS) {
            return new Time.Moment(checkpoint);
        }
        return nextTime;
    }

    function arm(config as WaterConfig, earliest as Time.Moment) as Void {
        if (config.error != null) {
            System.println("DrinkWater: " + config.error);
        }
        var nextTime = pendingDebug(config, earliest);
        if (nextTime == null) {
            nextTime = eventTime(config, earliest, Background.getLastTemporalEventTime());
        }
        if (nextTime == null) {
            Background.deleteTemporalEvent();
            return;
        }
        Background.registerForTemporalEvent(nextTime);
    }
}
