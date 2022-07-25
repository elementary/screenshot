/*
* Copyright (c) 2014–2016 Fabio Zaramella <ffabio.96.x@gmail.com>
*               2017–2022 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3 as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Artem Anufrij <artem.anufrij@live.de>
*              Fabio Zaramella <ffabio.96.x@gmail.com>
*/

public class Screenshot.SaveDialog : Granite.Dialog {
    public Gdk.Pixbuf pixbuf { get; construct; }
    public Settings settings { get; construct; }

    public signal void save_response (bool response, string folder_dir, string output_name, string format);

    public SaveDialog (Gdk.Pixbuf pixbuf, Settings settings, Gtk.Window parent) {
        Object (
            deletable: false,
            modal: true,
            pixbuf: pixbuf,
            resizable: false,
            settings: settings,
            title: _("Screenshot"),
            transient_for: parent
        );
    }

    construct {
        set_keep_above (true);
        var folder_dir = Environment.get_user_special_dir (UserDirectory.PICTURES)
            + "%c".printf (GLib.Path.DIR_SEPARATOR) + Application.SAVE_FOLDER;

        var folder_from_settings = settings.get_string ("folder-dir");

        if (folder_from_settings != folder_dir && folder_from_settings != "") {
            folder_dir = folder_from_settings;
        }

        Application.create_dir_if_missing (folder_dir);

        int width = pixbuf.get_width () / 4;
        int height = pixbuf.get_height () / 4;
        if (pixbuf.get_width () > Gdk.Screen.width () / 2 || pixbuf.get_height () > Gdk.Screen.height () / 2) {
            width /= 2;
            height /= 2;
        }

        var scale = get_style_context ().get_scale ();

        var preview = new Gtk.Image () {
            gicon = pixbuf.scale_simple (width * scale, height * scale, Gdk.InterpType.BILINEAR)
        };
        preview.get_style_context ().set_scale (1);

        var preview_event_box = new Gtk.EventBox ();
        preview_event_box.add (preview);

        Gtk.drag_source_set (preview_event_box, Gdk.ModifierType.BUTTON1_MASK, null, Gdk.DragAction.COPY);
        Gtk.drag_source_add_image_targets (preview_event_box);
        Gtk.drag_source_set_icon_gicon (preview_event_box, new ThemedIcon ("image-x-generic"));
        preview_event_box.drag_data_get.connect ((widget, context, selection_data, info, time_) => {
            selection_data.set_pixbuf (pixbuf);
        });


        var preview_box = new Gtk.Grid () {
            halign = Gtk.Align.CENTER
        };
        preview_box.add (preview_event_box);

        unowned Gtk.StyleContext preview_box_context = preview_box.get_style_context ();
        preview_box_context.add_class (Granite.STYLE_CLASS_CARD);
        preview_box_context.add_class (Granite.STYLE_CLASS_CHECKERBOARD);

        var dialog_label = new Gtk.Label (_("Save Image as…")) {
            halign = Gtk.Align.START
        };
        dialog_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var name_label = new Gtk.Label (_("Name:")) {
            halign = Gtk.Align.END
        };

        var date_time = new GLib.DateTime.now_local ().format ("%Y-%m-%d %H.%M.%S");

        /// TRANSLATORS: %s represents a timestamp here
        var file_name = _("Screenshot from %s").printf (date_time);

        if (this.scale_factor > 1) {
            file_name += "@%ix".printf (this.scale_factor);
        }

        var name_entry = new Granite.ValidatedEntry () {
            hexpand = true,
            text = file_name
        };
        name_entry.grab_focus ();

        var name_message_revealer = new ValidationMessage (_("File name cannot contain '/'"));
        name_message_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        var name_entry_grid = new Gtk.Grid ();
        name_entry_grid.attach (name_entry, 0, 0);
        name_entry_grid.attach (name_message_revealer, 0, 1);

        var format_label = new Gtk.Label (_("Format:")) {
            halign = Gtk.Align.END
        };

        var format_cmb = new Gtk.ComboBoxText ();
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

        var location_label = new Gtk.Label (_("Folder:")) {
            halign = Gtk.Align.END
        };

        var location = new Gtk.FileChooserButton (_("Select Screenshots Folder…"), Gtk.FileChooserAction.SELECT_FOLDER);
        location.set_current_folder (folder_dir);

        var grid = new Gtk.Grid () {
            margin = 12,
            margin_top = 0,
            row_spacing = 12,
            column_spacing = 12
        };
        grid.attach (preview_box, 0, 0, 2, 1);
        grid.attach (dialog_label, 0, 1, 2, 1);
        grid.attach (name_label, 0, 2, 1, 1);
        grid.attach (name_entry_grid, 1, 2, 1, 1);
        grid.attach (format_label, 0, 3, 1, 1);
        grid.attach (format_cmb, 1, 3, 1, 1);
        grid.attach (location_label, 0, 4, 1, 1);
        grid.attach (location, 1, 4, 1, 1);

        var content = this.get_content_area () as Gtk.Box;
        content.add (grid);

        var clipboard_btn = (Gtk.Button) add_button (_("Copy to Clipboard"), 0);

        var retry_btn = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var save_btn = (Gtk.Button) add_button (_("Save"), Gtk.ResponseType.APPLY);
        save_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        name_entry.changed.connect (() => {
            name_entry.is_valid = !name_entry.text.contains ("/");
            name_message_revealer.reveal_child = !name_entry.is_valid;
            save_btn.sensitive = name_entry.is_valid;
        });

        save_btn.clicked.connect (() => {
            save_response (true, folder_dir, name_entry.get_text (), format_cmb.get_active_text ());
        });

        clipboard_btn.clicked.connect (() => {
             Gtk.Clipboard.get_default (this.get_display ()).set_image (pixbuf);
             this.close ();
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
                settings.set_string ("folder-dir", Uri.unescape_string (uri.substring (7, -1)));
                folder_dir = settings.get_string ("folder-dir");
            }
        });

        key_press_event.connect ((e) => {
            if (e.keyval == Gdk.Key.Return)
                save_btn.activate ();

            return false;
        });
    }
}
