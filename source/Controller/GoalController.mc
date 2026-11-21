import Toybox.Lang;

class GoalController extends NumberController {
    function initialize(label as String, initial as Number) {
        NumberController.initialize("goalMl", label, initial, 50, 10000, 50);
    }
}
