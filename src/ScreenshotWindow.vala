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

    public class ScreenshotWindow : Gtk.Window {

        private Settings settings = new Settings ("net.launchpad.screenshot");

        /**
         *  UI elements
         */
        private Gtk.HeaderBar   header;
        private Gtk.Grid        grid;
        private Gtk.Button      take_btn;
        
        private int     type_of_capture;
        private string  choosen_format;
        private bool    mouse_pointer;
        private bool    window_border;
        private string  folder_dir;

        /**
         *  ScreenshotWindow Constructor
         */
        public ScreenshotWindow () {

            title = _("Screenshot");
            resizable = false;     // Window is not resizable

            type_of_capture = 0;
            choosen_format = settings.get_string ("format");
            mouse_pointer = settings.get_boolean ("mouse-pointer");
            window_border = settings.get_boolean ("window-border");
            folder_dir = Environment.get_user_special_dir (UserDirectory.PICTURES);

            if (settings.get_string ("folder-dir") != folder_dir)
                folder_dir = settings.get_string ("folder-dir");

            setup_ui ();
        }

        /**
         *  Builds all of the widgets and arranges them in the window
         */
        void setup_ui () {

            /* Use CSD */
            header = new Gtk.HeaderBar ();
            header.title = this.title;
            header.set_show_close_button (true);
            header.get_style_context ().remove_class ("header-bar");

            this.set_titlebar (header);

            grid = new Gtk.Grid ();
            grid.margin = 12;
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
            all.toggled.connect (() => {
                type_of_capture = 0;
            });

            // TODO
            var curr_window = new Gtk.RadioButton.with_label_from_widget (all, _("Grab the current window"));
            curr_window.toggled.connect (() => {
                type_of_capture = 1;
            });

            // TODO
            var selection = new Gtk.RadioButton.with_label_from_widget (curr_window, _("Select area to grab"));
            selection.toggled.connect (() => {
                type_of_capture = 2;
            });

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

            var border_label = new Gtk.Label (_("Include window border:"));
            border_label.halign = Gtk.Align.END;
            var border_switch = new Gtk.Switch ();
            border_switch.halign = Gtk.Align.START;

            border_switch.set_active (window_border);

            var format_label = new Gtk.Label (_("File format:"));
            format_label.halign = Gtk.Align.END;

            var location_label = new Gtk.Label (_("Screenshots folder:"));
            location_label.halign = Gtk.Align.END;
            var location = new Gtk.FileChooserButton (_("Select Sreenshots Folder…"), Gtk.FileChooserAction.SELECT_FOLDER);

            location.set_current_folder (folder_dir);

            /**
             *  Create combobox for file format
             */
            var format_cmb = new Gtk.ComboBoxText ();
            format_cmb.append_text ("png");
            format_cmb.append_text ("jpeg");
            format_cmb.active = (settings.get_string ("format") == "png" ? 0 : 1);

            // Pack second part of the grid
            grid.attach (prop_label, 0, 3, 1, 1);
            grid.attach (pointer_label, 0, 4, 1, 1);
            grid.attach (pointer_switch, 1, 4, 1, 1);
            grid.attach (border_label, 0, 5, 1, 1);
            grid.attach (border_switch, 1, 5, 1, 1);
            grid.attach (format_label, 0, 6, 1, 1);
            grid.attach (format_cmb, 1, 6, 1, 1);
            grid.attach (location_label, 0, 7, 1, 1);
            grid.attach (location, 1, 7, 1, 1);

            // Take button
            take_btn = new Gtk.Button.with_label (_("Take Screenshot"));
            take_btn.margin_top = 12;

            grid.attach (take_btn, 1, 8, 1, 1);
 
            /**
             *  Signals
             */
            pointer_switch.notify["active"].connect (() => {
			    if (pointer_switch.active) {
				    settings.set_boolean ("mouse-pointer", true);
                    mouse_pointer = settings.get_boolean ("mouse-pointer");
			    } else {
				    settings.set_boolean ("mouse-pointer", false);
                    mouse_pointer = settings.get_boolean ("mouse-pointer");
			    }
		    });

            border_switch.notify["active"].connect (() => {
			    if (border_switch.active) {
				    settings.set_boolean ("window-border", true);
                    window_border = settings.get_boolean ("window-border");
			    } else {
				    settings.set_boolean ("window-border", false);
                    window_border = settings.get_boolean ("window-border");
			    }
		    });

            format_cmb.changed.connect (() => {
                settings.set_string ("format", format_cmb.get_active_text ());
			    choosen_format = settings.get_string ("format");
		    });

            location.selection_changed.connect (() => {
			    SList<string> uris = location.get_uris ();
			    foreach (unowned string uri in uris) {
                    print(uri);
				    settings.set_string ("folder-dir", uri.substring (7, -1));
                    folder_dir = settings.get_string ("folder-dir");
			    }
		    });

            take_btn.clicked.connect (save_to_file);

            // Pack the main grid into the window
            this.add (grid);
        }

        private void save_to_file () {

            Gdk.Pixbuf screenshot;
            string filename;
            int width;
            int height;

            switch (type_of_capture) {
                case 0:
                    Gdk.Window win = Gdk.get_default_root_window();

                    width = win.get_width();
                    height = win.get_height();
                    filename = _("Screenshot ") + new GLib.DateTime.now_local ().format ("%d/%m/%Y - %H:%M") + "." + choosen_format;
                    
                    try {
                        screenshot = Gdk.pixbuf_get_from_window (win, 0, 0, width, height);
                        screenshot.save (filename, choosen_format);

                        // Send success notification
                        show_notification (_("Task finished"), filename + _(" saved"));
                    } catch (GLib.Error e) {
                        // Send failure notification
                        show_notification (_("Task aborted"), filename + _(" couldn't be saved"));
                    }

                    break;
                case 1:
                    // TODO
                    break;
                case 2:
                    // TODO
                    break;
            }
        }
    }
}
