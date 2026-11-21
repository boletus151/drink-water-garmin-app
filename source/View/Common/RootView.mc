import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

function waterApp() as DrinkWaterApp {
    return Application.getApp() as DrinkWaterApp;
}

function clockText(minute as Number) as String {
    return (minute / 60).toNumber().format("%02d") + ":" + (minute % 60).format("%02d");
}

class RootView extends LayoutView {
    var controller as RootController;

    function initialize(input as RootController) {
        LayoutView.initialize();
        controller = input;
    }

    function onShow() as Void {
        waterApp().visibleRoot = self;
        waterApp().refreshRootView();
    }

    function onHide() as Void {
        waterApp().visibleRoot = null;
    }

}
