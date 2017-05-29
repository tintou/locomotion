public class Locomotion.Window : Gtk.ApplicationWindow {
    Locomotion.Map map_widget;

    construct {
        icon_name = "com.github.tintou.locomotion";
        title = "Locomotion";
        height_request = 400;
        width_request = 300;
        window_position = Gtk.WindowPosition.CENTER;

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/tintou/locomotion");
        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        var grid = new Gtk.Grid ();
        grid.width_request = 100;
        map_widget = new Locomotion.Map ();
        paned.pack1 (grid, false, false);
        paned.pack2 (map_widget, true, false);
        add (paned);
    }

    public Window (Gtk.Application app) {
        Object (application: app);
        set_default_size (450, 70);
        go_to_current_location.begin ();
        populate.begin ();
    }

    public async void populate () {
        var data_dir = GLib.Path.build_filename (GLib.Environment.get_user_data_dir (), "com.github.tintou.locomotion", "GTFS", "RATP");
        var parser = new GTFSParser (GLib.File.new_for_path (data_dir));
        //parser.import_stations ();
    }

    private async void go_to_current_location () {
        try {
            var geoclue = yield new GClue.Simple ("com.github.tintou.locomotion", GClue.AccuracyLevel.EXACT, null);
            var location = geoclue.get_location ();
            map_widget.champlain_view.center_on (location.latitude, location.longitude);
        } catch (Error e) {
            critical (e.message);
        }
    }
}
