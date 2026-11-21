import Toybox.Graphics;

class TimeView extends DigitView {
    function initialize(editor as TimeController) {
        DigitView.initialize(editor);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(controller.key.equals("startTime") ? Rez.Layouts.StartTimeLayout(dc) : Rez.Layouts.EndTimeLayout(dc));
    }
}
