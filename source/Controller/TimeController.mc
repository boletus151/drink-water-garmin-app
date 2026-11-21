import Toybox.Lang;
import Toybox.WatchUi;

class TimeController extends DigitController {
    function initialize(setting as String, label as String, initial as Number) {
        var draft = initial < 0 ? 0 : (initial > 1439 ? 1439 : initial);
        var hour = (draft / 60).toNumber();
        var minute = draft % 60;
        DigitController.initialize(setting, label, hour * 100 + minute,
            0, 2359, Rez.Strings.TimeRange, Rez.Strings.InvalidHourValue);
        places = [1000, 100, 10, 1];
        if (initial != draft) {
            error = text(Rez.Strings.PreviousValueInvalid);
        }
    }

    function change(direction as Number) as Void {
        var count = 10;
        if (activeDigit == 0) {
            count = 3;
        } else if (activeDigit == 1 && value >= 2000) {
            count = 4;
        } else if (activeDigit == 2) {
            count = 6;
        }
        var place = places[activeDigit];
        var oldDigit = (value / place).toNumber() % 10;
        var digit = (oldDigit + direction + count) % count;
        value += (digit - oldDigit) * place;
        var hourUnits = (value / 100).toNumber() % 10;
        if (activeDigit == 0 && value >= 2000 && hourUnits > 3) {
            value -= hourUnits * 100;
        }
        error = null;
        WatchUi.requestUpdate();
    }

    function validationError() as String? {
        if ((value / 100).toNumber() > 23) {
            return text(Rez.Strings.InvalidHourValue);
        }
        if (value % 100 > 59) {
            return text(Rez.Strings.InvalidMinuteValue);
        }
        return null;
    }

    function save() as Void {
        waterApp().save(key, (value / 100).toNumber() * 60 + value % 100);
    }
}
