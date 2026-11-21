import Toybox.Graphics;

class IntervalView extends DigitView {
    function initialize(editor as IntervalController) {
        DigitView.initialize(editor);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.IntervalLayout(dc));
    }
}
