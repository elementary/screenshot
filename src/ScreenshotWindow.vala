/*
* Copyright (c) 2014–2016 Fabio Zaramella <ffabio.96.x@gmail.com>
*               2017–2018 elementary LLC. (https://elementary.io)
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

namespace Screenshot {

    public class ScreenshotWindow : Gtk.ApplicationWindow {

        private enum CaptureType {
            SCREEN,
            CURRENT_WINDOW,
            AREA
        }

        private Settings settings;
        private CaptureType capture_mode;
        private string prev_font_regular;
        private string prev_font_document;
        private string prev_font_mono;
        private bool from_command;
        private int delay;
        private bool to_clipboard;
        private int window_x;
        private int window_y;

        public bool close_on_save { get; set; }
        public bool mouse_pointer { get; set; }
        public bool redact { get; set; }

        public ScreenshotWindow () {
            Object (
                border_width: 6,
                resizable: false
            );

            to_clipboard = false;
        }

        construct {
            if (from_command) {
                return;
            }

            set_keep_above (true);
            stick ();

            var all = new Gtk.RadioButton (null);
            all.image = new Gtk.Image.from_icon_name ("grab-screen-symbolic", Gtk.IconSize.DND);
            all.tooltip_text = _("Grab the whole screen");

            var curr_window = new Gtk.RadioButton.from_widget (all);
            curr_window.image = new Gtk.Image.from_icon_name ("grab-window-symbolic", Gtk.IconSize.DND);
            curr_window.tooltip_text = _("Grab the current window");

            var selection = new Gtk.RadioButton.from_widget (curr_window);
            selection.image = new Gtk.Image.from_icon_name ("grab-area-symbolic", Gtk.IconSize.DND);
            selection.tooltip_text = _("Select area to grab");

            var radio_grid = new Gtk.Grid ();
            radio_grid.halign = Gtk.Align.CENTER;
            radio_grid.column_spacing = 24;
            radio_grid.margin = 24;
            radio_grid.get_style_context ().add_class (Granite.STYLE_CLASS_ACCENT);
            radio_grid.add (all);
            radio_grid.add (curr_window);
            radio_grid.add (selection);

            var pointer_label = new Gtk.Label (_("Grab mouse pointer:"));
            pointer_label.halign = Gtk.Align.END;

            var pointer_switch = new Gtk.Switch ();
            pointer_switch.halign = Gtk.Align.START;

            var close_label = new Gtk.Label (_("Close after saving:"));
            close_label.halign = Gtk.Align.END;

            var close_switch = new Gtk.Switch ();
            close_switch.halign = Gtk.Align.START;

            var redact_label = new Gtk.Label (_("Conceal text:"));
            redact_label.halign = Gtk.Align.END;

            var redact_switch = new Gtk.Switch ();
            redact_switch.halign = Gtk.Align.START;

            var delay_label = new Gtk.Label (_("Delay in seconds:"));
            delay_label.halign = Gtk.Align.END;

            var delay_spin = new Gtk.SpinButton.with_range (0, 15, 1);

            var take_btn = new Gtk.Button.with_label (_("Take Screenshot"));
            take_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            take_btn.can_default = true;

            this.set_default (take_btn);

            var close_btn = new Gtk.Button.with_label (_("Close"));

            var actions = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            actions.halign = Gtk.Align.END;
            actions.margin_top = 24;
            actions.spacing = 6;
            actions.add (close_btn);
            actions.add (take_btn);

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_top = 0;
            grid.row_spacing = 6;
            grid.column_spacing = 12;
            grid.attach (pointer_label, 0, 4, 1, 1);
            grid.attach (pointer_switch, 1, 4, 1, 1);
            grid.attach (close_label, 0, 5, 1, 1);
            grid.attach (close_switch, 1, 5, 1, 1);
            grid.attach (redact_label, 0, 6, 1, 1);
            grid.attach (redact_switch, 1, 6, 1, 1);
            grid.attach (delay_label, 0, 7, 1, 1);
            grid.attach (delay_spin, 1, 7, 1, 1);
            grid.attach (actions, 0, 8, 2, 1);

            var titlebar = new Gtk.HeaderBar ();
            titlebar.has_subtitle = false;
            titlebar.set_custom_title (radio_grid);

            var titlebar_style_context = titlebar.get_style_context ();
            titlebar_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            titlebar_style_context.add_class ("default-decoration");

            set_titlebar (titlebar);
            add (grid);

            settings = new Settings ("io.elementary.screenshot-tool");
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

            all.toggled.connect (() => {
                capture_mode = CaptureType.SCREEN;
                settings.set_enum ("last-capture-mode", capture_mode);
            });

            curr_window.toggled.connect (() => {
                capture_mode = CaptureType.CURRENT_WINDOW;
                settings.set_enum ("last-capture-mode", capture_mode);
            });

            selection.toggled.connect (() => {
                capture_mode = CaptureType.AREA;
                settings.set_enum ("last-capture-mode", capture_mode);
                present ();
            });

            delay_spin.value_changed.connect (() => {
                delay = delay_spin.get_value_as_int ();
            });
            delay = delay_spin.get_value_as_int ();

            take_btn.clicked.connect (take_clicked);
            close_btn.clicked.connect (close_clicked);
        }

        public ScreenshotWindow.from_cmd (int? action, int? delay, bool? grab_pointer, bool? redact, bool? clipboard) {
            if (delay != null) {
                this.delay = int.max (0, delay);
            }

            if (grab_pointer != null) {
                mouse_pointer = grab_pointer;
            }

            if (redact != null) {
                this.redact = redact;
            }

            if (action != null) {
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

            if (clipboard != null) {
                to_clipboard = clipboard;
            }

            close_on_save = true;
            from_command = true;

            this.set_opacity (0);
        }

        private bool grab_save (Gdk.Window? win, bool extra_time) {
            if (extra_time) {
                redact_text (true);
                Timeout.add_seconds (1, () => {
                    return grab_save (win, false);
                });

                return false;
            }

            Timeout.add (250, () => {
                if (from_command == false) {
                    this.set_opacity (1);
                }
                return false;
            });

            var win_rect = Gdk.Rectangle ();
            var root = Gdk.get_default_root_window ();

            if (win == null) {
                win = root;
            }

            Gdk.Pixbuf? screenshot;
            int scale_factor;

            if (capture_mode == CaptureType.AREA) {
                scale_factor = root.get_scale_factor ();
                Gdk.Rectangle selection_rect;
                win.get_frame_extents (out selection_rect);

                screenshot = new Gdk.Pixbuf.subpixbuf (Gdk.pixbuf_get_from_window (root, 0, 0, root.get_width (), root.get_height ()),
                                                    selection_rect.x, selection_rect.y, selection_rect.width, selection_rect.height);

                win_rect.x = selection_rect.x;
                win_rect.y = selection_rect.y;
                win_rect.width = selection_rect.width;
                win_rect.height = selection_rect.height;
            } else {
                scale_factor = win.get_scale_factor ();
                int width = win.get_width ();
                int height = win.get_height ();

                // Check the scaling factor in use, and if greater than 1 scale the image. (for HiDPI displays)
                if (scale_factor > 1 && capture_mode == CaptureType.SCREEN) {
                    screenshot = Gdk.pixbuf_get_from_window (win, 0, 0, width / scale_factor, height / scale_factor);
                    screenshot.scale (screenshot, width, height, width, height, 0, 0, scale_factor, scale_factor, Gdk.InterpType.BILINEAR);
                } else {
                    screenshot = Gdk.pixbuf_get_from_window (win, 0, 0, width, height);
                }

                win_rect.x = 0;
                win_rect.y = 0;
                win_rect.width = width;
                win_rect.height = height;
            }

            if (redact) {
                redact_text (false);
            }

            if (screenshot == null) {
                show_error_dialog ();
                return false;
            }

            if (mouse_pointer) {
                var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.LEFT_PTR);
                var cursor_pixbuf = cursor.get_image ();

                if (cursor_pixbuf != null) {
                    var manager = Gdk.Display.get_default ().get_device_manager ();
                    var device = manager.get_client_pointer ();

                    int cx, cy, xhot, yhot;
                    if (capture_mode != CaptureType.AREA) {
                        win.get_device_position (device, out cx, out cy, null);
                    } else {
                        root.get_device_position (device, out cx, out cy, null);
                    }
                    xhot = int.parse (cursor_pixbuf.get_option ("x_hot")); // Left padding in cursor_pixbuf between the margin and the actual pointer
                    yhot = int.parse (cursor_pixbuf.get_option ("y_hot")); // Top padding in cursor_pixbuf between the margin and the actual pointer

                    var cursor_rect = Gdk.Rectangle ();
                    cursor_rect.x = cx - xhot;
                    cursor_rect.y = cy - yhot;
                    cursor_rect.width = cursor_pixbuf.get_width ();
                    cursor_rect.height = cursor_pixbuf.get_height ();

                    if (scale_factor > 1) {
                        cursor_rect.x *= scale_factor;
                        cursor_rect.y *= scale_factor;
                        cursor_rect.width *= scale_factor;
                        cursor_rect.height *= scale_factor;
                    }

                    Gdk.Rectangle cursor_clip;
                    if (win_rect.intersect (cursor_rect, out cursor_clip)) {
                        cursor_rect.x -= win_rect.x;
                        cursor_rect.y -= win_rect.y;
                        cursor_clip.x -= win_rect.x;
                        cursor_clip.y -= win_rect.y;
                        cursor_pixbuf.composite (screenshot, cursor_clip.x, cursor_clip.y, cursor_clip.width, cursor_clip.height, cursor_rect.x, cursor_rect.y, scale_factor, scale_factor, Gdk.InterpType.BILINEAR, 255);
                    }
                }
            }

            play_shutter_sound ("screen-capture", _("Screenshot taken"));

            if (from_command == false) {
                var save_dialog = new Screenshot.Widgets.SaveDialog (screenshot, settings, this);
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
                            show_error_dialog ();
                            debug (e.message);
                        }
                    }
                });

                save_dialog.close.connect (() => {
                    if (close_on_save) {
                        this.destroy ();
                    }
                });

                save_dialog.show_all ();
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
                        show_error_dialog ();
                        debug (e.message);
                    }
                }
                this.destroy ();
            }

            return false;
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
                        + "%c".printf(GLib.Path.DIR_SEPARATOR) + ScreenshotApp.SAVE_FOLDER;
                }
                ScreenshotApp.create_dir_if_missing (folder_dir);
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

        public void take_clicked () {
            this.set_opacity (0);

            switch (capture_mode) {
                case CaptureType.SCREEN:
                    capture_screen ();
                    break;
                case CaptureType.CURRENT_WINDOW:
                    capture_window ();
                    break;
                case CaptureType.AREA:
                    capture_area ();
                    break;
            }
        }

        private int get_timeout(int delay, bool redact) {
            int timeout = delay * 1000;

            if (redact) {
                timeout -= 1000;
            }

            if (timeout < 300) {
                timeout = 300;
            }

            return timeout;
        }

        private void capture_screen () {
            remember_window_position ();
            this.hide ();

            Timeout.add (get_timeout (delay, redact), () => {
                if (from_command == false) {
                    move (window_x, window_y);
                    this.present ();
                }
                return grab_save (null, redact);
            });
        }

        private void capture_window () {
            Gdk.Screen screen = null;
            Gdk.Window win = null;
            GLib.List<Gdk.Window> list = null;

            screen = Gdk.Screen.get_default ();

            remember_window_position ();
            this.hide ();
            Timeout.add (get_timeout (delay, redact), () => {
                list = screen.get_window_stack ();
                foreach (Gdk.Window item in list) {
                    if (screen.get_active_window () == item) {
                        win = item;
                    }

                    // Recieve updates of other windows when they are resized
                    item.set_events (item.get_events () | Gdk.EventMask.STRUCTURE_MASK);
                }

                if (from_command == false) {
                    move (window_x, window_y);
                    this.present ();
                }

                if (win != null) {
                    grab_save (win, redact);
                } else {
                    var dialog = new Granite.MessageDialog.with_image_from_icon_name (
                         _("Could not capture screenshot"),
                         _("Couldn't find an active window"),
                         "dialog-error",
                         Gtk.ButtonsType.CLOSE
                    );

                    dialog.run ();
                    dialog.destroy ();

                    if (from_command == false) {
                        this.set_opacity (1);
                    } else {
                        this.destroy ();
                    }
                }

                return false;
            });
        }

        private void capture_area () {
            var selection_area = new Screenshot.Widgets.SelectionArea ();
            selection_area.show_all ();
            remember_window_position ();
            this.hide ();

            selection_area.cancelled.connect (() => {
                selection_area.close ();
                if (close_on_save) {
                    this.destroy ();
                } else {
                    if (from_command == false) {
                        move (window_x, window_y);
                        this.set_opacity (1);
                        this.present ();
                    }
                }
            });

            var win = selection_area.get_window ();

            selection_area.captured.connect (() => {
                if (delay == 0) {
                    selection_area.set_opacity (0);
                }
                selection_area.close ();
                Timeout.add (get_timeout (delay, redact), () => {
                    if (from_command == false) {
                        move (window_x, window_y);
                        this.present ();
                    }
                    return grab_save (win, redact);
                });
            });
        }

        private void show_error_dialog () {
            var dialog = new Granite.MessageDialog.with_image_from_icon_name (
                 _("Could not capture screenshot"),
                 _("Image not saved"),
                 "dialog-error",
                 Gtk.ButtonsType.CLOSE
            );

            dialog.run ();
            dialog.destroy ();
        }

        private void redact_text (bool redact) {
            var desktop_settings = new Settings ("org.gnome.desktop.interface");
            if (redact) {
                prev_font_regular = desktop_settings.get_string ("font-name");
                prev_font_mono = desktop_settings.get_string ("monospace-font-name");
                prev_font_document = desktop_settings.get_string ("document-font-name");

                desktop_settings.set_string ("font-name", "Redacted Script Regular 9");
                desktop_settings.set_string ("monospace-font-name", "Redacted Script Light 10");
                desktop_settings.set_string ("document-font-name", "Redacted Script Regular 10");
            } else {
                desktop_settings.set_string ("font-name", prev_font_regular);
                desktop_settings.set_string ("monospace-font-name", prev_font_mono);
                desktop_settings.set_string ("document-font-name", prev_font_document);
            }
        }

        private void play_shutter_sound (string id, string desc) {
            Canberra.Context context;
            Canberra.Proplist props;

            Canberra.Context.create (out context);
            Canberra.Proplist.create (out props);

            props.sets (Canberra.PROP_EVENT_ID, id);
            props.sets (Canberra.PROP_EVENT_DESCRIPTION, desc);
            props.sets (Canberra.PROP_CANBERRA_CACHE_CONTROL, "permanent");

            context.play_full (0, props, null);
        }

        private void close_clicked () {
            destroy ();
        }

        // Save main window position so that this position can be used
        // when the window reappears again
        private void remember_window_position () {
            get_position (out window_x, out window_y);
        }
    }
}
