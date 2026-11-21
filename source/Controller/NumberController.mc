import Toybox.Lang;
import Toybox.WatchUi;

class NumberController extends WatchUi.BehaviorDelegate {
    var key as String;
    var title as String;
    var value as Number;
    var minimum as Number;
    var maximum as Number;
    var step as Number;

    function initialize(setting as String, label as String, initial as Number,
                        low as Number, high as Number, increment as Number) {
        BehaviorDelegate.initialize();
        key = setting;
        title = label;
        value = initial;
        minimum = low;
        maximum = high;
        step = increment;
    }

    function change(direction as Number) as Void {
        value += direction * step;
        if (value < minimum) { value = minimum; }
        if (value > maximum) { value = maximum; }
        WatchUi.requestUpdate();
    }

    function confirm() as Boolean {
        return true;
    }

    function goBack() as Boolean {
        return true;
    }

    function save() as Void {
        waterApp().save(key, value);
    }

    function onPreviousPage() as Boolean {
        change(1);
        return true;
    }

    function onNextPage() as Boolean {
        change(-1);
        return true;
    }

    function onSelect() as Boolean {
        if (!confirm()) {
            return true;
        }
        save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        if (goBack()) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}
