/*
* Copyright 2017-2020 elementary, Inc. (https://elementary.io)
*           2014-2016 Fabio Zaramella <ffabio.96.x@gmail.com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3 as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class Screenshot.ScreenshotApp : Gtk.Application {
    private ScreenshotWindow window = null;

    private int delay = 1;
    private bool grab_pointer = false;
    private bool screen = false;
    private bool win = false;
    private bool area = false;
    private bool redact = false;
    private bool clipboard = false;

    public const string SAVE_FOLDER = _("Screenshots");

    public ScreenshotApp () {
        Object (
            application_id: "io.elementary.screenshot-tool",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        var options = new OptionEntry[7];
        options[0] = { "window", 'w', 0, OptionArg.NONE, ref win, _("Capture active window"), null };
        options[1] = { "area", 'r', 0, OptionArg.NONE, ref area, _("Capture area"), null };
        options[2] = { "screen", 's', 0, OptionArg.NONE, ref screen, _("Capture the whole screen"), null };
        options[3] = { "delay", 'd', 0, OptionArg.INT, ref delay, _("Take screenshot after specified delay"), _("Seconds")};
        options[4] = { "grab-pointer", 'p', 0, OptionArg.NONE, ref grab_pointer, _("Include the pointer with the screenshot"), null };
        options[5] = { "redact", 'e', 0, OptionArg.NONE, ref redact, _("Redact system text"), null };
        options[6] = { "clipboard", 'c', 0, OptionArg.NONE, ref clipboard, _("Save screenshot to clipboard"), null };

        add_main_option_entries (options);
    }

    protected override void activate () {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/screenshot");

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        var action = 0;
        if (screen) action = 1;
        if (win) action = 2;
        if (area) action = 3;

        if (action == 0) {
            if (window == null) {
                window = new ScreenshotWindow ();
                window.get_style_context ().add_class ("rounded");
                window.set_application (this);
                window.show_all ();
            }

            window.present ();
        } else {
            window = new ScreenshotWindow.from_cmd (action, delay, grab_pointer, redact, clipboard);
            window.set_application (this);
            window.take_clicked ();
        }

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (window != null) {
                window.destroy ();
            }
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q", "Escape"});
    }

    public static void create_dir_if_missing (string path) {
        if (!File.new_for_path (path).query_exists ()) {
            try {
                File file = File.new_for_path (path);
                file.make_directory ();
            } catch (Error e) {
                debug (e.message);
            }
        }
    }

    public static int main (string[] args) {
        return new ScreenshotApp ().run (args);
    }
}
