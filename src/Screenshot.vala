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

namespace Screenshot {

    public class ScreenshotApp : Granite.Application {

        private static ScreenshotApp app;
        private ScreenshotWindow window = null;

        private int action = 0;
        private int delay = 1;
        private bool grab_pointer = false;

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;

            // App info
            build_version = Build.VERSION;
            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKGDATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version_info = Build.VERSION_INFO;

            program_name = _("Screenshot");
            exec_name = "screenshot";

            app_years = "2014-2016";
            application_id = "net.launchpad.screenshot";
            app_icon = "applets-screenshooter";
            app_launcher = "screenshot.desktop";

            main_url = "https://launchpad.net/screenshot-tool";
            bug_url = "https://bugs.launchpad.net/screenshot-tool";
            help_url = "https://answers.launchpad.net/screenshot-tool";
            translate_url = "https://translations.launchpad.net/screenshot-tool";

            about_authors = {"Fabio Zaramella <ffabio.96.x@gmail.com>"};
            about_documenters = {"Fabio Zaramella <ffabio.96.x@gmail.com>"};
            about_artists = {"Fabio Zaramella"};
            about_comments = _("Save images of your screen or individual windows.");
            about_translators = "";
            about_license_type = Gtk.License.GPL_3_0;
        }

        protected override void activate () {
            this.hold ();
            stdout.printf ("activated\n");
            this.release ();
        }

        private void normal_startup () {
            if (window != null) {
                window.present (); // present window if app is already open
                return;
            }

            window = new ScreenshotWindow ();
            window.set_application (this);
            window.show_all ();
        }

        public static ScreenshotApp get_instance () {
            if (app == null)
                app = new ScreenshotApp ();

            return app;
        }

    	public static int main (string[] args) {
            // Init internationalization support
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Build.GETTEXT_PACKAGE);

            Gtk.init (ref args);
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

            app = new ScreenshotApp ();

            if (args[1] == "-s") {
                return 0;
            }

            return app.run (args);
        }

        private int _command_line (ApplicationCommandLine command_line) {
            OptionEntry[] options = new OptionEntry[3];
            options[0] = { "action", 0, 0, OptionArg.INT, ref action, "Action to do", null};
            options[1] = { "delay", 0, 0, OptionArg.INT, ref delay, "Delay before taking the screenshot", null };
            options[2] = { "grab-pointer", 0, 0, OptionArg.NONE, ref grab_pointer, "Grab pointer in screen?", null };

            add_main_option_entries (options);

            string[] args = command_line.get_arguments ();
            string*[] _args = new string[args.length];
            for (int i = 0; i < args.length; i++) {
                _args[i] = args[i];
            }

            try {
                var opt_context = new OptionContext ("- Screenhot tool");
                opt_context.set_help_enabled (true);
                opt_context.add_main_entries (options, null);

                unowned string[] tmp = _args;
                opt_context.parse (ref tmp);
            } catch (OptionError e) {
                command_line.print ("error: %s\n", e.message);
                command_line.print ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
                return 0;
            }

            if (action == 0) {
                normal_startup ();
            } else {
                window = new ScreenshotWindow.from_cmd (action, delay, grab_pointer);
                window.set_application (this);
                window.show_all ();

                if (action != 3) {
                    window.take_clicked ();
                } else {
                    window.present ();
                }
            }

            return 0;
        }

        public override int command_line (ApplicationCommandLine commmand_line) {
            this.hold ();
            int res = _command_line (commmand_line);
            this.release ();

            return res;
        }
    }
}
