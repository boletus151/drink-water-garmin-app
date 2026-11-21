class NumberEditor {
    var _controller as NumberController;

    function initialize(controller as NumberController) {
        _controller = controller;
    }

    function update(view as LayoutView) as Void {
        view.label("title").setText(_controller.title);
        view.label("value").setText(_controller.value.toString());
    }
}
