public class Locomotion.Station : GLib.Object {
    public string id { get; construct; }
    public string name { get; construct; }
    public string parent_id { get; set; }
    public string description { get; set; }
    public int location_type { get; set; }

    public double latitude { get; set; }
    public double longitude { get; set; }

    construct {
        
    }

    public Station (string id, string name) {
        Object (id: id, name: name);
    }
}
