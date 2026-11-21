import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class LayoutView extends WatchUi.View {
    var _layoutWidth as Number = 0;
    var _layoutHeight as Number = 0;
    var _items as Array<WatchUi.Drawable> = [];
    var _hidden as Array<WatchUi.Drawable> = [];
    var _stackHeader as Array<Array<StackText>> = [];
    var _stackContent as Array<Array<StackText>> = [];
    var _stackFooter as Array<Array<StackText>> = [];
    var _stackPadding as Number = 0;
    var _stackGap as Number = Theme.STACK_GAP;
    var _vertical as Boolean = false;

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
        _vertical = false;
        _stackHeader = [];
        _stackContent = [];
        _stackFooter = [];
    }

    function stackRows(rows as Array<Array<String>>) as Array<Array<StackText>> {
        var result = [] as Array<Array<StackText>>;
        for (var i = 0; i < rows.size(); i += 1) {
            var row = [] as Array<StackText>;
            for (var j = 0; j < rows[i].size(); j += 1) {
                var item = drawable(rows[i][j]);
                if (!(item instanceof StackText)) {
                    throw new Lang.UnexpectedTypeException("Vertical layout requires StackText: " +
                        rows[i][j], null, null);
                }
                row.add(item);
            }
            result.add(row);
        }
        return result;
    }

    function setVerticalLayout(header as Array<Array<String>>, content as Array<Array<String>>,
            footer as Array<Array<String>>, padding as Number, gap as Number) as Void {
        _stackHeader = stackRows(header);
        _stackContent = stackRows(content);
        _stackFooter = stackRows(footer);
        _stackPadding = padding;
        _stackGap = gap;
        _vertical = true;
    }

    function setEditorLayout(items as Array<WatchUi.Drawable>, dc as Graphics.Dc,
            content as Array<Array<String>>) as Void {
        setLayout(items);
        var confirmation = findDrawableById("confirmHint") != null ? "confirmHint" : "saveHint";
        setVerticalLayout([["title"]], content, [["editHint"], [confirmation]],
            (dc.getHeight() / 12).toNumber(), Theme.STACK_GAP);
    }

    function stackHeight(rows as Array<Array<StackText>>, dc as Graphics.Dc, width as Number) as Number {
        var total = 0;
        var count = 0;
        for (var i = 0; i < rows.size(); i += 1) {
            var visible = 0;
            for (var j = 0; j < rows[i].size(); j += 1) {
                if (_hidden.indexOf(rows[i][j]) < 0) {
                    visible += 1;
                }
            }
            if (visible == 0) {
                continue;
            }
            var itemWidth = ((width - _stackGap * (visible - 1)) / visible).toNumber();
            var height = 0;
            for (var j = 0; j < rows[i].size(); j += 1) {
                var item = rows[i][j];
                if (_hidden.indexOf(item) < 0) {
                    item.measure(dc, itemWidth);
                    if (item.measuredHeight > height) {
                        height = item.measuredHeight;
                    }
                }
            }
            total += height;
            count += 1;
        }
        return total + (count > 0 ? (count - 1) * _stackGap : 0);
    }

    function positionStack(rows as Array<Array<StackText>>, center as Number, top as Number) as Void {
        for (var i = 0; i < rows.size(); i += 1) {
            var width = 0;
            var height = 0;
            var count = 0;
            for (var j = 0; j < rows[i].size(); j += 1) {
                var item = rows[i][j];
                if (_hidden.indexOf(item) < 0) {
                    width += item.measuredWidth;
                    if (item.measuredHeight > height) {
                        height = item.measuredHeight;
                    }
                    count += 1;
                }
            }
            if (count == 0) {
                continue;
            }
            width += (count - 1) * _stackGap;
            var left = center - (width / 2).toNumber();
            for (var j = 0; j < rows[i].size(); j += 1) {
                var item = rows[i][j];
                if (_hidden.indexOf(item) < 0) {
                    item.setLocation(left + (item.measuredWidth / 2).toNumber(),
                        top + (height / 2).toNumber());
                    left += item.measuredWidth + _stackGap;
                }
            }
            top += height + _stackGap;
        }
    }

    function arrangeVerticalLayout(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var edgeWidth = (width * 0.65).toNumber();
        var headerHeight = stackHeight(_stackHeader, dc, edgeWidth);
        var footerHeight = stackHeight(_stackFooter, dc, (width * 0.90).toNumber());
        var contentWidth = _stackHeader.size() == 0 && _stackFooter.size() == 0 ?
            width - _stackPadding * 2 : (width * 0.90).toNumber();
        var contentHeight = stackHeight(_stackContent, dc, contentWidth);
        var top = _stackPadding + headerHeight + (headerHeight > 0 ? _stackGap : 0);
        var bottom = height - _stackPadding - footerHeight - (footerHeight > 0 ? _stackGap : 0);
        if (contentHeight > bottom - top) {
            throw new Lang.InvalidValueException("Vertical layout exceeds available height: content=" +
                contentHeight.toString() + ", available=" + (bottom - top).toString() +
                ", header=" + headerHeight.toString() + ", footer=" + footerHeight.toString());
        }
        var center = (width / 2).toNumber();
        positionStack(_stackHeader, center, _stackPadding);
        positionStack(_stackContent, center, top + ((bottom - top - contentHeight) / 2).toNumber());
        positionStack(_stackFooter, center, height - _stackPadding - footerHeight);
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
        if (_vertical) {
            arrangeVerticalLayout(dc);
        }
        // Drawable visibility is unavailable on API 3.1 devices.
        for (var i = 0; i < _items.size(); i += 1) {
            var item = _items[i];
            if (_hidden.indexOf(item) < 0) {
                item.draw(dc);
            }
        }
    }
}
