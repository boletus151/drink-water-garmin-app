import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsMenu extends WatchUi.Menu2 {
    var _count as Number;

    function initialize(daysOnly as Boolean) {
        Menu2.initialize({:title => text(daysOnly ? Rez.Strings.Days : Rez.Strings.Settings)});
        _count = daysOnly ? 7 : 8;
        if (daysOnly) {
            var names = [Rez.Strings.Monday, Rez.Strings.Tuesday, Rez.Strings.Wednesday,
                         Rez.Strings.Thursday, Rez.Strings.Friday, Rez.Strings.Saturday, Rez.Strings.Sunday];
            for (var i = 0; i < 7; i += 1) {
                addSetting("day" + ((i + 1) % 7 + 1).toString(), names[i]);
            }
        } else {
            addSetting("enabled", Rez.Strings.AppName);
            addSetting("goalMl", Rez.Strings.Goal);
            addSetting("intervalMinutes", Rez.Strings.Interval);
            addSetting("startHour", Rez.Strings.StartHour);
            addSetting("startMinute", Rez.Strings.StartMinute);
            addSetting("endHour", Rez.Strings.EndHour);
            addSetting("endMinute", Rez.Strings.EndMinute);
            addItem(new WatchUi.MenuItem(text(Rez.Strings.Days), null, "days", {}));
        }
    }

    function addSetting(key as String, title as ResourceId) as Void {
        addItem(new WatchUi.MenuItem(text(title), valueText(key), key, {}));
    }

    function valueText(key as String) as String {
        var value = Properties.getValue(key);
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
            var minimum = 0;
            var maximum = 59;
            var step = 1;
            if (key.equals("goalMl")) {
                minimum = 50;
                maximum = 10000;
                step = 50;
            } else if (key.equals("intervalMinutes")) {
                minimum = 5;
                maximum = 1440;
            } else if (key.equals("startHour") || key.equals("endHour")) {
                maximum = 23;
            }
            var label = item.getLabel();
            var editor = new NumberView(key, label instanceof String ? label : text(Rez.Strings.Settings),
                value, minimum, maximum, step);
            WatchUi.pushView(editor, new NumberDelegate(editor), WatchUi.SLIDE_UP);
        }
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

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var center = dc.getWidth() / 2;
        dc.drawText(center, 42, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center, 87, Graphics.FONT_NUMBER_MILD, value.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center, 162, Graphics.FONT_XTINY, text(Rez.Strings.EditHint), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center, 185, Graphics.FONT_XTINY, text(Rez.Strings.SaveHint), Graphics.TEXT_JUSTIFY_CENTER);
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
        waterApp().save(_view.key, _view.value);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
