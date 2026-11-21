import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

typedef StackTextOptions as {
    :identifier as Object,
    :text as String or ResourceId,
    :font as Graphics.FontType,
    :color as Graphics.ColorType,
    :backgroundColor as Graphics.ColorType,
    :justification as Number,
    :locX as Numeric,
    :locY as Numeric
};

class StackText extends WatchUi.Text {
    var _stackFont as Graphics.FontType;
    var _stackText as String;
    var measuredWidth as Number = 0;
    var measuredHeight as Number = 0;

    function initialize(options as StackTextOptions) {
        Text.initialize(options);
        var font = options[:font];
        var value = options[:text];
        if (font == null || value == null) {
            throw new Lang.InvalidOptionsException("StackText requires font and text");
        }
        _stackFont = font;
        _stackText = value instanceof String ? value : WatchUi.loadResource(value).toString();
        setJustification(Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function setText(value as String or ResourceId) as Void {
        _stackText = value instanceof String ? value : WatchUi.loadResource(value).toString();
        Text.setText(value);
    }

    function setFont(font as Graphics.FontType) as Void {
        _stackFont = font;
        Text.setFont(font);
    }

    function measure(dc as Graphics.Dc, availableWidth as Number) as Void {
        if (availableWidth <= 0) {
            throw new Lang.InvalidValueException("Vertical layout requires positive text width");
        }
        var fitted = Graphics.fitTextToArea(_stackText, _stackFont, availableWidth,
            Graphics.getFontHeight(_stackFont) * (_stackText.length() + 1), false);
        if (fitted == null) {
            throw new Lang.InvalidValueException("Text cannot fit in vertical layout: " + _stackText);
        }
        var dimensions = dc.getTextDimensions(fitted, _stackFont);
        measuredWidth = dimensions[0];
        measuredHeight = dimensions[1];
        Text.setText(fitted);
    }
}
