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

        /**
         *  UI elements
         */
        private Gtk.HeaderBar   header;
        private Gtk.Grid        grid;
        private Gtk.Button      take_btn;

        private enum FORMAT {
            PNG,
            JPG
        }
        
        private int choosen_format = 0;

        /**
         *  ScreenshotWindow Constructor
         */
        public ScreenshotWindow () {

            title = _("Screenshot");
            resizable = false;     // Window is not resizable

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
            grid.margin_top = 24;
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
            //all.toggled.connect (null);

            var curr_window = new Gtk.RadioButton.with_label_from_widget (all, _("Grab the current window"));
            //curr_window.toggled.connect (null);

            // Not implemented yet
            var selection = new Gtk.RadioButton.with_label_from_widget (curr_window, _("Select area to grab"));
            //selection.toggled.connect (null);

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

            var border_label = new Gtk.Label (_("Include window border:"));
            border_label.halign = Gtk.Align.END;
            var border_switch = new Gtk.Switch ();

            var format_label = new Gtk.Label (_("File format:"));
            format_label.halign = Gtk.Align.END;

            /**
             *  Create combobox for file format
             */
            var format_cmb = new Gtk.ComboBoxText ();
            format_cmb.append_text ("PNG");
            format_cmb.append_text ("JPG");
            format_cmb.active = 0;

            grid.attach (prop_label, 0, 3, 1, 1);
            grid.attach (pointer_label, 0, 4, 1, 1);
            grid.attach (pointer_switch, 1, 4, 1, 1);
            grid.attach (border_label, 0, 5, 1, 1);
            grid.attach (border_switch, 1, 5, 1, 1);
            grid.attach (format_label, 0, 6, 1, 1);
            grid.attach (format_cmb, 1, 6, 1, 1);

            // Take button
            take_btn = new Gtk.Button.with_label (_("Take Screenshot"));
            take_btn.margin_top = 18;

            grid.attach (take_btn, 1, 7, 1, 1);
 
            this.add (grid);
        }

        private void save_to_file () {
            
        }
    }
}
