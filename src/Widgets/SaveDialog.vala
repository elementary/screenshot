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

namespace Screenshot.Widgets {

    public class SaveDialog : Gtk.Dialog {

        private Gtk.Grid        grid;
        private Gtk.Label       name_label;
        private Gtk.Entry       name_entry;
        private Gtk.Button      save_btn;
        private Gtk.Button      retry_btn;

        public signal void save_confirm (bool response, string outname);

        public SaveDialog (Gtk.Window parent, string filename) {

            Object (use_header_bar: 1);
            (get_header_bar () as Gtk.HeaderBar).show_close_button = false;
            get_header_bar ().get_style_context ().remove_class ("header-bar");

            resizable = false;
            deletable = false;
            modal = true;
            set_keep_above (true);
            set_transient_for (parent);
            
            build (parent, filename);
        }

        public void build (Gtk.Window parent, string filename) {

            grid = new Gtk.Grid (); 
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.margin_start = 12;
            grid.margin_end = 12;
            #if HAS_GTK314_MIN
            grid.margin_bottom = 12;
            #endif

            var content = this.get_content_area () as Gtk.Box;

            name_label = new Gtk.Label (_("Name:"));
            name_label.halign = Gtk.Align.END;
            name_entry = new Gtk.Entry ();
            name_entry.set_text (filename);
            name_entry.set_width_chars (30);

            save_btn = new Gtk.Button.with_label (_("Save"));
            retry_btn = new Gtk.Button.with_label (_("Cancel"));

            save_btn.can_default = true;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            box.pack_end (save_btn, false, true, 0);
            box.pack_end (retry_btn, false, true, 0);
            box.homogeneous = true;

            save_btn.clicked.connect (() => {
                save_confirm (true, name_entry.get_text ());
                this.destroy ();
                parent.present ();
            });

            retry_btn.clicked.connect (() => {
                save_confirm (false, filename);
                this.destroy ();
                parent.present ();
            });

            grid.attach (name_label, 0, 0, 1, 1);
            grid.attach (name_entry, 1, 0, 1, 1);
            grid.attach (box, 1, 1, 1, 1);

            content.add (grid);
            show_all ();

            save_btn.grab_focus ();
        }

    }

}
