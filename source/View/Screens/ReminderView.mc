import Toybox.Graphics;

class ReminderView extends RootView {
    function initialize() {
        RootView.initialize(new ReminderController());
    }

    function onLayout(dc as Graphics.Dc) as Void {
        WaterFrame.setLayout(self, Rez.Layouts.ReminderLayout(dc), dc);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var config = Config.read();
        label("status").setText(text(config.enabled ? Rez.Strings.Enabled : Rez.Strings.Disabled));
        label("status").setColor(config.enabled ? Theme.TEXT : Theme.MUTED);
        show("content", WaterFrame.update(self, config, waterApp().scheduleError));
        drawLayout(dc);
    }
}
