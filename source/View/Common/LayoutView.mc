import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class LayoutText extends WatchUi.Text {
    var row as String?;
    var padding as Number = 0;
    var measuredWidth as Number = 0;
    var measuredHeight as Number = 0;
    var _preferredFont as Graphics.FontType;
    var _font as Graphics.FontType;
    var _ink as Graphics.ColorType = Theme.TEXT;
    var _text as String = "";
    var _lines as Array<String> = [];

    function initialize(options as { :identifier as Object, :visible as Boolean,
                                    :text as String or ResourceId, :font as Graphics.FontType,
                                    :locX as Numeric, :locY as Numeric, :justification as Number,
                                    :ink as Graphics.ColorType, :row as String, :padding as Number }) {
        Text.initialize(options);
        var ink = options[:ink];
        var font = options[:font];
        if (ink == null || font == null) {
            throw new Lang.UnexpectedTypeException("Layout text requires a font and an ink color", null, null);
        }
        _preferredFont = font;
        _font = font;
        setColor(ink);
        row = options[:row];
        var inset = options[:padding];
        if (inset != null) {
            if (inset < 0) {
                throw new Lang.UnexpectedTypeException("Layout padding cannot be negative", null, null);
            }
            padding = inset;
        }
        var value = options[:text];
        if (value != null) {
            setText(value);
        }
    }

    function setText(value as String or ResourceId) as Void {
        _text = value instanceof String ? value : text(value);
        Text.setText(value);
    }

    function setColor(color as Graphics.ColorType) as Void {
        _ink = color;
        Text.setColor(color);
    }

    function measure(dc as Graphics.Dc, availableWidth as Number, compact as Boolean) as Void {
        var numeric = _preferredFont == Graphics.FONT_NUMBER_MILD;
        _font = compact ? (numeric ? Graphics.FONT_SMALL : Graphics.FONT_XTINY) : _preferredFont;
        _lines = [];
        var contentWidth = availableWidth - padding * 2;
        if (contentWidth <= 0) {
            throw new Lang.UnexpectedTypeException("Layout has no room for text", null, null);
        }
        if (numeric) {
            _lines.add(_text);
        } else {
            wrap(dc, contentWidth);
        }
        measuredWidth = 0;
        for (var i = 0; i < _lines.size(); i += 1) {
            var lineWidth = dc.getTextWidthInPixels(_lines[i], _font);
            if (lineWidth > measuredWidth) {
                measuredWidth = lineWidth;
            }
        }
        // Digit cells keep their width when the value or the selected digit changes.
        if (padding > 0) {
            for (var digit = 0; digit < 10; digit += 1) {
                var digitWidth = dc.getTextWidthInPixels(digit.toString(), _font);
                if (digitWidth > measuredWidth) {
                    measuredWidth = digitWidth;
                }
            }
        }
        measuredWidth += padding * 2;
        measuredHeight = dc.getFontHeight(_font) * _lines.size() + padding * 2;
    }

    function wrap(dc as Graphics.Dc, availableWidth as Number) as Void {
        var remaining = _text;
        var line = "";
        while (remaining.length() > 0) {
            var space = remaining.find(" ");
            var word = remaining;
            if (space == null) {
                remaining = "";
            } else {
                var prefix = remaining.substring(0, space);
                var suffix = remaining.substring(space + 1, remaining.length());
                if (prefix == null || suffix == null) {
                    throw new Lang.UnexpectedTypeException("Cannot split layout text", null, null);
                }
                word = prefix;
                remaining = suffix;
            }
            var candidate = line.length() == 0 ? word : line + " " + word;
            if (dc.getTextWidthInPixels(candidate, _font) <= availableWidth) {
                line = candidate;
                continue;
            }
            if (line.length() > 0) {
                _lines.add(line);
                line = "";
            }
            for (var i = 0; i < word.length(); i += 1) {
                var character = word.substring(i, i + 1);
                if (character == null) {
                    throw new Lang.UnexpectedTypeException("Cannot read layout text", null, null);
                }
                if (dc.getTextWidthInPixels(character, _font) > availableWidth) {
                    throw new Lang.UnexpectedTypeException("Layout is too narrow for a character", null, null);
                }
                if (dc.getTextWidthInPixels(line + character, _font) > availableWidth) {
                    _lines.add(line);
                    line = "";
                }
                line += character;
            }
        }
        _lines.add(line);
    }

    function draw(dc as Graphics.Dc) as Void {
        dc.setColor(_ink, Graphics.COLOR_TRANSPARENT);
        var lineHeight = dc.getFontHeight(_font);
        for (var i = 0; i < _lines.size(); i += 1) {
            dc.drawText(locX, locY + padding + i * lineHeight, _font, _lines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class LayoutBackground extends WatchUi.Drawable {
    var _color as Graphics.ColorType;

    function initialize(options as { :identifier as Object, :ink as Graphics.ColorType }) {
        Drawable.initialize(options);
        var ink = options[:ink];
        if (ink == null) {
            throw new Lang.UnexpectedTypeException("Layout background requires an ink color", null, null);
        }
        _color = ink;
    }

    function draw(dc as Graphics.Dc) as Void {
        dc.setColor(_color, _color);
        dc.clear();
    }
}

class SelectionBox extends WatchUi.Drawable {
    var _color as Graphics.ColorType;
    var target as String;

    function initialize(options as { :identifier as Object, :target as String, :ink as Graphics.ColorType }) {
        var id = options[:identifier];
        var selected = options[:target];
        var ink = options[:ink];
        if (id == null || selected == null || ink == null) {
            throw new Lang.UnexpectedTypeException("Selection box requires an ID, a target and an ink color", null, null);
        }
        Drawable.initialize({:identifier => id});
        target = selected;
        _color = ink;
    }

    function follow(item as LayoutText) as Void {
        setLocation(item.locX - item.measuredWidth / 2, item.locY);
        width = item.measuredWidth;
        height = item.measuredHeight;
    }

    function draw(dc as Graphics.Dc) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(locX, locY, width, height);
    }
}

class LayoutView extends WatchUi.View {
    var fullScreen as Boolean = true;
    var _layoutWidth as Number = 0;
    var _layoutHeight as Number = 0;
    var _items as Array<WatchUi.Drawable> = [];
    var _hidden as Array<WatchUi.Drawable> = [];
    var _rows as Array<Array<LayoutText>> = [];
    var _roundScreen as Boolean;

    function initialize() {
        View.initialize();
        var shape = System.getDeviceSettings().screenShape;
        _roundScreen = shape == System.SCREEN_SHAPE_ROUND || shape == System.SCREEN_SHAPE_SEMI_ROUND;
    }

    function drawable(id as String) as WatchUi.Drawable {
        var item = findDrawableById(id);
        if (item == null) {
            throw new Lang.UnexpectedTypeException("Missing layout drawable: " + id, null, null);
        }
        return item;
    }

    function label(id as String) as LayoutText {
        var item = drawable(id);
        if (!(item instanceof LayoutText)) {
            throw new Lang.UnexpectedTypeException("Layout drawable must be LayoutText: " + id, null, null);
        }
        return item;
    }

    function setLayout(items as Array<WatchUi.Drawable>?) as Void {
        View.setLayout(items);
        _items = items != null ? items : [];
        _hidden = [];
        _rows = [] as Array<Array<LayoutText>>;
        var previous = null as String?;
        for (var i = 0; i < _items.size(); i += 1) {
            var item = _items[i];
            if (item instanceof LayoutText) {
                var group = item.row;
                if (group != null && previous != null && group.equals(previous)) {
                    var lastRow = _rows[_rows.size() - 1] as Array<LayoutText>;
                    lastRow.add(item);
                } else {
                    var newRow = [item] as Array<LayoutText>;
                    _rows.add(newRow);
                }
                previous = group;
            }
        }
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
        arrange(dc);
        // Drawable visibility is unavailable on API 3.1 devices.
        for (var i = 0; i < _items.size(); i += 1) {
            var item = _items[i];
            if (_hidden.indexOf(item) < 0) {
                item.draw(dc);
            }
        }
    }

    function arrange(dc as Graphics.Dc) as Void {
        var rows = [] as Array<Array<LayoutText>>;
        for (var i = 0; i < _rows.size(); i += 1) {
            var visible = [] as Array<LayoutText>;
            for (var j = 0; j < _rows[i].size(); j += 1) {
                var item = _rows[i][j];
                if (_hidden.indexOf(item) < 0) {
                    visible.add(item);
                }
            }
            if (visible.size() > 0) {
                rows.add(visible);
            }
        }
        if (rows.size() == 0) {
            return;
        }
        var availableWidth = dc.getWidth();
        var availableHeight = dc.getHeight();
        var margin = fullScreen ? Theme.SCREEN_MARGIN : Theme.MENU_MARGIN;
        availableWidth -= margin * 2;
        availableHeight -= margin * 2;
        var heights = [] as Array<Number>;
        var widths = [] as Array<Number>;
        var contentHeight = 0;
        var fits = false;
        var gap = 0;
        for (var attempt = 0; attempt < 2; attempt += 1) {
            heights = [] as Array<Number>;
            widths = [] as Array<Number>;
            contentHeight = 0;
            fits = true;
            for (var i = 0; i < rows.size(); i += 1) {
                var rowHeight = 0;
                var rowWidth = Theme.ROW_GAP * (rows[i].size() - 1);
                for (var j = 0; j < rows[i].size(); j += 1) {
                    var item = rows[i][j];
                    item.measure(dc, availableWidth, attempt == 1);
                    if (item.measuredHeight > rowHeight) {
                        rowHeight = item.measuredHeight;
                    }
                    rowWidth += item.measuredWidth;
                }
                heights.add(rowHeight);
                widths.add(rowWidth);
                contentHeight += rowHeight;
                fits = fits && rowWidth <= availableWidth;
            }
            fits = fits && contentHeight <= availableHeight;
            if (fits) {
                var spacing = fittingGap(dc, widths, heights, contentHeight, availableHeight);
                fits = spacing != null;
                if (spacing != null) {
                    gap = spacing;
                    break;
                }
            }
        }
        if (!fits) {
            throw new Lang.UnexpectedTypeException("Layout content does not fit the available screen area (" +
                dc.getWidth().toString() + "x" + dc.getHeight().toString() +
                ", content height " + contentHeight.toString() + ")", null, null);
        }
        var totalHeight = contentHeight + gap * (rows.size() - 1);
        var y = (dc.getHeight() - totalHeight) / 2;
        for (var i = 0; i < rows.size(); i += 1) {
            var x = (dc.getWidth() - widths[i]) / 2;
            for (var j = 0; j < rows[i].size(); j += 1) {
                var item = rows[i][j];
                item.setLocation(x + item.measuredWidth / 2, y + (heights[i] - item.measuredHeight) / 2);
                x += item.measuredWidth + Theme.ROW_GAP;
            }
            y += heights[i] + gap;
        }
        for (var i = 0; i < _items.size(); i += 1) {
            var item = _items[i];
            if (item instanceof SelectionBox && _hidden.indexOf(item) < 0) {
                var selected = label(item.target);
                if (_hidden.indexOf(selected) >= 0) {
                    throw new Lang.UnexpectedTypeException("Selection target is hidden: " + item.target, null, null);
                }
                item.follow(selected);
            }
        }
    }

    function fittingGap(dc as Graphics.Dc, widths as Array<Number>, heights as Array<Number>,
                        contentHeight as Number, availableHeight as Number) as Number? {
        var maximumGap = 0;
        if (heights.size() > 1) {
            maximumGap = ((availableHeight - contentHeight) / (heights.size() - 1)).toNumber();
            if (maximumGap > Theme.STACK_GAP) {
                maximumGap = Theme.STACK_GAP;
            }
        }
        for (var gap = maximumGap; gap >= 0; gap -= 1) {
            var totalHeight = contentHeight + gap * (heights.size() - 1);
            var y = (dc.getHeight() - totalHeight) / 2;
            var fits = true;
            for (var i = 0; i < heights.size(); i += 1) {
                if (widths[i] > availableRowWidth(dc, y, heights[i])) {
                    fits = false;
                    break;
                }
                y += heights[i] + gap;
            }
            if (fits) {
                return gap;
            }
        }
        return null;
    }

    function availableRowWidth(dc as Graphics.Dc, y as Numeric, height as Number) as Number {
        var margin = fullScreen ? Theme.SCREEN_MARGIN : Theme.MENU_MARGIN;
        if (!fullScreen || !_roundScreen) {
            return dc.getWidth() - margin * 2;
        }
        var halfWidth = dc.getWidth() / 2.0 - margin;
        var halfHeight = dc.getHeight() / 2.0 - margin;
        var top = y - dc.getHeight() / 2.0;
        var bottom = y + height - dc.getHeight() / 2.0;
        top = top < 0 ? -top : top;
        bottom = bottom < 0 ? -bottom : bottom;
        var distance = top > bottom ? top : bottom;
        if (halfHeight <= 0 || distance >= halfHeight) {
            return 0;
        }
        // Each row uses the chord at its outermost edge, not one small rectangle for the whole screen.
        var ratio = distance / halfHeight;
        return (2 * halfWidth * Math.sqrt(1 - ratio * ratio)).toNumber();
    }
}
