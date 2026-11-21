import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

function waterApp() as DrinkWaterApp {
    return Application.getApp() as DrinkWaterApp;
}

function clockText(minute as Number) as String {
    return (minute / 60).toNumber().format("%02d") + ":" + (minute % 60).format("%02d");
}

class WaterView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var config = Config.read();
        Theme.clear(dc);
        Theme.title(dc, 24, text(Rez.Strings.AppName), false);
        Theme.line(dc, 57, text(config.enabled ? Rez.Strings.Enabled : Rez.Strings.Disabled),
            config.enabled ? Theme.TEXT : Theme.MUTED);
        var error = config.error;
        if (waterApp().scheduleError || error != null) {
            Theme.line(dc, 92, text(Rez.Strings.InvalidSettings), Theme.WARNING);
            if (waterApp().scheduleError) {
                Theme.line(dc, 118, text(Rez.Strings.ScheduleError), Theme.WARNING);
            } else if (error != null) {
                Theme.line(dc, 118, error, Theme.WARNING);
            }
        } else {
            Theme.line(dc, 87, waterApp().reminder ? text(Rez.Strings.Reminder) : config.goalMl.toString() + " ml / dia",
                waterApp().reminder ? Theme.ACCENT : Theme.TEXT);
            Theme.line(dc, 111, clockText(config.startMinute) + " - " + clockText(config.endMinute) +
                " / " + config.intervalMinutes.toString() + " min", Theme.MUTED);
            var earliest = Time.now().add(new Time.Duration(1));
            var nextTime = Schedule.pendingDebug(config, earliest);
            if (nextTime == null) {
                nextTime = Schedule.next(config, earliest);
            }
            if (nextTime != null) {
                var info = Gregorian.info(nextTime, Time.FORMAT_SHORT);
                Theme.line(dc, 141, text(Rez.Strings.Next) + ": " + info.day.format("%02d") + "/" +
                    (info.month as Number).format("%02d") + " " + clockText(info.hour * 60 + info.min), Theme.TEXT);
            } else {
                Theme.line(dc, 141, text(Rez.Strings.NoNext), Theme.TEXT);
            }
        }
        var hintStyle = waterApp().scheduleError || error != null ? Theme.WARNING : Theme.MUTED;
        Theme.line(dc, 175, text(config.enabled ? Rez.Strings.DeactivateHint : Rez.Strings.ActivateHint), hintStyle);
        Theme.line(dc, 195, text(Rez.Strings.MenuHint), hintStyle);
    }
}

class WaterDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        var enabled = Properties.getValue("enabled");
        if (!(enabled instanceof Boolean)) {
            throw new Lang.UnexpectedTypeException("enabled must be Boolean", null, null);
        }
        waterApp().save("enabled", !enabled);
        return true;
    }

    function onMenu() as Boolean {
        return openSettings();
    }

    function onPreviousPage() as Boolean {
        return openSettings();
    }

    function openSettings() as Boolean {
        var menu = new SettingsMenu(false);
        WatchUi.pushView(menu, new SettingsDelegate(menu, false), WatchUi.SLIDE_UP);
        return true;
    }
}
