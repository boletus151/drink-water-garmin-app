import Toybox.Graphics;

class DigitEditor {
    var _digits as DigitController;

    function initialize(editor as DigitController) {
        _digits = editor;
    }

    function update(view as LayoutView) as Void {
        view.label("title").setText(_digits.title);
        for (var i = 0; i < _digits.places.size(); i += 1) {
            var selected = i == _digits.activeDigit;
            var digit = (_digits.value / _digits.places[i]).toNumber() % 10;
            var item = view.label("digit" + i.toString());
            item.setText(digit.toString());
            item.setColor(selected ? Theme.BACKGROUND : Theme.TEXT);
            item.setBackgroundColor(selected ? Theme.ACCENT : Graphics.COLOR_TRANSPARENT);
        }
        var message = _digits.error;
        view.label("range").setText(message != null ? message : text(_digits.rangeId));
        view.label("range").setColor(message != null ? Theme.WARNING : Theme.MUTED);
        view.label("confirmHint").setText(text(_digits.activeDigit < _digits.places.size() - 1 ?
            Rez.Strings.NextDigitHint : Rez.Strings.SaveHint));
    }
}
