import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsTitle extends WatchUi.Drawable {
    var _daysOnly as Boolean;
    var _view as LayoutView;
    var intakeFeedback as Boolean = false;

    function initialize(daysOnly as Boolean) {
        Drawable.initialize({});
        _daysOnly = daysOnly;
        _view = new LayoutView();
    }

    function draw(dc as Graphics.Dc) as Void {
        if (_view.updateLayoutSize(dc)) {
            _view.setLayout(_daysOnly ? Rez.Layouts.DaysMenuHeaderLayout(dc) : Rez.Layouts.SettingsMenuHeaderLayout(dc));
            _view.setVerticalLayout([], [["title"]], [], 0, Theme.STACK_GAP);
        }
        _view.show("background", !intakeFeedback);
        if (intakeFeedback) {
            dc.setColor(Theme.INTAKE_FEEDBACK, Theme.INTAKE_FEEDBACK);
            dc.clear();
        }
        _view.drawLayout(dc);
    }
}

