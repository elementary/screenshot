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

            var delay_spin = new Gtk.SpinButton.with_range (0, 15, 1);
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

            var root = Gdk.get_default_root_window ();

            if (win == null) {
                win = root;
            }

            var root_width = root.get_width ();
            var root_height = root.get_height ();
            int scale_factor = root.get_scale_factor ();

            Gdk.Pixbuf? root_pix = get_scaled_pixbuf_from_window (root, capture_mode, scale_factor);

            if (root_pix == null) {
                show_error_dialog ();
                return false;
            }

            if (mouse_pointer) {
                /* Getting actual cursor for current window fails for some reason so we construct a default cursor */
                var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.LEFT_PTR);
                var cursor_pixbuf = cursor.get_image ();

                /* It is easier to accurately place cursor by compositing cursor image with the root screen */
                /* It may or may not appear in the final screenshot */
                if (cursor_pixbuf != null) {
                    var manager = Gdk.Display.get_default ().get_device_manager ();
                    var device = manager.get_client_pointer ();

                    int cx, cy, xhot, yhot;
                    root.get_device_position (device, out cx, out cy, null);

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

                    cursor_pixbuf.composite (root_pix,
                                             cursor_rect.x, cursor_rect.y,
                                             cursor_rect.width, cursor_rect.height,
                                             cursor_rect.x, cursor_rect.y,
                                             scale_factor,
                                             scale_factor,
                                             Gdk.InterpType.BILINEAR,
                                             255);
                }
            }

            Gdk.Pixbuf? screenshot = null;

            if (capture_mode == CaptureType.AREA || capture_mode == CaptureType.CURRENT_WINDOW) {
                /* We use a subpixbuf of the root screen for capturing the current window because this will include
                 * menus, popups, tooltips etc whereas pixbuf_get_from_window will not */
                Gdk.Rectangle selection_rect;
                win.get_frame_extents (out selection_rect); /* Includes non-CSD decorations and regions offscreen */
                Gdk.Pixbuf? window_pix = null;
                int offset_x, offset_y;
                offset_x = offset_y = 0;
                Gdk.Rectangle subpix_rect = {selection_rect.x, selection_rect.y ,selection_rect.width ,selection_rect.height};

                if (capture_mode == CaptureType.CURRENT_WINDOW) {
                    /* frame_extents may include shadow region as a translucent border which we
                     * do not want when creating the subpixbuf because it will cause selection of
                     * parts of the background screen.*/

                    /* Need to scale frame extents when not selected manually */
                    if (scale_factor > 1) {
                        selection_rect.x *= scale_factor;
                        selection_rect.y *= scale_factor;
                        selection_rect.width *= scale_factor;
                        selection_rect.height *= scale_factor;
                    }

                    window_pix = get_scaled_pixbuf_from_window (win, capture_mode, scale_factor);
                    /* window_pix does not include non-CSD decorations but includes regions offscreen */
                    /* For non-CSD windows window_pix has no shadow and selection_rect will be unaltered and larger than window_pix;
                     * the offsets will be zero.  For CSD windows, selection_rect starts the same size as window_pix
                     * and will be shrunk to exclude the shadows; the offsets will reflect the thickness of the shadows. */
                    selection_rect = remove_translucent_border (window_pix, selection_rect, out offset_x, out offset_y);
                    subpix_rect = {selection_rect.x, selection_rect.y ,selection_rect.width ,selection_rect.height};

                    /* Do not try to select region outside the root window */
                    if (selection_rect.x < 0) {
                        subpix_rect.width += selection_rect.x;
                        subpix_rect.x = 0;
                    }

                    if (selection_rect.x + selection_rect.width > root_width) {
                        subpix_rect.width = root_width - selection_rect.x;
                    }

                    if (selection_rect.y < 0) {
                        subpix_rect.height += selection_rect.y;
                        subpix_rect.y = 0;
                    }

                    if (selection_rect.y + selection_rect.height > root_height) {
                        subpix_rect.height = root_height - selection_rect.y;
                    }
                }

                Gdk.Pixbuf subpix = new Gdk.Pixbuf.subpixbuf (root_pix,
                                                              subpix_rect.x,
                                                              subpix_rect.y,
                                                              subpix_rect.width,
                                                              subpix_rect.height);

                if (capture_mode == CaptureType.CURRENT_WINDOW) {
                    /* For whole window grab, construct a composite of selection_pix and window_pix
                     * (including shadow if there is one - absent with non-CSD windows.  Use Cairo since
                     * we do not know which of the pixbufs is larger.  */
                    screenshot = composite_pix (subpix, window_pix, selection_rect, offset_x, offset_y);
                } else {
                    screenshot = subpix;
                }
            } else {
                screenshot = root_pix;
            }

            if (screenshot == null) {
                show_error_dialog ();
                return false;
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

        private Gdk.Pixbuf? get_scaled_pixbuf_from_window (Gdk.Window win, CaptureType mode, int scale_factor) {
            int width = win.get_width ();
            int height = win.get_height ();
            // Check the scaling factor in use, and if greater than 1 scale the image. (for HiDPI displays)
            Gdk.Pixbuf? pix;
            if (scale_factor > 1 && mode == CaptureType.SCREEN) {
                pix = Gdk.pixbuf_get_from_window (win, 0, 0, width / scale_factor, height / scale_factor);
                pix.scale (pix, width, height, width, height, 0, 0, scale_factor, scale_factor, Gdk.InterpType.BILINEAR);
            } else {
                pix = Gdk.pixbuf_get_from_window (win, 0, 0, width, height);
            }

            return pix;
        }


        private Gdk.Rectangle remove_translucent_border (Gdk.Pixbuf? pix, Gdk.Rectangle rect, out int offset_x, out int offset_y) {
            const int MIN_ALPHA = 128;
            const int MIN_COLOR = 10;
            offset_x = offset_y = 0;

            if (pix == null) {
                rect.x = rect.y = rect.width = rect.height = 0;
            } else {
                /* Measure any dark translucent shadow around pix */
                var height = pix.get_height ();
                var width = pix.get_width ();
                uint8[] bytes = pix.read_pixel_bytes ().get_data ();
                var length = pix.get_byte_length ();
                var rowstride = pix.rowstride;
                var half_row = (width / 2) * 4;

                /* Measure top margin */
                int count = 0;
                uint index = half_row + 3;
                while (index < length &&
                       bytes[index] < MIN_ALPHA &&
                       bytes[index - 1] < MIN_COLOR &&
                       bytes[index - 2] < MIN_COLOR &&
                       bytes[index - 3] < MIN_COLOR) {


                    index += rowstride;
                    count++;
                }

                rect.height -= count;
                rect.y += count;
                offset_y = count;

                /* Measure bottom margin */
                count = 0;
                index = (uint)(length - half_row + 3);

                while (index < length &&
                       bytes[index] < MIN_ALPHA &&
                       bytes[index - 1] < MIN_COLOR &&
                       bytes[index - 2] < MIN_COLOR &&
                       bytes[index - 3] < MIN_COLOR) {

                    index -= rowstride;
                    count++;
                }

                rect.height -= count;

                /* Measure left margin */
                count = 0;
                index = (uint)(rowstride * (height / 2) + 3);
                while (index < length &&
                       bytes[index] < MIN_ALPHA &&
                       bytes[index - 1] < MIN_COLOR &&
                       bytes[index - 2] < MIN_COLOR &&
                       bytes[index - 3] < MIN_COLOR) {

                    index += 4;
                    count++;
                }

                rect.width -= count;
                rect.x += count;
                offset_x = count;

                /* Measure right margin */
                count = 0;
                index = rowstride * (height / 2) - 1;
                while (index < length &&
                       bytes[index] < MIN_ALPHA &&
                       bytes[index - 1] < MIN_COLOR &&
                       bytes[index - 2] < MIN_COLOR &&
                       bytes[index - 3] < MIN_COLOR) {

                    index -= 4;
                    count++;
                }

                rect.width -= count;
            }

            return rect;
        }
        /*** @pix1 is the subpix of the root screen.
           * @pix2 is the pixbuf of the whole window with CSD decorations (if any) including shadows.
           * @selection_rect is the area of the whole window, including non-CSD decorations (if any) but excluding shadows.
           * @offset_x and @offset_y are zero for non-CSD window since @pix2 is smaller than @selection_rect.
           * @offset_x and @offset_y reflect the left and top shadow widths for CSD windows.
           * @pix1 will be composited on top of @pix2. The final result
           * will contain the whole of each pix on a white background.
         ***/
        private Gdk.Pixbuf composite_pix (Gdk.Pixbuf pix1, Gdk.Pixbuf pix2, Gdk.Rectangle selection_rect,
                                          int offset_x, int offset_y) {

            double offset_x1 = 0.0;
            double offset_y1 = 0.0;
            double offset_x2 = 0.0;
            double offset_y2 = 0.0;
            int width1 = pix1.get_width ();
            int width2 = pix2.get_width ();
            int height1 = pix1.get_height ();
            int height2 = pix2.get_height ();

            offset_x1 = offset_x;
            offset_y1 = offset_y;

            bool left_truncation = (selection_rect.width > width1 && selection_rect.x < 0);
            bool top_truncation = (selection_rect.height > height1 && selection_rect.y < 0);
            int top_truncation_amount = top_truncation ? selection_rect.height - height1 : 0;
            bool non_CSD = (selection_rect.height > height2);
            int non_CSD_amount = non_CSD ? selection_rect.height - height2 : 0;
            int non_CSD_not_showing_amount = non_CSD ? int.min (top_truncation_amount, non_CSD_amount) : 0;

            if (left_truncation) {
                offset_x1 -= selection_rect.x;
            }

            if (top_truncation) {
                if (!non_CSD) {
                    offset_y1 -= selection_rect.y;
                } else {
                    offset_y1 -= (selection_rect.y + non_CSD_amount);
                }
            } else {
                offset_y2 = non_CSD_amount;
            }

            var cairo_width = int.max (selection_rect.width, width2);
            var cairo_height = int.max (selection_rect.height - non_CSD_not_showing_amount, height2);

            /* Create an Image surface large enough to hold composite image*/
            var cs = new Cairo.ImageSurface (Cairo.Format.ARGB32, cairo_width, cairo_height);
            var cr = new Cairo.Context (cs);
            cr.set_operator (Cairo.Operator.OVER);

            cr.translate (offset_x2, offset_y2);
            Gdk.cairo_set_source_pixbuf (cr, pix2, 0.0, 0.0);
            cr.paint ();

            cr.translate (offset_x1 - offset_x2, offset_y1 - offset_y2);
            Gdk.cairo_set_source_pixbuf (cr, pix1, 0.0, 0.0);
            cr.paint ();

            return Gdk.pixbuf_get_from_surface (cs, 0, 0, cairo_width, cairo_height);
        }

        private void save_file (string file_name, string format, string folder_dir, Gdk.Pixbuf screenshot) throws GLib.Error {
            string full_file_name = "";
            string folder_from_settings = "";

            if (folder_dir == "") {
                folder_from_settings = settings.get_string ("folder-dir");
                if (folder_from_settings != "" && File.new_for_path (folder_from_settings).query_exists ()) {
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

        private int get_timeout(int delay, bool redact) {
            int timeout = delay * 1000;

            if (redact) {
                timeout -= 1000;
            }

            if (timeout < 100) {
                timeout = 100;
            }

            return timeout;
        }

        private void capture_screen () {
            this.hide ();

            Timeout.add (get_timeout (delay, redact), () => {
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
            Timeout.add (get_timeout (delay, redact), () => {
                list = screen.get_window_stack ();
                foreach (Gdk.Window item in list) {
                    if (screen.get_active_window () == item) {
                        win = item;
                    }

                    // Receive updates of other windows when they are resized
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
                Timeout.add (get_timeout (delay, redact), () => {
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
