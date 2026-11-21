import Toybox.Graphics;

class GoalReachedView extends RootView {
    function initialize() {
        RootView.initialize(new RootController());
    }

    function onLayout(dc as Graphics.Dc) as Void {
        WaterFrame.setLayout(self, Rez.Layouts.GoalReachedLayout(dc), dc);
        show("toggleHint", false);
        show("menuHint", false);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (waterApp().refreshRootView()) {
            return;
        }
        var config = Config.read();
        var valid = WaterFrame.update(self, config, waterApp().scheduleError);
        show("content", valid);
        show("goal", valid);
        // show("consumed", valid);
        show("paused", valid);
        if (valid) {
            label("goal").setText(config.goalMl.toString() + " ml");
            // label("consumed").setText(text(Rez.Strings.ConsumedLabel) + ": " + config.consumedMl.toString() + " ml");
        }
        drawLayout(dc);
    }
}
