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
        var folder_dir = Environment.get_user_special_dir (UserDirectory.PICTURES)
            + "%c".printf (GLib.Path.DIR_SEPARATOR) + Application.SAVE_FOLDER;

        var folder_from_settings = settings.get_string ("folder-dir");

        if (folder_from_settings != folder_dir && folder_from_settings != "") {
            folder_dir = folder_from_settings;
        }

        Application.create_dir_if_missing (folder_dir);

        var drag_source = new Gtk.DragSource () {
            actions = COPY,
            content = new Gdk.ContentProvider.for_value (pixbuf)
        };
        drag_source.set_icon (
            Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).lookup_icon (
                "image-x-generic",
                null,
                32,
                scale_factor,
                NONE,
                PRELOAD
            ), 0, 0
        );

        var preview = new Gtk.Picture.for_paintable (Gdk.Texture.for_pixbuf (pixbuf)) {
            height_request = 128,
            margin_top = 18,
            margin_bottom = 18
        };
        preview.add_css_class (Granite.STYLE_CLASS_CARD);
        preview.add_css_class (Granite.STYLE_CLASS_CHECKERBOARD);
        preview.add_css_class (Granite.STYLE_CLASS_ROUNDED);
        preview.add_controller (drag_source);

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
        validation_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        validation_label.add_css_class (Granite.STYLE_CLASS_ERROR);

        var name_message_revealer = new Gtk.Revealer () {
            child = validation_label,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            margin_top = 3
        };

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

        var arrow = new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic");

        var location_button_indicator = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        location_button_indicator.append (folder_image);
        location_button_indicator.append (folder_name);
        location_button_indicator.append (arrow);

        var location_button = new Gtk.Button () {
            child = location_button_indicator
        };

        // Prevent large dialog size with large screenshots
        default_width = 500;

        var content = this.get_content_area () as Gtk.Box;
        content.append (dialog_label);
        content.append (preview);
        content.append (name_label);
        content.append (name_entry);
        content.append (name_message_revealer);
        content.append (format_label);
        content.append (format_cmb);
        content.append (location_label);
        content.append (location_button);

        var clipboard_btn = (Gtk.Button) add_button (_("Copy to Clipboard"), 0);

        var retry_btn = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var save_btn = (Gtk.Button) add_button (_("Save"), Gtk.ResponseType.APPLY);
        save_btn.receives_default = true;
        save_btn.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

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
            Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
            clipboard.changed.connect (on_clipboard_changed);
            clipboard.set_texture (Gdk.Texture.for_pixbuf (pixbuf));
        });

        retry_btn.clicked.connect (() => {
            save_response (false, folder_dir, file_name, format_cmb.get_active_text ());
        });

        format_cmb.changed.connect (() => {
            settings.set_string ("format", format_cmb.get_active_text ());
        });

        location_button.clicked.connect (() => {
            var location_dialog = new Gtk.FileDialog () {
                title = _("Select Screenshots Folder…"),
                accept_label = _("Select"),
                initial_folder = File.new_for_path (folder_dir)
            };

            location_dialog.select_folder.begin (this, null, (obj, res) => {
                try {
                    var folder = location_dialog.select_folder.end (res);

                    folder_dir = folder.get_path ();
                    settings.set_string ("folder-dir", folder_dir);
                    update_location_button (folder_dir);
                } catch (Error err) {
                    warning ("Failed to select screenshots folder: %s", err.message);
                }
            });
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

    private void on_clipboard_changed () {
        Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
        Gdk.Texture texture = Gdk.Texture.for_pixbuf (pixbuf);
        clipboard.read_texture_async.begin (null, (obj, res) => {
            Gdk.Texture _texture = clipboard.read_texture_async.end (res);
            if (_texture != null && _texture.height == texture.height && _texture.width == texture.width) {
                hide_destroy ();
            }
        });
    }

    public void hide_destroy () {
        hide ();

        // Timeout added to ensure the clipboard is synced
        // before closing the window
        GLib.Timeout.add_once (500, () => {
            close ();
        });
    }
}
