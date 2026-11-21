import Toybox.WatchUi;

class DaysMenu extends WatchUi.CustomMenu {
    var _list as SettingsList;

    function initialize() {
        var itemHeight = SettingsList.itemHeight();
        CustomMenu.initialize(itemHeight, Theme.BACKGROUND, {
            :focusItemHeight => itemHeight + Theme.MENU_FOCUS_PADDING * 2,
            :title => new SettingsTitle(true)
        });
        _list = new SettingsList();
        var names = [Rez.Strings.Monday, Rez.Strings.Tuesday, Rez.Strings.Wednesday,
                     Rez.Strings.Thursday, Rez.Strings.Friday, Rez.Strings.Saturday, Rez.Strings.Sunday];
        for (var i = 0; i < 7; i += 1) {
            _list.addSetting(self, "day" + (i + 1).toString(), names[i]);
        }
    }

    function refresh() as Void {
        _list.refresh(self);
    }

    function onShow() as Void {
        refresh();
    }
}
