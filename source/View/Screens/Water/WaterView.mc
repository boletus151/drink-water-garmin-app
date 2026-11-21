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
        if (waterApp().refreshRootView()) {
            return;
        }
        var now = Time.now();
        var config = Config.readAt(now);
        var valid = WaterFrame.update(self, config, waterApp().scheduleError);
        show("goal", valid);
        show("consumed", valid);
        show("schedule", valid);
        show("next", valid);
        if (valid) {
            label("goal").setText(text(Rez.Strings.GoalLabel) + ": " + config.goalMl.toString() + " ml");
            label("consumed").setText(text(Rez.Strings.ConsumedLabel) + ": " + config.consumedMl.toString() + " ml");
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
