import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class SettingsMenu extends WatchUi.CustomMenu {
    var _list as SettingsList;
    var _record as SettingsItem;
    var _header as SettingsTitle;
    var _feedbackTimer as Timer.Timer;

    function initialize() {
        var itemHeight = SettingsList.itemHeight();
        _header = new SettingsTitle(false);
        _feedbackTimer = new Timer.Timer();
        CustomMenu.initialize(itemHeight, Theme.BACKGROUND, {
            :focusItemHeight => itemHeight + Theme.MENU_FOCUS_PADDING * 2,
            :title => _header
        });
        _list = new SettingsList();
        _record = new SettingsItem(text(Rez.Strings.RecordIntake), null, "recordIntake");
        addItem(_record);
        _list.addSetting(self, "enabled", Rez.Strings.AppName);
        _list.addSetting(self, "goalMl", Rez.Strings.Goal);
        _list.addSetting(self, "servingMl", Rez.Strings.Serving);
        _list.addSetting(self, "intervalMinutes", Rez.Strings.Interval);
        _list.addSetting(self, "startTime", Rez.Strings.StartHour);
        _list.addSetting(self, "endTime", Rez.Strings.EndHour);
        addItem(new SettingsItem(text(Rez.Strings.Days), null, "days"));
    }

    function refresh() as Void {
        _list.refresh(self);
        _record.setSubLabel(Config.read().servingMl.toString() + " ml");
    }

    function onShow() as Void {
        refresh();
    }

    function setIntakeFeedback(active as Boolean) as Void {
        setBackgroundColor(active ? Theme.INTAKE_FEEDBACK : Theme.BACKGROUND);
        _header.intakeFeedback = active;
        var i = 0;
        var item = getItem(i);
        while (item != null) {
            if (item instanceof SettingsItem) {
                item.intakeFeedback = active;
            }
            i += 1;
            item = getItem(i);
        }
    }

    function flashIntake() as Void {
        _feedbackTimer.stop();
        if (_record.intakeFeedback) {
            // Leave a visible gap when another serving is recorded during the flash.
            setIntakeFeedback(false);
            WatchUi.requestUpdate();
            _feedbackTimer.start(method(:showIntakeFeedback), 60, false);
        } else {
            showIntakeFeedback();
        }
    }

    function showIntakeFeedback() as Void {
        setIntakeFeedback(true);
        WatchUi.requestUpdate();
        _feedbackTimer.start(method(:finishIntakeFeedback), 350, false);
    }

    function finishIntakeFeedback() as Void {
        setIntakeFeedback(false);
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        _feedbackTimer.stop();
        setIntakeFeedback(false);
    }
}
