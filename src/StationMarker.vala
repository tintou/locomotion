public class Locomotion.StationMarker : Champlain.Marker {

    public Station station { get; construct; }

    private static Gdk.Pixbuf marker_pixbuf = null;
    private Gtk.Image image;
    private Gtk.Popover popover = null;

    public StationMarker (Station station) {
        Object (station: station);
    }

    construct {
        draggable = false;
        selectable = true;
        image = new Gtk.Image ();
        image.halign = Gtk.Align.CENTER;
        image.valign = Gtk.Align.END;
        if (marker_pixbuf == null) {
            try {
                weak Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                var scale = image.get_style_context ().get_scale ();
                marker_pixbuf = icon_theme.load_icon_for_scale ("location-marker-station", 24, scale, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            } catch (Error e) {
                critical (e.message);
            }
        }

        image.get_style_context ().set_scale (1);
        image.gicon = marker_pixbuf;
        var eventbox = new Gtk.EventBox ();
        eventbox.halign = Gtk.Align.CENTER;
        eventbox.valign = Gtk.Align.END;
        eventbox.add (image);
        eventbox.show_all ();
        var actor = new GtkClutter.Actor.with_contents (eventbox);
        add_child (actor);
        latitude = station.latitude;
        longitude = station.longitude;
        translation_x = -actor.get_width ()/2;
        translation_y = -actor.get_height ();
        
        eventbox.events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        eventbox.button_release_event.connect (() => {
            Idle.add (() => {
                if (popover == null) {
                    popover = new Gtk.Popover (image);
                    popover.modal = true;
                    var grid = new Gtk.Grid ();
                    grid.orientation = Gtk.Orientation.VERTICAL;
                    grid.margin = 6;
                    var label = new Gtk.Label (station.name);
                    label.get_style_context ().add_class ("h3");
                    label.xalign = 0;
                    var desc_label = new Gtk.Label (station.description);
                    desc_label.xalign = 0;
                    grid.add (label);
                    grid.add (desc_label);
                    popover.add (grid);
                }

                popover.show_all ();
                return GLib.Source.REMOVE;
            });

            return false;
        });
    }
}
