/***
  BEGIN LICENSE

  Copyright (C) 2014-2015 Fabio Zaramella <ffabio.96.x@gmail.com>

  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as
  published    by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program.  If not, see <http://www.gnu.org/licenses>

  END LICENSE
***/

namespace Screenshot {

    public class ScreenshotWindow : Gtk.Dialog {

        private Settings settings = new Settings ("net.launchpad.screenshot");

        /**
         *  UI elements
         */
        private Gtk.Grid grid;

        private int     type_of_capture;
        private bool    mouse_pointer;
        private bool    include_date;
        private bool    close_on_save;
        private int     delay;

        private Screenshot.Widgets.SelectionArea    selection_area;
        private Screenshot.Widgets.SaveDialog       save_dialog;

        /**
         *  ScreenshotWindow Constructor
         */
        public ScreenshotWindow () {

            resizable = false;
            deletable = false;
            border_width = 6;

            type_of_capture = 0;
            mouse_pointer = settings.get_boolean ("mouse-pointer");
            include_date = settings.get_boolean ("include-date");
            close_on_save = settings.get_boolean ("close-on-save");
            delay = 1;

            setup_ui ();
        }

        /**
         *  Builds all of the widgets and arranges them in the window
         */
        void setup_ui () {

            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 6;
            grid.column_spacing = 12;

            /* Labels used to distinguish selections */
            var area_label = new Gtk.Label ("");
            area_label.set_markup ("<b>"+_("Capture area:")+"</b>");
            area_label.halign = Gtk.Align.END;

            var prop_label = new Gtk.Label ("");
            prop_label.set_markup ("<b>"+_("Properties")+"</b>");
            prop_label.margin_top = 12;
            prop_label.halign = Gtk.Align.END;

            /**
             *  Capture area selection
             */
            var all = new Gtk.RadioButton.with_label_from_widget (null, _("Grab the whole screen"));

            var curr_window = new Gtk.RadioButton.with_label_from_widget (all, _("Grab the current window"));

            var selection = new Gtk.RadioButton.with_label_from_widget (curr_window, _("Select area to grab"));

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

            var date_label = new Gtk.Label (_("Include date in file name:"));
            date_label.halign = Gtk.Align.END;
            var date_switch = new Gtk.Switch ();
            date_switch.halign = Gtk.Align.START;

            date_switch.set_active (include_date);

            var close_label = new Gtk.Label (_("Close after saving:"));
            close_label.halign = Gtk.Align.END;
            var close_switch = new Gtk.Switch ();
            close_switch.halign = Gtk.Align.START;

            close_switch.set_active (close_on_save);

            var delay_label = new Gtk.Label (_("Delay in seconds:"));
            delay_label.halign = Gtk.Align.END;

            var delay_spin = new Gtk.SpinButton.with_range (1, 15, 1);
		    delay_spin.set_value (delay);

            // Pack second part of the grid
            grid.attach (prop_label, 0, 3, 1, 1);
            grid.attach (pointer_label, 0, 4, 1, 1);
            grid.attach (pointer_switch, 1, 4, 1, 1);
            grid.attach (date_label, 0, 5, 1, 1);
            grid.attach (date_switch, 1, 5, 1, 1);
            grid.attach (close_label, 0, 6, 1, 1);
            grid.attach (close_switch, 1, 6, 1, 1);
            grid.attach (delay_label, 0, 7, 1, 1);
            grid.attach (delay_spin, 1, 7, 1, 1);

            // Take button
            var take_btn = new Gtk.Button.with_label (_("Take Screenshot"));
            take_btn.get_style_context ().add_class ("suggested-action");
            take_btn.can_default = true;

            this.set_default (take_btn);

            var cancel_btn = new Gtk.Button.with_label (_("Cancel"));

            Gtk.Box actions = get_action_area () as Gtk.Box;
            actions.add (cancel_btn);
            actions.add (take_btn);


            /**
             *  Signals
             */
            all.toggled.connect (() => {
                type_of_capture = 0;

                if (selection_area != null)
                    selection_area.hide ();
            });

            curr_window.toggled.connect (() => {
                type_of_capture = 1;

                if (selection_area != null)
                    selection_area.hide ();
            });

            selection.toggled.connect (() => {
                type_of_capture = 2;
                
                if (selection_area == null) {
                    selection_area = new Screenshot.Widgets.SelectionArea ();
				    selection_area.show_all ();
                } else
                    selection_area.present ();

                set_transient_for (selection_area);
                present();
            });

            pointer_switch.notify["active"].connect (() => {
			    if (pointer_switch.active) {
				    settings.set_boolean ("mouse-pointer", true);
                    mouse_pointer = settings.get_boolean ("mouse-pointer");
			    } else {
				    settings.set_boolean ("mouse-pointer", false);
                    mouse_pointer = settings.get_boolean ("mouse-pointer");
			    }
		    });

            date_switch.notify["active"].connect (() => {
			    if (date_switch.active) {
				    settings.set_boolean ("include-date", true);
                    include_date = settings.get_boolean ("include-date");
			    } else {
				    settings.set_boolean ("include-date", false);
                    include_date = settings.get_boolean ("include-date");
			    }
		    });

            close_switch.notify["active"].connect (() => {
			    if (close_switch.active) {
				    settings.set_boolean ("close-on-save", true);
                    close_on_save = settings.get_boolean ("close-on-save");
			    } else {
				    settings.set_boolean ("close-on-save", false);
                    close_on_save = settings.get_boolean ("close-on-save");
			    }
		    });

            delay_spin.value_changed.connect (() => {
			    delay = delay_spin.get_value_as_int ();
		    });

            take_btn.clicked.connect (take_clicked);
            cancel_btn.clicked.connect (cancel_clicked);

            focus_in_event.connect (() => {
                if (selection_area != null && selection_area.is_visible ()) {
                    selection_area.present ();
                    present ();
                }

                return false;
            });

            // Pack the main grid into the window
            Gtk.Box content = get_content_area () as Gtk.Box;
            content.add (grid);
        }
        
        private bool grab_save (Gdk.Window win) {

            Gdk.Pixbuf      screenshot;
            Gdk.Rectangle   win_rect;
            int             width, height;
            
            win_rect = Gdk.Rectangle ();

            width = win.get_width();
            height = win.get_height();

            screenshot = Gdk.pixbuf_get_from_window (win, 0, 0, width, height);

            win_rect.x = 0;
            win_rect.y = 0;
            win_rect.width = width;
            win_rect.height = height;

            if (type_of_capture == 2) {
                screenshot = new Gdk.Pixbuf.subpixbuf (screenshot, selection_area.x, selection_area.y, selection_area.w, selection_area.h);
                    
                win_rect.x = selection_area.x;
                win_rect.y = selection_area.y;
                win_rect.width = selection_area.w;
                win_rect.height = selection_area.h;
            }

            if (mouse_pointer) {

                Gdk.Cursor      cursor;
                Gdk.Pixbuf      cursor_pixbuf;

                cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.LEFT_PTR);
                cursor_pixbuf = cursor.get_image ();

                if (cursor_pixbuf != null) {
                        
                    Gdk.DeviceManager   manager;
                    Gdk.Device          device;
                    Gdk.Rectangle       cursor_rect;
                    int                 cx, cy;

                    manager = Gdk.Display.get_default ().get_device_manager ();
                    device = manager.get_client_pointer ();
                    win.get_device_position (device, out cx, out cy, null);
                    cursor_rect = Gdk.Rectangle ();

                    cursor_rect.x = cx + win_rect.x;
                    cursor_rect.y = cy + win_rect.y;
                    cursor_rect.width = cursor_pixbuf.get_width ();
                    cursor_rect.height = cursor_pixbuf.get_height ();

                    if (win_rect.intersect (cursor_rect, out cursor_rect)) {

                        cursor_pixbuf.composite (screenshot, cx, cy, cursor_rect.width, cursor_rect.height, cx, cy, 1.0, 1.0, Gdk.InterpType.BILINEAR, 255);
                    }
                }
            }

            save_dialog = new Screenshot.Widgets.SaveDialog (settings, this, include_date);

            save_dialog.save_response.connect ((response, folder_dir, output_name, format) => {
                save_dialog.set_opacity (0);
                save_dialog.destroy ();

                if (response == true) {
                    string file_name = folder_dir + "/" + output_name + "." + format;

                    try {
                        screenshot.save (file_name, format);

                        if (close_on_save == true)
                            this.destroy ();
                    } catch (GLib.Error e) {
                        // Send failure notification
                        show_notification (_("Task aborted"), _("Image not saved"));
                        debug (e.message);
                    }
                } else
                    return;
            });

            return false;
        }

        private void take_clicked () {

            Gdk.Screen              screen = null;
            Gdk.Window              win    = null;
            GLib.List<Gdk.Window>   list   = null;
            
            switch (type_of_capture) {
                case 0:
                    win = Gdk.get_default_root_window();

                    this.set_opacity (0);
                    this.hide ();
                    Timeout.add (delay*1000, () => {
                        this.show ();
                        grab_save (win);
                        Timeout.add (200, () => {
                            this.set_opacity (1);
                            return false;
                        });
                        return false;
                    }); 
                    break;
                case 1:
                    screen = Gdk.Screen.get_default ();

                    this.set_opacity (0);
                    this.hide ();
                    Timeout.add (delay*1000, () => {
                        list = screen.get_window_stack ();
                        foreach (Gdk.Window item in list) {
                            if (screen.get_active_window () == item) {
                                win = item;                   
                            }
                        }
                        this.show ();
                        if (win != null)
                            grab_save (win);
                        else
                            show_notification (_("Task aborted"), _("Couldn't find an active window"));
                        Timeout.add (200, () => {
                            this.set_opacity (1);
                            return false;
                        });
                        return false;
                    });
                    break;
                case 2:
                    win = Gdk.get_default_root_window();

                    selection_area.set_opacity (0);
                    this.set_opacity (0);
                    Timeout.add (delay*1000, () => {
                        grab_save (win);
                        Timeout.add (200, () => {
                            selection_area.set_opacity (1);
                            this.set_opacity (1);
                            return false;
                        });
                        return false;
                    });
                    break;
            }
        }

        private void cancel_clicked () {
            destroy ();
        }
    }
}
