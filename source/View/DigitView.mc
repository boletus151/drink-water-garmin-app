import Toybox.Graphics;

class DigitView extends NumberView {
    var _digits as DigitController;

    function initialize(editor as DigitController) {
        NumberView.initialize(editor);
        _digits = editor;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        label("title").setText(_digits.title);
        for (var i = 0; i < _digits.places.size(); i += 1) {
            var selected = i == _digits.activeDigit;
            var digit = (_digits.value / _digits.places[i]).toNumber() % 10;
            var item = label("digit" + i.toString());
            item.setText(digit.toString());
            item.setColor(selected ? Theme.BACKGROUND : Theme.TEXT);
            item.setBackgroundColor(selected ? Theme.ACCENT : Graphics.COLOR_TRANSPARENT);
        }
        var message = _digits.error;
        label("range").setText(message != null ? message : text(_digits.rangeId));
        label("range").setColor(message != null ? Theme.WARNING : Theme.MUTED);
        label("confirmHint").setText(text(_digits.activeDigit < _digits.places.size() - 1 ?
            Rez.Strings.NextDigitHint : Rez.Strings.SaveHint));
        drawLayout(dc);
    }
}
