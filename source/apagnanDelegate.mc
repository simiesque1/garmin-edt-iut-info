import Toybox.Lang;
import Toybox.WatchUi;

class apagnanDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new apagnanMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}