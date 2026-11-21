import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Lang;

(:background)
function text(id as ResourceId) as String {
    return Application.loadResource(id) as String;
}

(:background)
class WaterConfig {
    var enabled as Boolean = true;
    var goalMl as Number = 2000;
    var intervalMinutes as Number = 60;
    var startMinute as Number = 540;
    var endMinute as Number = 1260;
    var days as Array<Boolean> = [true, true, true, true, true, true, true];
    var error as String? = null;

    function initialize() {
    }

    function validate() as String? {
        if (goalMl < 50 || goalMl > 10000) {
            return text(Rez.Strings.InvalidGoal);
        }
        if (intervalMinutes < Config.MIN_INTERVAL || intervalMinutes > Config.MAX_INTERVAL) {
            return text(Rez.Strings.InvalidInterval);
        }
        if (startMinute < 0 || endMinute > 1439 || startMinute >= endMinute) {
            return text(Rez.Strings.InvalidHours);
        }
        for (var i = 0; i < days.size(); i += 1) {
            if (days[i]) {
                return null;
            }
        }
        return text(Rez.Strings.NoDays);
    }
}

(:background)
module Config {
    const DEBUG = true;
    const MIN_INTERVAL = 15;
    const MAX_INTERVAL = 60;

    function read() as WaterConfig {
        var result = new WaterConfig();
        var version = Properties.getValue("schemaVersion");
        if (!(version instanceof Number) || version < 1 || version > 3) {
            result.error = text(Rez.Strings.UnsupportedVersion);
            return result;
        }
        var keys = ["goalMl", "intervalMinutes", "startTime", "endTime"];
        var values = [] as Array<Number>;
        for (var i = 0; i < keys.size(); i += 1) {
            var value = Properties.getValue(keys[i]);
            if (!(value instanceof Number)) {
                result.error = text(Rez.Strings.InvalidSettings);
                return result;
            }
            values.add(value);
        }
        var enabled = Properties.getValue("enabled");
        if (!(enabled instanceof Boolean)) {
            result.error = text(Rez.Strings.InvalidSettings);
            return result;
        }
        result.enabled = enabled;
        result.goalMl = values[0];
        result.intervalMinutes = values[1];
        result.startMinute = values[2];
        result.endMinute = values[3];
        for (var day = 1; day <= 7; day += 1) {
            var selected = Properties.getValue("day" + day.toString());
            if (!(selected instanceof Boolean)) {
                result.error = text(Rez.Strings.InvalidSettings);
                return result;
            }
            result.days[day - 1] = selected;
        }
        result.error = result.validate();
        return result;
    }
}
