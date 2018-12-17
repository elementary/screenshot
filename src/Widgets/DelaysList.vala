/*
 * Copyright (c) 2011-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

namespace Screenshot.Widgets {
    public class DelaysList : Gtk.Popover {
        public signal void delay_changed (int delay);
        private Gtk.Grid selection_list;

        public DelaysList (Gtk.Widget relative_to) {
            this.relative_to = relative_to;
        }

        construct {
            var now_sec = get_timer_button(0);
            var three_sec = get_timer_button (3);
            var five_sec = get_timer_button (5);
            var ten_sec = get_timer_button (10);

            selection_list = new Gtk.Grid ();
            selection_list.orientation = Gtk.Orientation.VERTICAL;
            selection_list.add (now_sec);
            selection_list.add (three_sec);
            selection_list.add (five_sec);
            selection_list.add (ten_sec);
            selection_list.show_all ();
            add (selection_list);
        }

        private Gtk.ModelButton get_timer_button (int delay) {
            var button = new Gtk.ModelButton ();

            if (delay == 0) {
                button.text = _("Now");
            } else {
                button.text = _("in %ds").printf (delay);
            }

            button.clicked.connect (() => {
                delay_changed (delay);
                hide();
            });

            return button;
        }
    }
}

