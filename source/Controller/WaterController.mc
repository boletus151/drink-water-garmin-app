import Toybox.Time;

class WaterController extends BaseWaterController {
    function initialize() {
        BaseWaterController.initialize();
    }

    function nextReminder(config as WaterConfig) as Time.Moment? {
        var earliest = Time.now().add(new Time.Duration(1));
        var nextTime = Schedule.pendingDebug(config, earliest);
        return nextTime != null ? nextTime : Schedule.next(config, earliest);
    }
}
