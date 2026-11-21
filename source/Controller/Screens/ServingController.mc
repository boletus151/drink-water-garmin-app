import Toybox.Lang;
import Toybox.WatchUi;

class ServingController extends NumberController {
    var error as String? = null;

    function initialize(label as String, initial as Number) {
        NumberController.initialize("servingMl", label, initial,
            Config.MIN_SERVING, Config.MAX_SERVING, Config.SERVING_STEP);
        if (!Config.validServing(initial)) {
            value = initial < minimum ? minimum : initial > maximum ? maximum :
                minimum + ((initial - minimum) / step).toNumber() * step;
            error = text(Rez.Strings.PreviousValueInvalid);
        }
    }

    function change(direction as Number) as Void {
        error = null;
        NumberController.change(direction);
    }

    function confirm() as Boolean {
        if (!Config.validServing(value)) {
            error = text(Rez.Strings.InvalidServing);
            WatchUi.requestUpdate();
            return false;
        }
        return true;
    }
}
