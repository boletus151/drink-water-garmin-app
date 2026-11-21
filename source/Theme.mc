import Toybox.Graphics;
import Toybox.Lang;

module Theme {
    const BACKGROUND = 0x000000;
    const TEXT = 0xFFFFFF;
    const MUTED = 0xAAAAAA;
    const ACCENT = 0x55FFFF;
    const FOCUS = 0x000055;
    const WARNING = 0xFFAA55;
    const MENU_ITEM_HEIGHT = 62;
    const MENU_FOCUS_HEIGHT = 68;

    function clear(dc as Graphics.Dc) as Void {
        dc.setColor(TEXT, BACKGROUND);
        dc.clear();
    }

    function color(dc as Graphics.Dc, foreground as Number) as Void {
        dc.setColor(foreground, BACKGROUND);
    }

    function title(dc as Graphics.Dc, y as Number, value as String,
                   verticallyCentered as Boolean) as Void {
        color(dc, ACCENT);
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_SMALL, value,
            Graphics.TEXT_JUSTIFY_CENTER |
            (verticallyCentered ? Graphics.TEXT_JUSTIFY_VCENTER : 0));
    }

    function line(dc as Graphics.Dc, y as Number, value as String, style as Number) as Void {
        color(dc, style);
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_XTINY, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function number(dc as Graphics.Dc, y as Number, value as String) as Void {
        color(dc, TEXT);
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_NUMBER_MILD, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function digit(dc as Graphics.Dc, x as Number, y as Number, width as Number,
                   value as String, selected as Boolean) as Void {
        dc.setColor(selected ? ACCENT : BACKGROUND, BACKGROUND);
        dc.fillRectangle(x - width / 2, y - 3, width, dc.getFontHeight(Graphics.FONT_NUMBER_MILD) + 6);
        dc.setColor(selected ? BACKGROUND : TEXT, selected ? ACCENT : BACKGROUND);
        dc.drawText(x, y, Graphics.FONT_NUMBER_MILD, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function menuItem(dc as Graphics.Dc, label as String?, subLabel as String?,
                      focused as Boolean) as Void {
        var background = focused ? FOCUS : BACKGROUND;
        dc.setColor(TEXT, background);
        dc.clear();
        var center = dc.getWidth() / 2;
        var middle = dc.getHeight() / 2;
        if (label != null) {
            dc.drawText(center, subLabel == null ? middle : middle - 13,
                Graphics.FONT_XTINY, label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (subLabel != null) {
            dc.setColor(focused ? ACCENT : MUTED, background);
            dc.drawText(center, middle + 13, Graphics.FONT_XTINY, subLabel,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
