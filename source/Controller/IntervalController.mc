import Toybox.Lang;

class IntervalController extends DigitController {
    function initialize(label as String, initial as Number) {
        DigitController.initialize("intervalMinutes", label, initial,
            Config.MIN_INTERVAL, Config.MAX_INTERVAL, Rez.Strings.IntervalRange, Rez.Strings.InvalidInterval);
    }
}
