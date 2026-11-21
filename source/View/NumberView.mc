import Toybox.Graphics;

class NumberView extends LayoutView {
    var controller as NumberController;

    function initialize(editor as NumberController) {
        LayoutView.initialize();
        controller = editor;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        label("title").setText(controller.title);
        label("value").setText(controller.value.toString());
        drawLayout(dc);
    }
}
