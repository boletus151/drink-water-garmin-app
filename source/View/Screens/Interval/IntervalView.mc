import Toybox.Graphics;

class IntervalView extends LayoutView {
    var _editor as DigitEditor;

    function initialize(editor as IntervalController) {
        LayoutView.initialize();
        _editor = new DigitEditor(editor);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setEditorLayout(Rez.Layouts.IntervalLayout(dc), dc, [["digit0", "digit1"], ["range"]]);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        _editor.update(self);
        drawLayout(dc);
    }
}
