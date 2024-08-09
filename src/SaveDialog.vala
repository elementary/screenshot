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

    private Gtk.Label folder_name;
    private Gtk.Image folder_image;

    public SaveDialog (Gdk.Pixbuf pixbuf, Settings settings) {
        Object (
            deletable: false,
            modal: true,
            pixbuf: pixbuf,
            settings: settings,
            title: _("Screenshot")
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
            margin_top = 18,
            margin_bottom = 18,
            halign = Gtk.Align.CENTER
        };
        preview_box.add (preview_event_box);

        unowned Gtk.StyleContext preview_box_context = preview_box.get_style_context ();
        preview_box_context.add_class (Granite.STYLE_CLASS_CARD);
        preview_box_context.add_class (Granite.STYLE_CLASS_CHECKERBOARD);

        var dialog_label = new Granite.HeaderLabel (_("Save Image as…"));

        var date_time = new GLib.DateTime.now_local ().format ("%Y-%m-%d %H.%M.%S");

        /// TRANSLATORS: %s represents a timestamp here
        var file_name = _("Screenshot from %s").printf (date_time);

        if (this.scale_factor > 1) {
            file_name += "@%ix".printf (this.scale_factor);
        }

        var name_label = new Granite.HeaderLabel (_("Name"));

        var name_entry = new Granite.ValidatedEntry () {
            activates_default = true,
            hexpand = true,
            text = file_name
        };
        name_entry.grab_focus ();

        var validation_label = new Gtk.Label ("") {
            halign = Gtk.Align.END,
            justify = Gtk.Justification.RIGHT,
            max_width_chars = 55,
            wrap = true,
            xalign = 1
        };
        validation_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        validation_label.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        var name_message_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            margin_top = 3
        };
        name_message_revealer.add (validation_label);

        var format_label = new Granite.HeaderLabel (_("File Type"));

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

        var location_label = new Granite.HeaderLabel (_("Folder")) {
            margin_top = 18
        };

        folder_name = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            hexpand = true
        };

        folder_image = new Gtk.Image ();

        update_location_button (folder_dir);

        var arrow = new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic", BUTTON);

        var location_button_indicator = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        location_button_indicator.add (folder_image);
        location_button_indicator.add (folder_name);
        location_button_indicator.add (arrow);

        var location_button = new Gtk.Button () {
            child = location_button_indicator
        };

        var location_dialog = new Gtk.FileChooserNative (
            _("Select Screenshots Folder…"),
            this,
            Gtk.FileChooserAction.SELECT_FOLDER,
            _("Select"),
            null
        );
        location_dialog.set_current_folder (folder_dir);

        var content = this.get_content_area () as Gtk.Box;
        content.valign = Gtk.Align.START;
        content.vexpand = true;
        content.margin_end = 12;
        content.margin_bottom = 12;
        content.margin_start = 12;
        content.add (dialog_label);
        content.add (preview_box);
        content.add (name_label);
        content.add (name_entry);
        content.add (name_message_revealer);
        content.add (format_label);
        content.add (format_cmb);
        content.add (location_label);
        content.add (location_button);
        content.show_all ();

        var clipboard_btn = (Gtk.Button) add_button (_("Copy to Clipboard"), 0);

        var retry_btn = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var save_btn = (Gtk.Button) add_button (_("Save"), Gtk.ResponseType.APPLY);
        save_btn.has_default = true;
        save_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        name_entry.changed.connect (() => {
            if (name_entry.text.length == 0) {
                validation_label.label = _("Filename can't be blank");
                name_entry.is_valid = false;
            } else if (name_entry.text.contains ("/")) {
                validation_label.label = _("Filename can't contain “/”");
                name_entry.is_valid = false;
            } else {
                name_entry.is_valid = true;
            }

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

        location_button.clicked.connect (() => {
            location_dialog.run ();
        });

        location_dialog.response.connect ((response) => {
            if (response == Gtk.ResponseType.ACCEPT) {
                SList<string> uris = location_dialog.get_uris ();
                foreach (unowned string uri in uris) {
                    settings.set_string ("folder-dir", Uri.unescape_string (uri.substring (7, -1)));
                    folder_dir = settings.get_string ("folder-dir");
                }

                update_location_button (folder_dir);
            }
        });
    }

    private void update_location_button (string folder_dir) {
        var file = File.new_for_path (folder_dir);
        try {
            var info = file.query_info (
                FileAttribute.STANDARD_DISPLAY_NAME + "," + FileAttribute.STANDARD_ICON,
                FileQueryInfoFlags.NONE
            );
            folder_name.label = info.get_display_name ();
            folder_image.gicon = info.get_icon ();
        } catch (Error e) {
            folder_name.label = folder_dir;
            folder_image.gicon = new ThemedIcon ("folder");
        }
    }
}
