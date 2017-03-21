/***

    Copyright (C) 2014-2016 Fabio Zaramella <ffabio.96.x@gmail.com>
                  2017 elementary LLC.

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses>

***/

namespace Screenshot {

    public class ScreenshotWindow : Gtk.Dialog {

        private enum CaptureType {
            SCREEN,
            CURRENT_WINDOW,
            AREA
        }

        private Settings settings = new Settings ("net.launchpad.screenshot");

        private CaptureType capture_mode;
        private string prev_font_regular;
        private string prev_font_document;
        private string prev_font_mono;

        private bool mouse_pointer;
        private bool from_command;
        private bool close_on_save;
        private bool redact;
        private int delay;
        private bool to_clipboard;

        public ScreenshotWindow () {
            Object (border_width: 6,
                    deletable: false,
                    resizable: false);

            capture_mode = CaptureType.SCREEN;
            mouse_pointer = settings.get_boolean ("mouse-pointer");
            close_on_save = settings.get_boolean ("close-on-save");
            redact = settings.get_boolean ("redact");
            delay = settings.get_int ("delay");
            to_clipboard = false;
        }

        construct {
            if (from_command) {
                return;
            }

            set_keep_above (true);
            stick ();

            var area_label = new Gtk.Label (_("Capture area:"));
            area_label.get_style_context ().add_class ("h4");
            area_label.halign = Gtk.Align.END;

            var all = new Gtk.RadioButton.with_label_from_widget (null, _("Grab the whole screen"));

            var curr_window = new Gtk.RadioButton.with_label_from_widget (all, _("Grab the current window"));

            var selection = new Gtk.RadioButton.with_label_from_widget (curr_window, _("Select area to grab"));

            var prop_label = new Gtk.Label (_("Properties:"));
            prop_label.get_style_context ().add_class ("h4");
            prop_label.halign = Gtk.Align.END;

            var pointer_label = new Gtk.Label (_("Grab mouse pointer:"));
            pointer_label.halign = Gtk.Align.END;

            var pointer_switch = new Gtk.Switch ();
            pointer_switch.halign = Gtk.Align.START;
            settings.bind ("mouse-pointer", pointer_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var close_label = new Gtk.Label (_("Close after saving:"));
            close_label.halign = Gtk.Align.END;

            var close_switch = new Gtk.Switch ();
            close_switch.halign = Gtk.Align.START;
            settings.bind ("close-on-save", close_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var redact_label = new Gtk.Label (_("Conceal text:"));
            redact_label.halign = Gtk.Align.END;

            var redact_switch = new Gtk.Switch ();
            redact_switch.halign = Gtk.Align.START;
            settings.bind ("redact", redact_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var delay_label = new Gtk.Label (_("Delay in seconds:"));
            delay_label.halign = Gtk.Align.END;

            var delay_spin = new Gtk.SpinButton.with_range (1, 15, 1);
            settings.bind ("delay", delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 6;
            grid.column_spacing = 12;
            grid.attach (area_label, 0, 0, 1, 1);
            grid.attach (all, 1, 0, 1, 1);
            grid.attach (curr_window, 1, 1, 1, 1);
            grid.attach (selection, 1, 2, 1, 1);
            grid.attach (prop_label, 0, 3, 1, 1);
            grid.attach (pointer_label, 0, 4, 1, 1);
            grid.attach (pointer_switch, 1, 4, 1, 1);
            grid.attach (close_label, 0, 5, 1, 1);
            grid.attach (close_switch, 1, 5, 1, 1);
            grid.attach (redact_label, 0, 6, 1, 1);
            grid.attach (redact_switch, 1, 6, 1, 1);
            grid.attach (delay_label, 0, 7, 1, 1);
            grid.attach (delay_spin, 1, 7, 1, 1);

            Gtk.Box content = get_content_area () as Gtk.Box;
            content.add (grid);

            var take_btn = new Gtk.Button.with_label (_("Take Screenshot"));
            take_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            take_btn.can_default = true;

            this.set_default (take_btn);

            var cancel_btn = new Gtk.Button.with_label (_("Cancel"));

            Gtk.Box actions = get_action_area () as Gtk.Box;
            actions.margin_top = 12;
            actions.add (cancel_btn);
            actions.add (take_btn);

            all.toggled.connect (() => {
                capture_mode = CaptureType.SCREEN;
            });

            curr_window.toggled.connect (() => {
                capture_mode = CaptureType.CURRENT_WINDOW;
            });

            selection.toggled.connect (() => {
                capture_mode = CaptureType.AREA;
                present ();
            });

            pointer_switch.notify["active"].connect (() => {
                mouse_pointer = pointer_switch.active;
            });

            close_switch.notify["active"].connect (() => {
                close_on_save = close_switch.active;
            });

            redact_switch.notify["active"].connect (() => {
                redact = redact_switch.active;
            });

            delay_spin.value_changed.connect (() => {
                delay = delay_spin.get_value_as_int ();
            });

            take_btn.clicked.connect (take_clicked);
            cancel_btn.clicked.connect (cancel_clicked);
        }

        public ScreenshotWindow.from_cmd (int? action, int? delay, bool? grab_pointer, bool? redact, bool? clipboard) {
            if (delay != null) {
                this.delay = delay;
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
            int scale_factor = win.get_scale_factor ();

            if (capture_mode == CaptureType.AREA) {
                Gdk.Rectangle selection_rect;
                win.get_frame_extents (out selection_rect);

                screenshot = new Gdk.Pixbuf.subpixbuf (Gdk.pixbuf_get_from_window (root, 0, 0, root.get_width (), root.get_height ()),
                                                    selection_rect.x, selection_rect.y, selection_rect.width, selection_rect.height);

                win_rect.x = selection_rect.x;
                win_rect.y = selection_rect.y;
                win_rect.width = selection_rect.width;
                win_rect.height = selection_rect.height;
            } else {
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
                    win.get_device_position (device, out cx, out cy, null);
                    xhot = int.parse (cursor_pixbuf.get_option ("x_hot")); // Left padding in cursor_pixbuf between the margin and the actual pointer
                    yhot = int.parse (cursor_pixbuf.get_option ("y_hot")); // Top padding in cursor_pixbuf between the margin and the actual pointer

                    var cursor_rect = Gdk.Rectangle ();

                    cursor_rect.x = cx + win_rect.x - xhot;
                    cursor_rect.y = cy + win_rect.y - yhot;
                    cursor_rect.width = cursor_pixbuf.get_width ();
                    cursor_rect.height = cursor_pixbuf.get_height ();

                    if (scale_factor > 1) {
                        cursor_rect.x *= scale_factor;
                        cursor_rect.y *= scale_factor;
                        cursor_rect.width *= scale_factor;
                        cursor_rect.height *= scale_factor;
                    }

                    if (win_rect.intersect (cursor_rect, out cursor_rect)) {
                        cursor_pixbuf.composite (screenshot, cursor_rect.x, cursor_rect.y, cursor_rect.width, cursor_rect.height, cursor_rect.x, cursor_rect.y, scale_factor, scale_factor, Gdk.InterpType.BILINEAR, 255);
                    }
                }
            }

            if (redact) {
                redact_text (false);
            }

            play_shutter_sound ("screen-capture", _("Screenshot taken"));

            if (from_command == false) {
                var save_dialog = new Screenshot.Widgets.SaveDialog (screenshot, settings, this);
                save_dialog.save_response.connect ((response, folder_dir, output_name, format) => {
                    save_dialog.destroy ();

                    if (response) {
                        string[] formats = {".png", ".jpg", ".jpeg",".bmp", ".tiff"};
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

        private void save_file (string file_name, string format, string folder_dir, Gdk.Pixbuf screenshot) throws GLib.Error {
            string full_file_name = "";

            if (folder_dir == "") {
                string folder_from_settings = settings.get_string ("folder-dir");
                if (folder_from_settings != "") {
                    folder_dir = folder_from_settings;
                } else {
                    folder_dir = GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES);
                }
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

        private void capture_screen () {
            this.hide ();

            Timeout.add_seconds (delay - (redact ? 1 : 0), () => {
                if (from_command == false) {
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

            this.hide ();
            Timeout.add_seconds (delay - (redact ? 1 : 0), () => {
                list = screen.get_window_stack ();
                foreach (Gdk.Window item in list) {
                    if (screen.get_active_window () == item) {
                        win = item;
                    }

                    // Recieve updates of other windows when they are resized
                    item.set_events (item.get_events () | Gdk.EventMask.STRUCTURE_MASK);
                }

                if (from_command == false) {
                    this.present ();
                }

                if (win != null) {
                    grab_save (win, redact);
                } else {
                    Gtk.MessageDialog dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                                                    Gtk.ButtonsType.CLOSE, _("Could not capture screenshot"));
                    dialog.secondary_text = _("Couldn't find an active window");
                    dialog.deletable = false;
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
            this.hide ();

            selection_area.cancelled.connect (() => {
                selection_area.close ();
                if (close_on_save) {
                    this.destroy ();
                } else {
                    if (from_command == false) {
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
                Timeout.add_seconds (delay - (redact ? 1 : 0), () => {
                    if (from_command == false) {
                        this.present ();
                    }
                    return grab_save (win, redact);
                });
            });
        }

        private void show_error_dialog () {
            var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                                Gtk.ButtonsType.CLOSE, _("Could not capture screenshot"));
            dialog.secondary_text = _("Image not saved");
            dialog.deletable = false;
            dialog.run ();
            dialog.destroy ();
        }

        private void redact_text (bool redact) {
            var settings = new Settings ("org.gnome.desktop.interface");
            if (redact) {
                prev_font_regular = settings.get_string ("font-name");
                prev_font_mono = settings.get_string ("monospace-font-name");
                prev_font_document = settings.get_string ("document-font-name");

                settings.set_string ("font-name", "Redacted Script Regular 9");
                settings.set_string ("monospace-font-name", "Redacted Script Light 10");
                settings.set_string ("document-font-name", "Redacted Script Regular 10");
            } else {
                settings.set_string ("font-name", prev_font_regular);
                settings.set_string ("monospace-font-name", prev_font_mono);
                settings.set_string ("document-font-name", prev_font_document);
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

        private void cancel_clicked () {
            destroy ();
        }
    }
}
