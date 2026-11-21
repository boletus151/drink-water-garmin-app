class DaysMenu extends BaseSettingsMenu {
    function initialize() {
        BaseSettingsMenu.initialize(true);
        _count = 7;
        var names = [Rez.Strings.Monday, Rez.Strings.Tuesday, Rez.Strings.Wednesday,
                     Rez.Strings.Thursday, Rez.Strings.Friday, Rez.Strings.Saturday, Rez.Strings.Sunday];
        for (var i = 0; i < 7; i += 1) {
            addSetting("day" + (i + 1).toString(), names[i]);
        }
    }
}
