import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class apagnanView extends WatchUi.View {
    hidden var statusMessage = "Loading...";
    hidden var relevantCourses = [];
    hidden var nextCourse = null;

    function initialize() {
        View.initialize();
    }

    // Set up the layout
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    } 

    // Trigger API request when view is shown
    function onShow() {
        makeRequest();
    }

    // Update the display
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (nextCourse != null) {
            var courseInfo = Lang.format("$1$\n$2$\n$3$", [nextCourse["content"]["lesson_from_reference"], nextCourse["content"]["room"], formatDate(nextCourse["start_date"])]);
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_XTINY, courseInfo, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_TINY, statusMessage, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Make API request
    function makeRequest() {
        var url = "https://edt-iut-info-limoges.vercel.app/api/timetable/A1/5";
        var params = {};

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, method(:onReceive));
    }

    // Handle API response
    function onReceive(responseCode as Number, data as Null or Dictionary or String or Toybox.PersistedContent.Iterator) as Void {
        if (responseCode == 200) {
            if (data instanceof Dictionary) {
                var lessons = data["data"]["lessons"];
                if (lessons == null) {
                    System.println("Error: lessons is null");
                    return;
                }

                relevantCourses = [];

                for (var i = 0; i < lessons.size(); i++) {
                    var lesson = lessons[i];
                    if (lesson == null) {
                        System.println("Error: lesson is null at index " + i);
                        continue;
                    }

                    var group = lesson["group"];

                    switch (lesson["type"]) {
                        case "CM":
                            relevantCourses.add(lesson);
                            break;
                        case "TD":
                            if (group["main"] == 2 && !group.hasKey("sub")) {
                                relevantCourses.add(lesson);
                            }
                            break;
                        case "TP":
                            if (group["main"] == 2 && group["sub"] == 1) {
                                relevantCourses.add(lesson);
                            }
                            break;
                    }
                }

                findClosestCourse();
                
                statusMessage = relevantCourses.size().toString() + " courses";
            } else {
                statusMessage = "Unexpected data type";
            }
        } else {
            statusMessage = "Error: " + responseCode.toString();
        }
        WatchUi.requestUpdate();
    }

    // Find the next upcoming course
    function findClosestCourse() {
        var now = Time.now();
        nextCourse = null;

        for (var i = 0; i < relevantCourses.size(); i++) {
            var course = relevantCourses[i];
            var courseTime = parseDate(course["start_date"]);
            
            if (courseTime != null && courseTime.greaterThan(now)) {
                if (nextCourse == null || courseTime.lessThan(parseDate(nextCourse["start_date"]))) {
                    nextCourse = course;
                }
            }
        }

        if (nextCourse != null) {
            System.println("Closest course: " + nextCourse["content"]["lesson_from_reference"] + " at " + nextCourse["start_date"]);
        } else {
            System.println("No upcoming courses found");
        }
    }

    // Parse date string to moment
    function parseDate(dateString) {
        if (dateString == null || dateString.length() < 19) {
            return null;
        }

        var year = dateString.substring(0, 4).toNumber();
        var month = dateString.substring(5, 7).toNumber();
        var day = dateString.substring(8, 10).toNumber();
        var hour = dateString.substring(11, 13).toNumber();
        var minute = dateString.substring(14, 16).toNumber();
        var second = dateString.substring(17, 19).toNumber();

        if (year == null || month == null || day == null || 
            hour == null || minute == null || second == null) {
            return null;
        }

        return Time.Gregorian.moment({
            :year => year,
            :month => month,
            :day => day,
            :hour => hour,
            :minute => minute,
            :second => second
        });
    }

    // Format date for display
    function formatDate(dateString) {
        var moment = parseDate(dateString);
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return Lang.format("$1$:$2$ $3$/$4$", [
            info.hour.format("%02d"),
            info.min.format("%02d"),
            info.day.format("%02d"),
            info.month.format("%02d")
        ]);
    }
}