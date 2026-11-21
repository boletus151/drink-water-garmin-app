import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class LayoutView extends WatchUi.View {
    var _layoutWidth as Number = 0;
    var _layoutHeight as Number = 0;
    var _items as Array<WatchUi.Drawable> = [];
    var _hidden as Array<WatchUi.Drawable> = [];

    function initialize() {
        View.initialize();
    }

    function drawable(id as String) as WatchUi.Drawable {
        var item = findDrawableById(id);
        if (item == null) {
            throw new Lang.UnexpectedTypeException("Missing layout drawable: " + id, null, null);
        }
        return item;
    }

    function label(id as String) as WatchUi.Text or WatchUi.TextArea {
        var item = drawable(id);
        if (!(item instanceof WatchUi.Text) && !(item instanceof WatchUi.TextArea)) {
            throw new Lang.UnexpectedTypeException("Layout drawable must be text: " + id, null, null);
        }
        return item;
    }

    function setLayout(items as Array<WatchUi.Drawable>?) as Void {
        View.setLayout(items);
        _items = items != null ? items : [];
        _hidden = [];
    }

    function show(id as String, shown as Boolean) as Void {
        var item = drawable(id);
        if (shown) {
            _hidden.remove(item);
        } else if (_hidden.indexOf(item) < 0) {
            _hidden.add(item);
        }
    }

    function updateLayoutSize(dc as Graphics.Dc) as Boolean {
        var changed = _layoutWidth != dc.getWidth() || _layoutHeight != dc.getHeight();
        _layoutWidth = dc.getWidth();
        _layoutHeight = dc.getHeight();
        return changed;
    }

    function drawLayout(dc as Graphics.Dc) as Void {
        // Drawable visibility is unavailable on API 3.1 devices.
        for (var i = 0; i < _items.size(); i += 1) {
            var item = _items[i];
            if (_hidden.indexOf(item) < 0) {
                item.draw(dc);
            }
        }
    }
}
