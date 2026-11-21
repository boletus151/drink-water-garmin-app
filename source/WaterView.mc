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

    function line(dc as Graphics.Dc, y as Number, value as String) as Void {
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_XTINY, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var config = Config.read();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth() / 2, 24, Graphics.FONT_SMALL,
            text(Rez.Strings.AppName),
            Graphics.TEXT_JUSTIFY_CENTER);
        line(dc, 57, text(config.enabled ? Rez.Strings.Enabled : Rez.Strings.Disabled));
        var error = config.error;
        if (waterApp().scheduleError || error != null) {
            line(dc, 92, text(Rez.Strings.InvalidSettings));
            if (waterApp().scheduleError) {
                line(dc, 118, text(Rez.Strings.ScheduleError));
            } else if (error != null) {
                line(dc, 118, error);
            }
        } else {
            line(dc, 87, waterApp().reminder ? text(Rez.Strings.Reminder) : config.goalMl.toString() + " ml / dia");
            line(dc, 111, clockText(config.startMinute) + " - " + clockText(config.endMinute) +
                " / " + config.intervalMinutes.toString() + " min");
            var nextTime = Schedule.next(config, Time.now().add(new Time.Duration(1)));
            if (nextTime != null) {
                var info = Gregorian.info(nextTime, Time.FORMAT_SHORT);
                line(dc, 141, text(Rez.Strings.Next) + ": " + info.day.format("%02d") + "/" +
                    (info.month as Number).format("%02d") + " " + clockText(info.hour * 60 + info.min));
            } else {
                line(dc, 141, text(Rez.Strings.NoNext));
            }
        }
        line(dc, 175, text(config.enabled ? Rez.Strings.DeactivateHint : Rez.Strings.ActivateHint));
        line(dc, 195, text(Rez.Strings.MenuHint));
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
