class SettingsMenu extends BaseSettingsMenu {
    function initialize() {
        BaseSettingsMenu.initialize(false);
        _count = 6;
        addSetting("enabled", Rez.Strings.AppName);
        addSetting("goalMl", Rez.Strings.Goal);
        addSetting("intervalMinutes", Rez.Strings.Interval);
        addSetting("startTime", Rez.Strings.StartHour);
        addSetting("endTime", Rez.Strings.EndHour);
        addItem(new SettingsItem(text(Rez.Strings.Days), null, "days"));
    }
}
