import Toybox.WatchUi;

class SettingsMenu extends WatchUi.CustomMenu {
    var _list as SettingsList;
    var _record as SettingsItem;

    function initialize() {
        var itemHeight = SettingsList.itemHeight();
        CustomMenu.initialize(itemHeight, Theme.BACKGROUND, {
            :focusItemHeight => itemHeight + Theme.MENU_FOCUS_PADDING * 2,
            :title => new SettingsTitle(false)
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
}
