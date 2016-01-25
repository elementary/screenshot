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
    
    /**
     *  Code stolen from Eidete program with some adjustments.
     */
    public class SelectionArea : Granite.Widgets.CompositedWindow {

        private int[,] pos;

        public int x;
        public int y;
        public int w;
        public int h;

        public SelectionArea () {

            stick ();
            set_resizable (true);
            set_deletable (false);
            set_has_resize_grip (false);
            set_default_geometry (640, 480);
            set_type_hint (Gdk.WindowTypeHint.DIALOG);
            events = Gdk.EventMask.BUTTON_MOTION_MASK | Gdk.EventMask.BUTTON1_MOTION_MASK | 
                     Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK ;
            set_skip_taskbar_hint (true);
            set_skip_pager_hint (true);
			
            button_press_event.connect ((e) => {
                Gdk.WindowEdge [] dir = {Gdk.WindowEdge.NORTH_WEST,
                                         Gdk.WindowEdge.NORTH,Gdk.WindowEdge.NORTH_EAST,
                                         Gdk.WindowEdge.EAST,Gdk.WindowEdge.SOUTH_EAST,Gdk.WindowEdge.SOUTH,
                                         Gdk.WindowEdge.SOUTH_WEST,Gdk.WindowEdge.WEST};

                for (var i=0;i<8;i++){
                    if (in_quad (pos[i,0]-12, pos[i,1]-10, 24, 24, (int) e.x, (int) e.y)){
                        begin_resize_drag (dir[i], (int) e.button, (int) e.x_root, (int) e.y_root, e.time);

                        return false;
                    }
                }
                begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);

                return false;
            });

            configure_event.connect ((e) => {

                /**
                 *  Check if coordinates are out of the screen and check
                 *  if coordinate + width/height is out of the screen, then
                 *  adjust coordinates to keep width and height (and aspect
                 *  ratio) intact.
                 */
                if(e.x < 0 || e.x > e.window.get_screen().get_width()) {
                    x = 0;
                } else if (e.x + e.width > e.window.get_screen().get_width() && e.width < e.window.get_screen().get_width()) {
                    x = e.window.get_screen().get_width() - e.width;
                } else {
                    x = e.x;
                }

                if(e.y < 0) {
                    y = 0;
                } else if (e.y + e.height >= e.window.get_screen().get_height() && e.height < e.window.get_screen().get_height()) {
                    y = e.window.get_screen().get_height() - e.height - 1;
                } else {
                    y = e.y;
                }

                /**
                 *  Just in case an edge is still outside of the screen
                 *  we'll modify the width/height if thats the case.
                 */
                if (x + e.width > e.window.get_screen().get_width()) {
                    w = e.window.get_screen ().get_width() - x;
                } else {
                    w = e.width;
                }

                if(y + e.height > e.window.get_screen().get_height()) {
                    h = e.window.get_screen().get_height() - y;
                } else {
                    h = e.height;
                }

                return false;
            });
        }

        private bool in_quad (int qx, int qy, int qh, int qw, int x, int y){
            return ((x>qx) && (x<(qx+qw)) && (y>qy) && (y<qy+qh));
        }

        public override bool draw (Cairo.Context ctx){

            int w = this.get_allocated_width    ();
            int h = this.get_allocated_height   ();
            int r = 12;

            pos = {{1, 1},      // upper left
                   {w/2, 1},    // upper midpoint
                   {w-1, 1},    // upper right
                   {w-1, h/2},  // right midpoint
                   {w-1, h-1},  // lower right
                   {w/2, h-1},  // lower midpoint
                   {1, h-1},    // lower left
                   {1, h/2}};   // left midpoint

            ctx.rectangle (0, 0, w, h);
            ctx.set_source_rgba (0.1, 0.1, 0.1, 0.2);
            ctx.fill ();

            for (var i=0;i<8;i++){
                ctx.arc (pos[i,0], pos[i,1], r, 0.0, 2*3.14);
                ctx.set_source_rgb (0.7, 0.7, 0.7);
                ctx.fill ();
            }
            ctx.rectangle (0, 0, w, h);
            ctx.set_source_rgb (0.7, 0.7, 0.7);
            ctx.set_line_width (1.0);
            ctx.stroke ();

            return base.draw (ctx);
        }
    }
}
