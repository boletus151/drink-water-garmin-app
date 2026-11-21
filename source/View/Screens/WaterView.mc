import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class WaterView extends RootView {
    var _water as WaterController;

    function initialize() {
        _water = new WaterController();
        RootView.initialize(_water);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        WaterFrame.setLayout(self, Rez.Layouts.WaterLayout(dc), dc);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var config = Config.read();
        label("status").setText(text(config.enabled ? Rez.Strings.Enabled : Rez.Strings.Disabled));
        label("status").setColor(config.enabled ? Theme.TEXT : Theme.MUTED);
        var valid = WaterFrame.update(self, config, waterApp().scheduleError);
        show("content", valid);
        show("schedule", valid);
        show("next", valid);
        if (valid) {
            label("content").setText(config.goalMl.toString() + " ml / dia");
            label("schedule").setText(clockText(config.startMinute) + " - " + clockText(config.endMinute) +
                " / " + config.intervalMinutes.toString() + " min");
            var nextTime = _water.nextReminder(config);
            if (nextTime != null) {
                var info = Gregorian.info(nextTime, Time.FORMAT_SHORT);
                label("next").setText(text(Rez.Strings.Next) + ": " + info.day.format("%02d") + "/" +
                    (info.month as Number).format("%02d") + " " + clockText(info.hour * 60 + info.min));
            } else {
                label("next").setText(text(Rez.Strings.NoNext));
            }
        }
        drawLayout(dc);
    }
}
