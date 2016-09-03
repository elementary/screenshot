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
    public class SelectionArea : Granite.Widgets.CompositedWindow {
        public signal void captured ();
        public signal void cancelled ();

        private Gdk.Point start_point;

        private bool dragging = false;

        construct {
            type = Gtk.WindowType.POPUP;
        }

        public SelectionArea () {
            stick ();
            set_resizable (true);
            set_deletable (false);
            set_has_resize_grip (false);
            set_skip_taskbar_hint (true);
            set_skip_pager_hint (true);
            set_keep_above (true);

            var screen = get_screen ();
            set_default_size (screen.get_width (), screen.get_height ());
            add_events (Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.KEY_PRESS_MASK);

            button_press_event.connect ((e) => {
                if (dragging || e.button != 1) {
                    return true;
                }

                dragging = true;

                start_point.x = (int)e.x_root;
                start_point.y = (int)e.y_root;

                return true;
            });

            button_release_event.connect ((e) => {
                if (!dragging || e.button != 1) {
                    return true;
                }

                dragging = false;
                captured ();

                return true;
            });

            motion_notify_event.connect ((e) => {
                if (!dragging) {
                    return true;
                }

                int x = start_point.x;
                int y = start_point.y;

                int width = (x - (int)e.x_root).abs ();
                int height = (y - (int)e.y_root).abs ();
                if (width < 1 || height < 1) {
                    return true;
                }

                x = int.min (x, (int)e.x_root);
                y = int.min (y, (int)e.y_root);

                move (x, y);
                resize (width, height);

                return true;
            });

            key_press_event.connect ((e) => {
                if (e.keyval == Gdk.Key.Escape) {
                    cancelled ();
                }

                return true;
            });
        }

        public override void show_all () {
            base.show_all ();
            var manager = Gdk.Display.get_default ().get_device_manager ();
            var pointer = manager.get_client_pointer ();
            var keyboard = pointer.get_associated_device ();
            var window = get_window ();

            pointer.grab (window,
                        Gdk.GrabOwnership.NONE,
                        false,
                        Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
                        new Gdk.Cursor.for_display (window.get_display (), Gdk.CursorType.CROSSHAIR),
                        Gtk.get_current_event_time ());

            if (keyboard != null) {
                keyboard.grab (window,
                        Gdk.GrabOwnership.NONE,
                        false,
                        Gdk.EventMask.KEY_PRESS_MASK,
                        null,
                        Gtk.get_current_event_time ());
            }
        }

        public new void close () {
            get_window ().set_cursor (null);
            base.close ();
        }

        public override bool draw (Cairo.Context ctx) {
            if (!dragging) {
                return true;
            }

            int w = get_allocated_width ();
            int h = get_allocated_height ();

            ctx.rectangle (0, 0, w, h);
            ctx.set_source_rgba (0.1, 0.1, 0.1, 0.2);
            ctx.fill ();

            ctx.rectangle (0, 0, w, h);
            ctx.set_source_rgb (0.7, 0.7, 0.7);
            ctx.set_line_width (1.0);
            ctx.stroke ();

            return base.draw (ctx);
        }
    }
}
