import Toybox.Graphics;

class GoalView extends LayoutView {
    var _editor as NumberEditor;

    function initialize(editor as GoalController) {
        LayoutView.initialize();
        _editor = new NumberEditor(editor);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setEditorLayout(Rez.Layouts.GoalLayout(dc), dc, [["value"]]);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        _editor.update(self);
        drawLayout(dc);
    }
}
