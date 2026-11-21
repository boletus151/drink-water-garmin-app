import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class WaterFrame {
    static function setLayout(view as LayoutView, items as Array<WatchUi.Drawable>, dc as Graphics.Dc) as Void {
        var content = [] as Array<Array<String>>;
        for (var i = 0; i < items.size(); i += 1) {
            var item = items[i];
            if (item instanceof StackText) {
                var id = item.identifier;
                if (!(id instanceof String)) {
                    throw new Lang.UnexpectedTypeException("Stack text requires a String identifier", null, null);
                }
                content.add([id]);
            }
        }
        content.add(["errorTitle"]);
        content.add(["errorDetail"]);
        items.addAll(Rez.Layouts.WaterFrameLayout(dc));
        view.setLayout(items);
        view.setVerticalLayout([["title"]], content, [["toggleHint"], ["menuHint"]],
            (dc.getHeight() / 48).toNumber(), Theme.ROOT_STACK_GAP);
    }

    static function update(view as LayoutView, config as WaterConfig, scheduleError as Boolean) as Boolean {
        var error = config.error;
        var invalid = scheduleError || error != null;
        view.show("errorTitle", invalid);
        view.show("errorDetail", invalid);
        if (invalid) {
            if (scheduleError) {
                view.label("errorDetail").setText(text(Rez.Strings.ScheduleError));
            } else if (error != null) {
                view.label("errorDetail").setText(error);
            }
        }
        var hintStyle = invalid ? Theme.WARNING : Theme.MUTED;
        view.label("toggleHint").setText(text(config.enabled ? Rez.Strings.DeactivateHint : Rez.Strings.ActivateHint));
        view.label("toggleHint").setColor(hintStyle);
        view.label("menuHint").setColor(hintStyle);
        return !invalid;
    }
}
