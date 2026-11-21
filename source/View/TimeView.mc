import Toybox.Graphics;

class TimeView extends DigitView {
    function initialize(editor as TimeController) {
        DigitView.initialize(editor);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.TimeLayout(dc));
    }
}
