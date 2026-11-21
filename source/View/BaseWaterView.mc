import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

function waterApp() as DrinkWaterApp {
    return Application.getApp() as DrinkWaterApp;
}

function clockText(minute as Number) as String {
    return (minute / 60).toNumber().format("%02d") + ":" + (minute % 60).format("%02d");
}

class BaseWaterView extends LayoutView {
    var controller as BaseWaterController;

    function initialize(input as BaseWaterController) {
        LayoutView.initialize();
        controller = input;
    }

    function setWaterLayout(items as Array<WatchUi.Drawable>, dc as Graphics.Dc) as Void {
        items.addAll(Rez.Layouts.SettingsErrorLayout(dc));
        setLayout(items);
    }

    function onShow() as Void {
        waterApp().visibleRoot = self;
        waterApp().refreshRootView();
    }

    function onHide() as Void {
        waterApp().visibleRoot = null;
    }

    function updateFrame(config as WaterConfig) as Boolean {
        label("status").setText(text(config.enabled ? Rez.Strings.Enabled : Rez.Strings.Disabled));
        label("status").setColor(config.enabled ? Theme.TEXT : Theme.MUTED);
        var error = config.error;
        var invalid = waterApp().scheduleError || error != null;
        show("errorTitle", invalid);
        show("errorDetail", invalid);
        show("content", !invalid);
        show("schedule", !invalid);
        if (invalid) {
            if (waterApp().scheduleError) {
                label("errorDetail").setText(text(Rez.Strings.ScheduleError));
            } else if (error != null) {
                label("errorDetail").setText(error);
            }
        }
        var hintStyle = invalid ? Theme.WARNING : Theme.MUTED;
        label("toggleHint").setText(text(config.enabled ? Rez.Strings.DeactivateHint : Rez.Strings.ActivateHint));
        label("toggleHint").setColor(hintStyle);
        label("menuHint").setColor(hintStyle);
        return !invalid;
    }

    function updateSchedule(config as WaterConfig) as Void {
        label("schedule").setText(clockText(config.startMinute) + " - " + clockText(config.endMinute) +
            " / " + config.intervalMinutes.toString() + " min");
    }
}
