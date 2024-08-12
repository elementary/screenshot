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

    private static bool area = false;
    private static bool clipboard = false;
    private static bool grab_pointer = false;
    private static bool redact = false;
    private static bool screen = false;
    private static bool win = false;
    private static int delay = 1;

    private Settings settings = new Settings ("io.elementary.screenshot");

    private Gdk.Pixbuf? pixbuf;

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
        { "clipboard", 'c', 0, OptionArg.NONE, ref clipboard, CLIPBOARD, null },
        { null }
    };

    public Application () {
        Object (
            application_id: "io.elementary.screenshot",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (GETTEXT_PACKAGE);

        add_main_option_entries (OPTION_ENTRIES);
    }

    protected override void startup () {
        base.startup ();

        Hdy.init ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == DARK;
        });

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            quit ();
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q", "Escape"});

        hold ();
    }

    protected override void activate () {
        var action = 0;
        if (screen) action = 1;
        if (win) action = 2;
        if (area) action = 3;

        if (action == 0) {
            take_screenshot.begin ();
        } else {
            take_screenshot_backend.begin (action - 1);
        }
    }

    private async void take_screenshot () {
        var portal = new Xdp.Portal ();

        try {
            var file_uri = yield portal.take_screenshot (null, INTERACTIVE, null);

            pixbuf = new Gdk.Pixbuf.from_file (Filename.from_uri (file_uri, null));

            show_save_dialog ();
        } catch (Error e) {
            warning ("Failed to take screenshot via portal: %s", e.message);
        } finally {
            release ();
        }
    }

    private async void take_screenshot_backend (CaptureType capture_type) {
        var backend = new ScreenshotBackend ();

        try {
            pixbuf = yield backend.capture (capture_type, delay, grab_pointer, redact);

            if (pixbuf != null) {
                show_save_dialog ();
            }
        } catch (GLib.IOError.CANCELLED e) {
            //Do nothing
        } catch (Error e) {
            show_error_dialog (e.message);
        } finally {
            release ();
        }
    }

    private void show_save_dialog () {
        var save_dialog = new SaveDialog (pixbuf, settings);
        save_dialog.set_application (this);

        save_dialog.save_response.connect ((dialog, response, folder_dir, output_name, format) => {
            dialog.destroy ();

            if (response) {
                string[] formats = {".png", ".jpg", ".jpeg", ".bmp", ".tiff"};
                string output = output_name;

                foreach (string type in formats) {
                    output = output.replace (type, "");
                }

                try {
                    save_file (output, format, folder_dir);
                } catch (GLib.Error e) {
                    show_error_dialog (e.message);
                }
            } else {
                take_screenshot.begin ();
            }
        });

        save_dialog.present ();
    }

    private void save_file (string file_name, string format, owned string folder_dir) throws GLib.Error {
        if (pixbuf == null) {
            critical ("Pixbuf is null");
            return;
        }

        string full_file_name = "";
        string folder_from_settings = "";

        if (folder_dir == "") {
            folder_from_settings = settings.get_string ("folder-dir");
            if (folder_from_settings != "") {
                folder_dir = folder_from_settings;
            } else {
                folder_dir = GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES)
                    + "%c".printf (GLib.Path.DIR_SEPARATOR) + Application.SAVE_FOLDER;
            }
            create_dir_if_missing (folder_dir);
        }

        int attempt = 0;

        do {
            if (attempt == 0) {
                full_file_name = Path.build_filename (folder_dir, "%s.%s".printf (file_name, format));
            } else {
                full_file_name = Path.build_filename (folder_dir, "%s (%d).%s".printf (file_name, attempt, format));
            }

            attempt++;
        } while (File.new_for_path (full_file_name).query_exists ());

        pixbuf.save (full_file_name, format);
    }

    private void show_error_dialog (string error_message) {
        var dialog = new Granite.MessageDialog.with_image_from_icon_name (
             _("Could not capture screenshot"),
             _("Image not saved"),
             "dialog-error",
             Gtk.ButtonsType.CLOSE
        );
        dialog.set_application (this);
        dialog.show_error_details (error_message);
        dialog.response.connect (dialog.destroy);
        dialog.present ();
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
