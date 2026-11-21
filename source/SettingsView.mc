import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsTitle extends WatchUi.Drawable {
    var _title as String;

    function initialize(title as String) {
        Drawable.initialize({});
        _title = title;
    }

    function draw(dc as Graphics.Dc) as Void {
        Theme.clear(dc);
        Theme.title(dc, dc.getHeight() / 2, _title, true);
    }
}

class SettingsItem extends WatchUi.CustomMenuItem {
    function initialize(label as String, subLabel as String?, key as String) {
        CustomMenuItem.initialize(key, {});
        setLabel(label);
        setSubLabel(subLabel);
    }

    function draw(dc as Graphics.Dc) as Void {
        var label = getLabel();
        var subLabel = getSubLabel();
        Theme.menuItem(dc, label instanceof String ? label : null,
            subLabel instanceof String ? subLabel : null, isFocused());
    }
}

class SettingsMenu extends WatchUi.CustomMenu {
    var _count as Number;

    function initialize(daysOnly as Boolean) {
        CustomMenu.initialize(Theme.MENU_ITEM_HEIGHT, Theme.BACKGROUND, {
            :focusItemHeight => Theme.MENU_FOCUS_HEIGHT,
            :title => new SettingsTitle(text(daysOnly ? Rez.Strings.Days : Rez.Strings.Settings))
        });
        _count = daysOnly ? 7 : 6;
        if (daysOnly) {
            var names = [Rez.Strings.Monday, Rez.Strings.Tuesday, Rez.Strings.Wednesday,
                         Rez.Strings.Thursday, Rez.Strings.Friday, Rez.Strings.Saturday, Rez.Strings.Sunday];
            for (var i = 0; i < 7; i += 1) {
                addSetting("day" + (i + 1).toString(), names[i]);
            }
        } else {
            addSetting("enabled", Rez.Strings.AppName);
            addSetting("goalMl", Rez.Strings.Goal);
            addSetting("intervalMinutes", Rez.Strings.Interval);
            addSetting("startTime", Rez.Strings.StartHour);
            addSetting("endTime", Rez.Strings.EndHour);
            addItem(new SettingsItem(text(Rez.Strings.Days), null, "days"));
        }
    }

    function addSetting(key as String, title as ResourceId) as Void {
        addItem(new SettingsItem(text(title), valueText(key), key));
    }

    function valueText(key as String) as String {
        var value = Properties.getValue(key);
        if (key.equals("startTime") || key.equals("endTime")) {
            if (!(value instanceof Number)) {
                throw new Lang.UnexpectedTypeException("Time settings must be Number", null, null);
            }
            return clockText(value);
        }
        if (value instanceof Boolean) {
            return text(value ? Rez.Strings.Enabled : Rez.Strings.Disabled);
        }
        return value.toString();
    }

    function refresh() as Void {
        for (var i = 0; i < _count; i += 1) {
            var item = getItem(i);
            if (item != null) {
                var key = item.getId();
                if (key instanceof String && !key.equals("days")) {
                    item.setSubLabel(valueText(key));
                }
            }
        }
    }

    function onShow() as Void {
        refresh();
    }
}

class SettingsDelegate extends WatchUi.Menu2InputDelegate {
    var _menu as SettingsMenu;

    function initialize(menu as SettingsMenu, daysOnly as Boolean) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var key = item.getId();
        if (!(key instanceof String)) {
            return;
        }
        if (key.equals("days")) {
            var menu = new SettingsMenu(true);
            WatchUi.pushView(menu, new SettingsDelegate(menu, true), WatchUi.SLIDE_UP);
            return;
        }
        var value = Properties.getValue(key);
        if (value instanceof Boolean) {
            waterApp().save(key, !value);
            _menu.refresh();
        } else if (value instanceof Number) {
            var label = item.getLabel();
            var title = label instanceof String ? label : text(Rez.Strings.Settings);
            var editor = createNumberEditor(key, title, value);
            WatchUi.pushView(editor, new NumberDelegate(editor), WatchUi.SLIDE_UP);
        }
    }

    function createNumberEditor(key as String, title as String, value as Number) as NumberView {
        if (key.equals("startTime") || key.equals("endTime")) {
            return new TimeView(key, title, value);
        }
        if (key.equals("intervalMinutes")) {
            return new IntervalView(title, value);
        }
        if (key.equals("goalMl")) {
            return new NumberView(key, title, value, 50, 10000, 50);
        }
        throw new Lang.UnexpectedTypeException("Unknown numeric setting: " + key, null, null);
    }

}

class NumberView extends WatchUi.View {
    var key as String;
    var title as String;
    var value as Number;
    var minimum as Number;
    var maximum as Number;
    var step as Number;

    function initialize(setting as String, label as String, initial as Number,
                        low as Number, high as Number, increment as Number) {
        View.initialize();
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

    function onUpdate(dc as Graphics.Dc) as Void {
        Theme.clear(dc);
        Theme.title(dc, 42, title, false);
        Theme.number(dc, 87, value.toString());
        Theme.line(dc, 162, text(Rez.Strings.EditHint), Theme.MUTED);
        Theme.line(dc, 185, text(Rez.Strings.SaveHint), Theme.MUTED);
    }
}

class DigitView extends NumberView {
    var activeDigit as Number = 0;
    var places as Array<Number> = [10, 1];
    var error as String? = null;
    var _range as ResourceId;
    var _invalid as ResourceId;

    function initialize(setting as String, label as String, initial as Number,
                        low as Number, high as Number, range as ResourceId, invalid as ResourceId) {
        NumberView.initialize(setting, label, initial, low, high, 1);
        _range = range;
        _invalid = invalid;
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
        return value < minimum || value > maximum ? text(_invalid) : null;
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

    function onUpdate(dc as Graphics.Dc) as Void {
        Theme.clear(dc);
        var center = dc.getWidth() / 2;
        Theme.title(dc, 42, title, false);
        var time = places.size() == 4;
        if (time) {
            Theme.number(dc, 87, ":");
        }
        for (var i = 0; i < places.size(); i += 1) {
            var x = center + (time ? -63 + i * 38 + (i >= 2 ? 12 : 0) : (i == 0 ? -22 : 22));
            var width = time ? 34 : 40;
            var digit = (value / places[i]).toNumber() % 10;
            Theme.digit(dc, x, 87, width, digit.toString(), i == activeDigit);
        }
        var message = error;
        Theme.line(dc, 145, message != null ? message : text(_range),
            message != null ? Theme.WARNING : Theme.MUTED);
        Theme.line(dc, 174, text(Rez.Strings.EditHint), Theme.MUTED);
        Theme.line(dc, 195,
            text(activeDigit < places.size() - 1 ? Rez.Strings.NextDigitHint : Rez.Strings.SaveHint),
            Theme.MUTED);
    }
}

class TimeView extends DigitView {
    function initialize(setting as String, label as String, initial as Number) {
        var draft = initial < 0 ? 0 : (initial > 1439 ? 1439 : initial);
        var hour = (draft / 60).toNumber();
        var minute = draft % 60;
        DigitView.initialize(setting, label, hour * 100 + minute,
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

class IntervalView extends DigitView {
    function initialize(label as String, initial as Number) {
        DigitView.initialize("intervalMinutes", label, initial,
            Config.MIN_INTERVAL, Config.MAX_INTERVAL, Rez.Strings.IntervalRange, Rez.Strings.InvalidInterval);
    }
}

class NumberDelegate extends WatchUi.BehaviorDelegate {
    var _view as NumberView;

    function initialize(view as NumberView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Boolean {
        _view.change(1);
        return true;
    }

    function onNextPage() as Boolean {
        _view.change(-1);
        return true;
    }

    function onSelect() as Boolean {
        if (!_view.confirm()) {
            return true;
        }
        _view.save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        if (_view.goBack()) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}
