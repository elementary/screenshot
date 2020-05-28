/*
* Copyright (c) 2014–2016 Fabio Zaramella <ffabio.96.x@gmail.com>
*               2017–2018 elementary LLC. (https://elementary.io)
*               2019 Alexander Mikhaylenko <exalm7659@gmail.com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3 as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Screenshot {

    public class ScreenshotBackend : Object {

        private ScreenshotProxy proxy;
        public bool can_conceal_text { get; private set; }
        public bool can_screenshot_area_with_cursor { get; private set; }

        construct {
            try {
                proxy = Bus.get_proxy_sync<ScreenshotProxy> (BusType.SESSION,
                                                             "org.gnome.Shell.Screenshot",
                                                             "/org/gnome/Shell/Screenshot");

                get_capabilities ();
            } catch (Error e) {
                error ("Couldn't get dbus proxy: %s\n", e.message);
            }
        }

        private void get_capabilities () throws Error {
            var introspectable = Bus.get_proxy_sync<IntrospectableProxy> (
                BusType.SESSION,
                "org.gnome.Shell.Screenshot",
                "/org/gnome/Shell/Screenshot"
            );
            var xml = introspectable.introspect ();

            var node = new DBusNodeInfo.for_xml (xml);
            var iface = node.lookup_interface ("org.gnome.Shell.Screenshot");
            if (iface.lookup_method ("ConcealText") != null) {
                can_conceal_text = true;
            }

            if (iface.lookup_method ("ScreenshotAreaWithCursor") != null) {
                can_screenshot_area_with_cursor = true;
            }
        }

        public async Gdk.Pixbuf? capture (CaptureType type, int delay, bool include_pointer, bool redact) throws Error {
            Gdk.Rectangle? rect = null;

            redact &= can_conceal_text;

            if (type == CaptureType.AREA) {
                rect = {};
                yield proxy.select_area (out rect.x, out rect.y, out rect.width, out rect.height);
            }

            yield sleep (get_timeout (delay, redact));

            if (redact) {
                yield proxy.conceal_text ();
                yield sleep (1000);
            }

            var pixbuf = yield get_pixbuf (rect, type, include_pointer);

            return pixbuf;
        }

        private async void sleep (int delay) {
            GLib.Timeout.add (delay, () => {
                sleep.callback ();
                return Source.REMOVE;
            });
            yield;
        }

        private int get_timeout (int delay, bool redact) {
            int timeout = delay * 1000;

            if (redact) {
                timeout -= 1000;
            }

            if (timeout < 300) {
                timeout = 300;
            }

            return timeout;
        }

        private async void screenshot_area (int x, int y, int width, int height, bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error {
            if (include_cursor && can_screenshot_area_with_cursor) {
                yield proxy.screenshot_area_with_cursor (x, y, width, height,
                                                         true, flash, filename,
                                                         out success, out filename_used);
                return;
            }

            yield proxy.screenshot_area (x, y, width, height, flash, filename,
                                         out success, out filename_used);
        }

        private async Gdk.Pixbuf? get_pixbuf (Gdk.Rectangle? rect, CaptureType type, bool include_pointer) throws Error {
            var success = false;
            var filename_used = "";
            var tmp_filename = get_tmp_filename ();

            switch (type) {
                case CaptureType.SCREEN:
                    yield proxy.screenshot (include_pointer, false, tmp_filename,
                                            out success, out filename_used);
                    break;
                case CaptureType.CURRENT_WINDOW:
                    yield proxy.screenshot_window (true, include_pointer,
                                                   false, tmp_filename,
                                                   out success, out filename_used);
                    break;
                case CaptureType.AREA:
                    if (rect == null) {
                        return null;
                    }

                    yield screenshot_area (rect.x, rect.y, rect.width, rect.height,
                                           include_pointer, false, tmp_filename,
                                           out success, out filename_used);

                    break;
            }

            if (!success) {
                return null;
            }

            play_shutter_sound ("screen-capture", _("Screenshot taken"));

            var file = File.new_for_path (filename_used);
            var stream = yield file.read_async ();
            var pixbuf = yield new Gdk.Pixbuf.from_stream_async (stream);
            yield stream.close_async ();
            yield file.delete_async ();

            return pixbuf;
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

        private string get_tmp_filename () {
            var dir = Environment.get_user_cache_dir ();
            var name = "io.elementary.screenshot-tool-%lu.png".printf (Random.next_int ());
            return Path.build_filename (dir, name);
        }
    }
}
