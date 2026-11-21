import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

(:background)
class WaterService extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var config = Config.read();
        var now = Time.now();
        var last = Background.getBackgroundData();
        if (!(last instanceof Number)) {
            last = Storage.getValue("lastReminder");
        }
        var key = null as Number?;
        if (DebugConfig.DEBUG) {
            var target = Background.getLastTemporalEventTime();
            if (!(target instanceof Time.Moment)) {
                System.println("DrinkWater DEBUG: falta la fecha del evento temporal ejecutado");
            } else {
                key = Schedule.debugDueKey(config, now, target.value(), true);
            }
        } else {
            key = Schedule.dueKey(config, now);
        }
        if (key != null && (!(last instanceof Number) || key > last)) {
            Background.requestApplicationWake(text(Rez.Strings.Reminder));
            last = key;
        }
        Schedule.arm(config, now.add(new Time.Duration(1)));
        Background.exit(last instanceof Number ? last : null);
    }
}
