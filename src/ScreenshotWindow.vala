/***

    Copyright (C) 2014-2016 Fabio Zaramella <ffabio.96.x@gmail.com>

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

        /**
         *  UI elements
         */
        private Gtk.Grid grid;
        private Gtk.RadioButton all;
        private Gtk.RadioButton curr_window;
        private Gtk.RadioButton selection;

        private CaptureType capture_mode;
        private string prev_font_regular;
        private string prev_font_document;
        private string prev_font_mono;

        private bool mouse_pointer;
        private bool from_command;
        private bool close_on_save;
        private bool redact;
        private int delay;

        /**
         *  ScreenshotWindow Constructor
         */
        public ScreenshotWindow () {
            resizable = false;
            deletable = false;
            border_width = 6;

			capture_mode = CaptureType.SCREEN;
            mouse_pointer = settings.get_boolean ("mouse-pointer");
            close_on_save = settings.get_boolean ("close-on-save");
            redact = settings.get_boolean ("redact");
            delay = settings.get_int ("delay");

            setup_ui ();
        }

        public ScreenshotWindow.from_cmd (int? action, int? delay, bool? grab_pointer, bool? redact) {
            if (delay != null) {
                this.delay = delay;
            }

            if (grab_pointer != null) {
                mouse_pointer = grab_pointer;
            }

            if (redact != null) {
                this.redact = redact;
            }

            close_on_save = true;
            setup_ui ();

            if (action != null) {
                switch (action) {
                    case 1: this.capture_mode = CaptureType.SCREEN; break;
                    case 2: this.capture_mode = CaptureType.CURRENT_WINDOW; break;
                    case 3: this.capture_mode = CaptureType.AREA;
                        selection.set_active (true);
                    break;
                }
            }

            from_command = true;
        }

        /**
         *  Builds all of the widgets and arranges them in the window
         */
        void setup_ui () {
            window_position = Gtk.WindowPosition.CENTER;
            set_keep_above (true);
            stick ();
        
            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 6;
            grid.column_spacing = 12;

            /* Labels used to distinguish selections */
            var area_label = new Gtk.Label (_("Capture area:"));
            area_label.get_style_context ().add_class ("h4");
            area_label.halign = Gtk.Align.END;

            var prop_label = new Gtk.Label (_("Properties:"));
            prop_label.get_style_context ().add_class ("h4");
            prop_label.halign = Gtk.Align.END;

            /**
             *  Capture area selection
             */
            all = new Gtk.RadioButton.with_label_from_widget (null, _("Grab the whole screen"));

            curr_window = new Gtk.RadioButton.with_label_from_widget (all, _("Grab the current window"));

            selection = new Gtk.RadioButton.with_label_from_widget (curr_window, _("Select area to grab"));

            // Pack first part of the grid
            grid.attach (area_label, 0, 0, 1, 1);
            grid.attach (all, 1, 0, 1, 1);
            grid.attach (curr_window, 1, 1, 1, 1);
            grid.attach (selection, 1, 2, 1, 1);

            /**
             *  Effects area selection
             */
            var pointer_label = new Gtk.Label (_("Grab mouse pointer:"));
            pointer_label.halign = Gtk.Align.END;
            var pointer_switch = new Gtk.Switch ();
            pointer_switch.halign = Gtk.Align.START;

            pointer_switch.set_active (mouse_pointer);

            var close_label = new Gtk.Label (_("Close after saving:"));
            close_label.halign = Gtk.Align.END;
            var close_switch = new Gtk.Switch ();
            close_switch.halign = Gtk.Align.START;

            close_switch.set_active (close_on_save);

            var redact_label = new Gtk.Label (_("Conceal text:"));
            redact_label.halign = Gtk.Align.END;
            var redact_switch = new Gtk.Switch ();
            redact_switch.halign = Gtk.Align.START;

            redact_switch.set_active (redact);

            var delay_label = new Gtk.Label (_("Delay in seconds:"));
            delay_label.halign = Gtk.Align.END;

            var delay_spin = new Gtk.SpinButton.with_range (1, 15, 1);
		    delay_spin.set_value (delay);

            // Pack second part of the grid
            grid.attach (prop_label, 0, 3, 1, 1);
            grid.attach (pointer_label, 0, 4, 1, 1);
            grid.attach (pointer_switch, 1, 4, 1, 1);
            grid.attach (close_label, 0, 5, 1, 1);
            grid.attach (close_switch, 1, 5, 1, 1);
            grid.attach (redact_label, 0, 6, 1, 1);
            grid.attach (redact_switch, 1, 6, 1, 1);
            grid.attach (delay_label, 0, 7, 1, 1);
            grid.attach (delay_spin, 1, 7, 1, 1);

            // Take button
            var take_btn = new Gtk.Button.with_label (_("Take Screenshot"));
            take_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            take_btn.can_default = true;

            this.set_default (take_btn);

            var cancel_btn = new Gtk.Button.with_label (_("Cancel"));

            Gtk.Box actions = get_action_area () as Gtk.Box;
            actions.margin_top = 12;
            actions.add (cancel_btn);
            actions.add (take_btn);

            /**
             *  Signals
             */
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
                settings.set_boolean ("mouse-pointer", pointer_switch.active);
                mouse_pointer = pointer_switch.active;
            });

            close_switch.notify["active"].connect (() => {
                settings.set_boolean ("close-on-save", close_switch.active);
                close_on_save = close_switch.active;
            });

            redact_switch.notify["active"].connect (() => {
                settings.set_boolean ("redact", redact_switch.active);
                redact = redact_switch.active;
            });

            delay_spin.value_changed.connect (() => {
                delay = delay_spin.get_value_as_int ();
                settings.set_int ("delay", delay);
            });

            take_btn.clicked.connect (take_clicked);
            cancel_btn.clicked.connect (cancel_clicked);

            // Pack the main grid into the window
            Gtk.Box content = get_content_area () as Gtk.Box;
            content.add (grid);
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
                this.set_opacity (1);
                return false;
            });

            var win_rect = Gdk.Rectangle ();
            var root = Gdk.get_default_root_window ();

            if (win == null) {
                win = root;
            }

            Gdk.Pixbuf? screenshot;
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

                screenshot = Gdk.pixbuf_get_from_window (win, 0, 0, width, height);

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

                    int cx, cy;
                    win.get_device_position (device, out cx, out cy, null);

                    var cursor_rect = Gdk.Rectangle ();

                    cursor_rect.x = cx + win_rect.x;
                    cursor_rect.y = cy + win_rect.y;
                    cursor_rect.width = cursor_pixbuf.get_width ();
                    cursor_rect.height = cursor_pixbuf.get_height ();

                    if (win_rect.intersect (cursor_rect, out cursor_rect)) {
                        cursor_pixbuf.composite (screenshot, cx, cy, cursor_rect.width, cursor_rect.height, cx, cy, 1.0, 1.0, Gdk.InterpType.BILINEAR, 255);
                    }
                }
            }

            if (redact) {
                redact_text (false);
            }

            var save_dialog = new Screenshot.Widgets.SaveDialog (screenshot, settings, this);
            save_dialog.save_response.connect ((response, folder_dir, output_name, format) => {
                save_dialog.destroy ();

                if (response) {
                    string[] formats = {".png", ".jpg", ".jpeg",".bmp", ".tiff"};
                    string output = output_name;

                    foreach (string type in formats) {
                        output = output.replace (type, "");
                    }

                    string file_name = Path.build_filename (folder_dir, output + "." + format);

                    try {
                        screenshot.save (file_name, format);

                        if (close_on_save) {
                            this.destroy ();
                        }
                    } catch (GLib.Error e) {
                        show_error_dialog ();
                        debug (e.message);
                    }
                }

                if (from_command && close_on_save) {
                    this.destroy ();
                }
            });

            save_dialog.close.connect (() => {
                this.destroy ();
            });

            save_dialog.show_all ();

            return false;
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
                this.present ();
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
                }

                this.present ();

                if (win != null) {
                    grab_save (win, redact);
                } else {
                    Gtk.MessageDialog dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                                                    Gtk.ButtonsType.CLOSE, _("Could not capture screenshot"));
                    dialog.secondary_text = _("Couldn't find an active window");
                    dialog.deletable = false;
                    dialog.run ();
                    dialog.destroy ();
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
                    this.present ();
                }
            });

            var win = selection_area.get_window ();

            selection_area.captured.connect (() => {
                selection_area.close ();
                Timeout.add_seconds (delay - (redact ? 1 : 0), () => {
                    this.present ();
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
            if (redact) {
                var settings = new Settings ("org.gnome.desktop.interface");
                prev_font_regular = settings.get_string ("font-name");
                prev_font_mono = settings.get_string ("monospace-font-name");
                prev_font_document = settings.get_string ("document-font-name");

                settings.set_string ("font-name", "Redacted Script Regular 9");
                settings.set_string ("monospace-font-name", "Redacted Script Light 10");
                settings.set_string ("document-font-name", "Redacted Script Regular 10");
            } else {
                var settings = new Settings ("org.gnome.desktop.interface");

                settings.set_string ("font-name", prev_font_regular);
                settings.set_string ("monospace-font-name", prev_font_mono);
                settings.set_string ("document-font-name", prev_font_document);
            }
        }

        private void cancel_clicked () {
            destroy ();
        }
    }
}
