public class Locomotion.Application : Gtk.Application {
    public Application () {
        Object(application_id: "com.github.tintou.locomotion",
                flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void activate () {
        // Create the window of this application and show it
        var window = new Locomotion.Window (this);
        window.show_all ();
    }

    public static int main (string[] args) {
        Locomotion.Application app = new Locomotion.Application ();
        Gda.init ();
        Clutter.init (ref args);
        return app.run (args);
    }
}
