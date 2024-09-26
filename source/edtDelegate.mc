import Toybox.Lang;
import Toybox.WatchUi;

class edtDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new edtMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}