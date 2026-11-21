import Toybox.Graphics;

class ServingView extends LayoutView {
    var _controller as ServingController;
    var _editor as NumberEditor;

    function initialize(controller as ServingController) {
        LayoutView.initialize();
        _controller = controller;
        _editor = new NumberEditor(controller);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setEditorLayout(Rez.Layouts.ServingLayout(dc), dc, [["value"], ["range"]]);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        _editor.update(self);
        var error = _controller.error;
        label("range").setText(error != null ? error : text(Rez.Strings.ServingRange));
        label("range").setColor(error != null ? Theme.WARNING : Theme.MUTED);
        drawLayout(dc);
    }
}
