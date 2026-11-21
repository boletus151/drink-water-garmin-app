import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class WaterView extends BaseWaterView {
    var _water as WaterController;

    function initialize() {
        _water = new WaterController();
        BaseWaterView.initialize(_water);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setWaterLayout(Rez.Layouts.WaterLayout(dc), dc);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var config = Config.read();
        var valid = updateFrame(config);
        show("next", valid);
        if (valid) {
            label("content").setText(config.goalMl.toString() + " ml / dia");
            updateSchedule(config);
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
