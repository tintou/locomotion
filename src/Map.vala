public class Locomotion.Map : GtkChamplain.Embed {
    Champlain.MarkerLayer marker_layer;
    unowned Database database;
    public Map () {
        
    }

    construct {
        height_request = 200;
        width_request = 100;
        champlain_view.keep_center_on_resize = true;
        champlain_view.zoom_level = 15;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;

        marker_layer = new Champlain.MarkerLayer ();
        champlain_view.add_layer (marker_layer);

        database = Database.get_default ();
        database.station_visible.connect ((station) => {
            var marker = new StationMarker (station);
            marker_layer.add_marker (marker);
            marker.animate_in ();
        });

        database.station_hidden.connect ((station) => {
            marker_layer.get_markers ().foreach ((marker) => {
                if (marker is StationMarker) {
                    if (((StationMarker) marker).station == station) {
                        marker_layer.remove_marker (marker);
                    }
                }
            });
        });

        champlain_view.layer_relocated.connect (map_relocated);
        button_release_event.connect ((event) => {
            if (event.button == Gdk.BUTTON_PRIMARY) {
                map_relocated ();
            }

            return false;
        });
    }

    private void map_relocated () {
        if (champlain_view.zoom_level <= 14) {
            var zero_box = new Champlain.BoundingBox ();
            zero_box.left = zero_box.right = zero_box.top = zero_box.bottom = 0;
            database.watch_box.begin (zero_box);
            return;
        }

        var bounding_box = champlain_view.get_bounding_box ();
        var removable_markers = new Gee.LinkedList<Champlain.Marker> ();
        marker_layer.get_markers ().foreach ((marker) => {
            if (!bounding_box.covers (marker.latitude, marker.longitude)) {
                removable_markers.add (marker);
            }
        });

        foreach (var marker in removable_markers) {
            marker_layer.remove_marker (marker);
        }

        database.watch_box.begin (bounding_box);
    }
}
