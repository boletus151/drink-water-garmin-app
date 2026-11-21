import Toybox.Graphics;
import Toybox.System;

class ReminderView extends RootView {
    function initialize() {
        RootView.initialize(new ReminderController());
    }

    function onLayout(dc as Graphics.Dc) as Void {
        WaterFrame.setLayout(self, Rez.Layouts.ReminderLayout(dc), dc);
    }

    function onShow() as Void {
        RootView.onShow();
        if (waterApp().visibleRoot == self) {
            System.println("DrinkWater INFO: pantalla de recordatorio visible");
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (waterApp().refreshRootView()) {
            return;
        }
        var config = Config.read();
        var valid = WaterFrame.update(self, config, waterApp().scheduleError);
        show("content", valid);
        show("remaining", valid);
        if (valid) {
            var remaining = config.goalMl - config.consumedMl;
            if (remaining < 0) {
                remaining = 0;
            }
            label("remaining").setText(text(Rez.Strings.RemainingLabel) + ": " + remaining.toString() + " ml");
        }
        drawLayout(dc);
    }
}
