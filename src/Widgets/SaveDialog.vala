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

namespace Screenshot.Widgets {

    public class SaveDialog : Gtk.Dialog {

        private Gtk.Grid            grid;
        private Gtk.Label           dialog_label;
        private Gtk.Label           name_label;
        private Gtk.Entry           name_entry;
        private Gtk.Label           format_label;
        private Gtk.ComboBoxText    format_cmb;
        private Gtk.Button          save_btn;
        private Gtk.Button          retry_btn;

        private string  file_name;
        private string  date_time;
        private string  folder_dir;

        public signal void save_response (bool response, string folder_dir, string output_name, string format);

        public SaveDialog (Gdk.Pixbuf pixbuf, Settings settings, Gtk.Window parent) {

            resizable = false;
            deletable = false;
            border_width = 6;
            modal = true;
            set_keep_above (true);
            set_transient_for (parent);

            folder_dir = Environment.get_user_special_dir (UserDirectory.PICTURES);

            if (settings.get_string ("folder-dir") != folder_dir && settings.get_string ("folder-dir") != "")
                folder_dir = settings.get_string ("folder-dir");

            build (pixbuf, settings, parent);
            show_all ();
            name_entry.grab_focus ();
        }

        public void build (Gdk.Pixbuf pixbuf, Settings settings, Gtk.Window parent) {

            date_time = new GLib.DateTime.now_local ().format ("%Y-%m-%d %H:%M:%S");
            file_name = _("Screenshot from ") + date_time;

            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 12;
            grid.column_spacing = 12;

            var content = this.get_content_area () as Gtk.Box;

            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            int width = pixbuf.get_width () / 4;
            int height = pixbuf.get_height () / 4;
            if (pixbuf.get_width () > Gdk.Screen.width () / 2) {
                width /= 2;
            }

            if (pixbuf.get_height () > Gdk.Screen.height () / 2) {
                height /= 2;
            }

            var screenshot = pixbuf.scale_simple (width, height, Gdk.InterpType.BILINEAR);

            var preview = new Gtk.Image.from_pixbuf (screenshot);

            dialog_label = new Gtk.Label (_("Save Image as…"));
            dialog_label.get_style_context ().add_class ("h4");
            dialog_label.halign = Gtk.Align.START;

            name_label = new Gtk.Label (_("Name:"));
            name_label.halign = Gtk.Align.END;
            name_entry = new Gtk.Entry ();
            name_entry.set_text (file_name);
            name_entry.set_width_chars (35);

            format_label = new Gtk.Label (_("Format:"));
            format_label.halign = Gtk.Align.END;

            /**
             *  Create combobox for file format
             */
            format_cmb = new Gtk.ComboBoxText ();
            format_cmb.append_text ("png");
            format_cmb.append_text ("jpeg");
            format_cmb.append_text ("bmp");
            format_cmb.append_text ("tiff");

            switch (settings.get_string ("format")) {
                case "png":
                    format_cmb.active = 0;
                    break;
                case "jpeg":
                    format_cmb.active = 1;
                    break;
                case "bmp":
                    format_cmb.active = 2;
                    break;
                case "tiff":
                    format_cmb.active = 3;
                    break;
            }

            var location_label = new Gtk.Label (_("Folder:"));
            location_label.halign = Gtk.Align.END;
            var location = new Gtk.FileChooserButton (_("Select Screenshots Folder…"), Gtk.FileChooserAction.SELECT_FOLDER);

            location.set_current_folder (folder_dir);

            save_btn = new Gtk.Button.with_label (_("Save"));
            retry_btn = new Gtk.Button.with_label (_("Cancel"));

            save_btn.get_style_context ().add_class ("suggested-action");

            Gtk.Box actions = get_action_area () as Gtk.Box;
            actions.margin_top = 12;
            actions.add (retry_btn);
            actions.add (save_btn);

            save_btn.clicked.connect (() => {
                save_response (true, folder_dir, name_entry.get_text (), format_cmb.get_active_text ());
            });

            retry_btn.clicked.connect (() => {
                save_response (false, folder_dir, file_name, format_cmb.get_active_text ());
            });

            format_cmb.changed.connect (() => {
                settings.set_string ("format", format_cmb.get_active_text ());
            });

            location.selection_changed.connect (() => {
                SList<string> uris = location.get_uris ();
                foreach (unowned string uri in uris) {
                    settings.set_string ("folder-dir", uri.substring (7, -1));
                    folder_dir = settings.get_string ("folder-dir");
                }
            });

            key_press_event.connect ((e) => {
                if (e.keyval == Gdk.Key.Return)
                    save_btn.activate ();

                return false;
            });

            grid.attach (dialog_label, 1, 0, 1, 1);
            grid.attach (name_label, 0, 1, 1, 1);
            grid.attach (name_entry, 1, 1, 1, 1);
            grid.attach (format_label, 0, 2, 1, 1);
            grid.attach (format_cmb, 1, 2, 1, 1);
            grid.attach (location_label, 0, 3, 1, 1);
            grid.attach (location, 1, 3, 1, 1);

            main_box.add (preview);
            main_box.add (grid);

            content.add (main_box);
        }
    }
}
