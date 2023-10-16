/*
* Copyright 2017–2020 elementary, Inc. (https://elementary.io)
*           2014–2016 Fabio Zaramella <ffabio.96.x@gmail.com>
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

public class Screenshot.ScreenshotWindow : Hdy.ApplicationWindow {
    public bool to_clipboard { get; construct; }
    public bool close_on_save { get; set; }
    public bool mouse_pointer { get; set; }
    public bool redact { get; set; }

    private Settings settings;
    private CaptureType capture_mode;
    private bool from_command;
    private int delay;
    private ScreenshotBackend backend;
    private Gtk.Image all_image;
    private Gtk.Label pointer_label;
    private Gtk.Switch pointer_switch;

    public ScreenshotWindow () {
        Object (
            resizable: false,
            to_clipboard: false
        );
    }

    public ScreenshotWindow.from_cmd (int action, int delay, bool grab_pointer, bool redact, bool clipboard) {
        Object (
            to_clipboard: clipboard
        );

        close_on_save = true;
        from_command = true;
        mouse_pointer = grab_pointer;
        this.delay = int.max (0, delay);
        this.redact = redact;

        switch (action) {
            case 1:
                capture_mode = CaptureType.SCREEN;
                break;
            case 2:
                capture_mode = CaptureType.CURRENT_WINDOW;
                break;
            case 3:
                capture_mode = CaptureType.AREA;
                break;
        }
    }

    construct {
        if (from_command) {
            return;
        }

        backend = new ScreenshotBackend ();

        all_image = new Gtk.Image.from_icon_name ("grab-screen-symbolic", DND);

        var all = new Gtk.RadioButton (null) {
            tooltip_text = _("Grab the whole screen")
        };
        all.image = all_image;

        var curr_image = new Gtk.Image.from_icon_name ("grab-window-symbolic", DND);

        var curr_window = new Gtk.RadioButton.from_widget (all) {
            tooltip_text = _("Grab the current window")
        };
        curr_window.image = curr_image;

        var selection_image = new Gtk.Image.from_icon_name ("grab-area-symbolic", DND);

        var selection = new Gtk.RadioButton.from_widget (curr_window) {
            tooltip_text = _("Select area to grab")
        };
        selection.image = selection_image;

        pointer_label = new Gtk.Label (_("Grab pointer:")) {
            halign = END
        };

        pointer_switch = new Gtk.Switch () {
            halign = START
        };

        var close_label = new Gtk.Label (_("Close after saving:")) {
            halign = END
        };

        var close_switch = new Gtk.Switch () {
            halign = START
        };

        var redact_label = new Gtk.Label (_("Conceal text:")) {
            halign = END
        };

        var redact_switch = new Gtk.Switch () {
            halign = START
        };

        var delay_label = new Gtk.Label (_("Delay in seconds:"));
        delay_label.halign = Gtk.Align.END;

        var delay_spin = new Gtk.SpinButton.with_range (0, 15, 1);

        var take_btn = new Gtk.Button.with_label (_("Take Screenshot"));
        take_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        take_btn.can_default = true;

        this.set_default (take_btn);

        var close_btn = new Gtk.Button.with_label (_("Close"));

        var radio_box = new Gtk.Box (HORIZONTAL, 18) {
            halign = CENTER
        };
        radio_box.add (all);
        radio_box.add (curr_window);
        radio_box.add (selection);

        var option_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        option_grid.attach (pointer_label, 0, 0);
        option_grid.attach (pointer_switch, 1, 0);
        option_grid.attach (close_label, 0, 1);
        option_grid.attach (close_switch, 1, 1);

        if (backend.can_conceal_text) {
            option_grid.attach (redact_label, 0, 2);
            option_grid.attach (redact_switch, 1, 2);
        }

        option_grid.attach (delay_label, 0, 3);
        option_grid.attach (delay_spin, 1, 3);

        var actions = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            homogeneous = true
        };
        actions.add (close_btn);
        actions.add (take_btn);

        var box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 24,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        box.add (radio_box);
        box.add (option_grid);
        box.add (actions);

        var window_handle = new Hdy.WindowHandle () {
            child = box
        };

        child = window_handle;

        settings = new Settings ("io.elementary.screenshot");
        settings.bind ("mouse-pointer", pointer_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind ("mouse-pointer", this, "mouse-pointer", GLib.SettingsBindFlags.DEFAULT);
        settings.bind ("close-on-save", close_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind ("close-on-save", this, "close-on-save", GLib.SettingsBindFlags.DEFAULT);
        settings.bind ("delay", delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);
        settings.bind ("redact", redact_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind ("redact", this, "redact", GLib.SettingsBindFlags.DEFAULT);

        switch (settings.get_enum ("last-capture-mode")) {
            case 1:
                capture_mode = CaptureType.CURRENT_WINDOW;
                curr_window.active = true;
                break;
            case 2:
                capture_mode = CaptureType.AREA;
                selection.active = true;
                break;
            default:
                capture_mode = CaptureType.SCREEN;
        }

        update_pointer_switch ();

        all.toggled.connect (() => {
            capture_mode = CaptureType.SCREEN;
            settings.set_enum ("last-capture-mode", capture_mode);
            update_pointer_switch ();
        });

        curr_window.toggled.connect (() => {
            capture_mode = CaptureType.CURRENT_WINDOW;
            settings.set_enum ("last-capture-mode", capture_mode);
            update_pointer_switch ();
        });

        selection.toggled.connect (() => {
            capture_mode = CaptureType.AREA;
            settings.set_enum ("last-capture-mode", capture_mode);
            update_pointer_switch ();
            present ();
        });

        delay_spin.value_changed.connect (() => {
            delay = delay_spin.get_value_as_int ();
        });
        delay = delay_spin.get_value_as_int ();

        take_btn.clicked.connect (take_clicked);
        close_btn.clicked.connect (() => {
            destroy ();
        });

        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.notify["gtk-application-prefer-dark-theme"].connect (() => {
            update_icons (gtk_settings.gtk_application_prefer_dark_theme);
        });

        update_icons (gtk_settings.gtk_application_prefer_dark_theme);
    }

    private void update_icons (bool prefers_dark) {
        if (prefers_dark) {
            all_image.icon_name = "grab-screen-symbolic-dark";
        } else {
            all_image.icon_name = "grab-screen-symbolic";
        }
    }

    private void update_pointer_switch () {
        var sensitive = backend.can_screenshot_area_with_cursor || capture_mode != CaptureType.AREA;
        pointer_label.sensitive = sensitive;
        pointer_switch.sensitive = sensitive;
    }

    private void save_file (string file_name, string format, owned string folder_dir, Gdk.Pixbuf screenshot) throws GLib.Error {
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
            Application.create_dir_if_missing (folder_dir);
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

        screenshot.save (full_file_name, format);
    }

    private void save_pixbuf (Gdk.Pixbuf screenshot) {
        if (from_command == false) {
            var save_dialog = new Screenshot.SaveDialog (screenshot, settings, this);
            save_dialog.save_response.connect ((response, folder_dir, output_name, format) => {
                save_dialog.destroy ();

                if (response) {
                    string[] formats = {".png", ".jpg", ".jpeg", ".bmp", ".tiff"};
                    string output = output_name;

                    foreach (string type in formats) {
                        output = output.replace (type, "");
                    }

                    try {
                        save_file (output, format, folder_dir, screenshot);

                        if (close_on_save) {
                            this.destroy ();
                        }
                    } catch (GLib.Error e) {
                        show_error_dialog (e.message);
                    }
                }
            });

            save_dialog.close.connect (() => {
                if (close_on_save) {
                    this.destroy ();
                }
            });

            save_dialog.present ();
        } else {
            if (to_clipboard) {
                Gtk.Clipboard.get_default (this.get_display ()).set_image (screenshot);
            } else {
                var date_time = new GLib.DateTime.now_local ().format ("%Y-%m-%d %H.%M.%S");

                /// TRANSLATORS: %s represents a timestamp here
                string file_name = _("Screenshot from %s").printf (date_time);
                string format = settings.get_string ("format");
                try {
                    save_file (file_name, format, "", screenshot);
                } catch (GLib.Error e) {
                    show_error_dialog (e.message);
                }
            }
            this.destroy ();
        }
    }

    public void take_clicked () {
        hide ();

        backend.capture.begin (capture_mode, delay, mouse_pointer, redact, (obj, res) => {
            Gdk.Pixbuf? pixbuf = null;
            try {
                pixbuf = backend.capture.end (res);
            } catch (GLib.IOError.CANCELLED e) {
                if (close_on_save) {
                    this.destroy ();
                    return;
                }
            } catch (Error e) {
                show_error_dialog (e.message);
            }

            if (pixbuf != null) {
                save_pixbuf (pixbuf);
            }

            if (from_command == false) {
                present ();
            }
        });
    }

    private void show_error_dialog (string error_message) {
        var dialog = new Granite.MessageDialog.with_image_from_icon_name (
             _("Could not capture screenshot"),
             _("Image not saved"),
             "dialog-error",
             Gtk.ButtonsType.CLOSE
        );
        dialog.show_error_details (error_message);
        dialog.response.connect (destroy);
        dialog.present ();
    }
}
