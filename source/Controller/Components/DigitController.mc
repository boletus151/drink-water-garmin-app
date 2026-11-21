import Toybox.Lang;
import Toybox.WatchUi;

class DigitController extends NumberController {
    var activeDigit as Number = 0;
    var places as Array<Number> = [10, 1];
    var error as String? = null;
    var rangeId as ResourceId;
    var invalidId as ResourceId;

    function initialize(setting as String, label as String, initial as Number,
                        low as Number, high as Number, range as ResourceId, invalid as ResourceId) {
        NumberController.initialize(setting, label, initial, low, high, 1);
        rangeId = range;
        invalidId = invalid;
        if (initial < minimum || initial > maximum) {
            value = initial < minimum ? minimum : maximum;
            error = text(Rez.Strings.PreviousValueInvalid);
        }
    }

    function change(direction as Number) as Void {
        var place = places[activeDigit];
        var oldDigit = (value / place).toNumber() % 10;
        var digit = (oldDigit + direction + 10) % 10;
        value += (digit - oldDigit) * place;
        error = null;
        WatchUi.requestUpdate();
    }

    function confirm() as Boolean {
        if (activeDigit < places.size() - 1) {
            activeDigit += 1;
            error = null;
            WatchUi.requestUpdate();
            return false;
        }
        var invalid = validationError();
        if (invalid != null) {
            error = invalid;
            WatchUi.requestUpdate();
            return false;
        }
        return true;
    }

    function validationError() as String? {
        return value < minimum || value > maximum ? text(invalidId) : null;
    }

    function goBack() as Boolean {
        if (activeDigit > 0) {
            activeDigit -= 1;
            error = null;
            WatchUi.requestUpdate();
            return false;
        }
        return true;
    }
}
