import Toybox.Graphics;

class GoalView extends NumberView {
    function initialize(editor as GoalController) {
        NumberView.initialize(editor);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.GoalLayout(dc));
    }
}
