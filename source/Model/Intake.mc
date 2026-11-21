import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:background)
class DailyIntake {
    var day as Number;
    var totalMl as Number = 0;
    var error as String? = null;

    function initialize(date as Number) {
        day = date;
    }
}

(:background)
module Intake {
    const DEBUG_INITIAL_ML = 1800;

    function storageKey(debug as Boolean) as String {
        return debug ? "debugDailyIntake" : "dailyIntake";
    }

    function dayKey(info as Gregorian.Info) as Number {
        return info.year * 10000 + (info.month as Number) * 100 + info.day;
    }

    function read(now as Time.Moment) as DailyIntake {
        return readForMode(now, DebugConfig.DEBUG);
    }

    function readForMode(now as Time.Moment, debug as Boolean) as DailyIntake {
        var result = new DailyIntake(dayKey(Gregorian.info(now, Time.FORMAT_SHORT)));
        var stored = Storage.getValue(storageKey(debug));
        if (stored == null) {
            return result;
        }
        if (stored instanceof Dictionary) {
            var day = stored["day"];
            var total = stored["totalMl"];
            if (day instanceof Number && total instanceof Number && day > 0 &&
                total >= 0 && total % Config.SERVING_STEP == 0) {
                if (day == result.day) {
                    result.totalMl = total;
                }
                return result;
            }
        }
        result.error = text(Rez.Strings.InvalidIntake);
        return result;
    }
}
