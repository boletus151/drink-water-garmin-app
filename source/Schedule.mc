import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:background)
module Schedule {
    const MINIMUM_SECONDS = 300;
    const MAX_DELAY_SECONDS = 60;
    const CHECKPOINT_SECONDS = 3600;

    function minuteOnDay(config as WaterConfig, weekday as Number,
                         seconds as Number) as Number? {
        if (!config.enabled || config.error != null || !config.days[weekday - 1]) {
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

    // Gregorian.moment uses UTC. Convert a civil date without assuming a 24-hour local day.
    function civilSeconds(info as Gregorian.Info) as Number {
        return Gregorian.moment({
            :year => info.year, :month => info.month as Number, :day => info.day,
            :hour => info.hour, :minute => info.min, :second => info.sec
        }).value();
    }

    function localMoment(civil as Number, reference as Time.Moment) as Time.Moment? {
        var candidate = civil - (civilSeconds(Gregorian.info(reference, Time.FORMAT_SHORT)) - reference.value());
        for (var i = 0; i < 3; i += 1) {
            var actual = civilSeconds(Gregorian.info(new Time.Moment(candidate), Time.FORMAT_SHORT));
            if (actual == civil) {
                return new Time.Moment(candidate);
            }
            candidate += civil - actual;
        }
        // A civil time skipped by a daylight-saving change has no corresponding instant.
        return null;
    }

    function next(config as WaterConfig, earliest as Time.Moment) as Time.Moment? {
        var info = Gregorian.info(earliest, Time.FORMAT_SHORT);
        var civil = civilSeconds(info);
        var midnight = civil - info.hour * 3600 - info.min * 60 - info.sec;
        for (var day = 0; day <= 7; day += 1) {
            var date = Gregorian.utcInfo(new Time.Moment(midnight + day * 86400), Time.FORMAT_SHORT);
            var seconds = day == 0 ? info.hour * 3600 + info.min * 60 + info.sec : 0;
            var weekday = date.day_of_week as Number;
            var slot = minuteOnDay(config, weekday, seconds);
            while (slot != null) {
                var result = localMoment(midnight + day * 86400 + slot * 60, earliest);
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
        if (!config.days[weekday - 1] ||
            minute < config.startMinute || minute > config.endMinute) {
            return null;
        }
        var elapsed = (minute - config.startMinute) * 60 + info.sec;
        var remainder = elapsed % (config.intervalMinutes * 60);
        if (remainder > MAX_DELAY_SECONDS) {
            return null;
        }
        return civilSeconds(info) - remainder;
    }

    function eventTime(config as WaterConfig, earliest as Time.Moment,
                       lastEvent as Time.Moment?) as Time.Moment? {
        var nextTime = next(config, earliest);
        if (nextTime == null) {
            return null;
        }
        var allowed = earliest;
        if (lastEvent != null && allowed.value() < lastEvent.value() + MINIMUM_SECONDS) {
            allowed = lastEvent.add(new Time.Duration(MINIMUM_SECONDS));
        }
        if (nextTime.value() < allowed.value()) {
            if (allowed.value() - nextTime.value() <= MAX_DELAY_SECONDS &&
                dueKey(config, allowed) != null) {
                nextTime = allowed;
            } else {
                nextTime = next(config, allowed);
                if (nextTime == null) {
                    return null;
                }
            }
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
        var nextTime = eventTime(config, earliest, Background.getLastTemporalEventTime());
        if (nextTime == null) {
            Background.deleteTemporalEvent();
            return;
        }
        Background.registerForTemporalEvent(nextTime);
    }
}
