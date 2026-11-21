import Toybox.Graphics;

class TimeView extends LayoutView {
    var _editor as DigitEditor;

    function initialize(editor as TimeController) {
        LayoutView.initialize();
        _editor = new DigitEditor(editor);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.TimeLayout(dc));
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        _editor.update(self);
        drawLayout(dc);
    }
}
