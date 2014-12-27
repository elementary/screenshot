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

using Gtk;
using Gdk;
using Granite;

namespace Screenshot {

    public class ScreenshotApp : Granite.Application {

        private static ScreenshotApp app;
        private ScreenshotWindow window = null;

        construct {

            // App info
            build_version = Build.VERSION;
            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKGDATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version_info = Build.VERSION_INFO;

            program_name = "Screenshot";
            exec_name = "screenshot";

            app_years = "2014-2015";
            application_id = "net.launchpad.screenshot";
            app_icon = "applets-screenshooter";
            app_launcher = "screenshot.desktop";

            main_url = "https://launchpad.net/screenshot";
            bug_url = "https://bugs.launchpad.net/screenshot";
            help_url = "https://answers.launchpad.net/screenshot";
            translate_url = "https://translations.launchpad.net/screenshot";
        
            about_authors = {"Fabio Zaramella <ffabio.96.x@gmail.com>"};
            about_documenters = {"Fabio Zaramella <ffabio.96.x@gmail.com>"};
            about_artists = {"Fabio Zaramella"};
            about_comments = _("Save images of your screen or individual windows.");
            about_translators = "";
            about_license_type = Gtk.License.GPL_3_0;
        }

        protected override void activate () {
                        
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
    }
}
