import Toybox.Graphics;

class ReminderView extends BaseWaterView {
    function initialize() {
        BaseWaterView.initialize(new ReminderController());
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setWaterLayout(Rez.Layouts.ReminderLayout(dc), dc);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var config = Config.read();
        if (updateFrame(config)) {
            updateSchedule(config);
        }
        drawLayout(dc);
    }
}
