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

public class Screenshot.Application : Gtk.Application {
    public const string SAVE_FOLDER = _("Screenshots");

    private ScreenshotWindow window = null;

    private static bool area = false;
    private static bool clipboard = false;
    private static bool grab_pointer = false;
    private static bool redact = false;
    private static bool screen = false;
    private static bool win = false;
    private static int delay = 1;

    private const string CAPTURE_AREA = N_("Capture area");
    private const string CAPTURE_STRING = N_("Capture the whole screen");
    private const string CAPTURE_WIN = N_("Capture active window");
    private const string DELAY = N_("Take screenshot after specified delay");
    private const string SECONDS = N_("Seconds");
    private const string INCLUDE_POINTER = N_("Include the pointer with the screenshot");
    private const string REDACT_TEXT = N_("Redact system text");
    private const string CLIPBOARD = N_("Save screenshot to clipboard");

    private const OptionEntry[] OPTION_ENTRIES = {
        { "window", 'w', 0, OptionArg.NONE, ref win, CAPTURE_WIN, null },
        { "area", 'r', 0, OptionArg.NONE, ref area, CAPTURE_AREA, null },
        { "screen", 's', 0, OptionArg.NONE, ref screen, CAPTURE_STRING, null },
        { "delay", 'd', 0, OptionArg.INT, ref delay, DELAY, SECONDS},
        { "grab-pointer", 'p', 0, OptionArg.NONE, ref grab_pointer, INCLUDE_POINTER, null },
        { "redact", 'e', 0, OptionArg.NONE, ref redact, REDACT_TEXT, null },
        { "clipboard", 'c', 0, OptionArg.NONE, ref clipboard, CLIPBOARD, null }
    };

    public Application () {
        Object (
            application_id: "io.elementary.screenshot-tool",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        add_main_option_entries (OPTION_ENTRIES);
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
        if (Posix.mkdir (path, 0775) != 0) {
            var err_no = GLib.errno;
            if (err_no != Posix.EEXIST) {
                debug (GLib.IOError.from_errno (err_no).message);
            }
        }
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
