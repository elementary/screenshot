/*
* Copyright (c) 2019 Alexander Mikhaylenko <exalm7659@gmail.com>
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
    [DBus (name = "org.freedesktop.DBus.Introspectable")]
    public interface IntrospectableProxy : Object {
        public abstract string introspect () throws Error;
    }

    [DBus (name = "org.gnome.Shell.Screenshot")]
    public interface ScreenshotProxy : Object {
        public abstract async void conceal_text () throws GLib.Error;
        public abstract async void screenshot (bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error;
        public abstract async void screenshot_window (bool include_frame, bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error;
        public abstract async void screenshot_area (int x, int y, int width, int height, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error;
        public abstract async void screenshot_area_with_cursor (int x, int y, int width, int height, bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error;
        public abstract async void select_area (out int x, out int y, out int width, out int height) throws GLib.Error;
    }
}
