import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsTitle extends WatchUi.Drawable {
    var _daysOnly as Boolean;
    var _view as LayoutView;

    function initialize(daysOnly as Boolean) {
        Drawable.initialize({});
        _daysOnly = daysOnly;
        _view = new LayoutView();
    }

    function draw(dc as Graphics.Dc) as Void {
        if (_view.updateLayoutSize(dc)) {
            _view.setLayout(_daysOnly ? Rez.Layouts.DaysMenuHeaderLayout(dc) : Rez.Layouts.SettingsMenuHeaderLayout(dc));
        }
        _view.drawLayout(dc);
    }
}

