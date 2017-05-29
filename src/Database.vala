public class Locomotion.Database : GLib.Object {
    private static Database _db = null;
    public static unowned Database get_default () {
        if (_db == null) {
            _db = new Database ();
        }

        return _db;
    }

    public const string TABLE_STATIONS = "stations";
    public Gda.Connection connection { get; construct; }
    private const string DB_FILE = "data-0.1.db";
    private Champlain.BoundingBox current_bounding_box = null;
    private GLib.HashTable<string, Station> visible_stations;

    public signal void station_visible (Station station);
    public signal void station_hidden (Station station);

    construct {
        visible_stations = new GLib.HashTable<string, Station> (str_hash, str_equal);
        var data_dir = GLib.Path.build_filename (GLib.Environment.get_user_data_dir (), "com.github.tintou.locomotion");
        var database_dir = GLib.File.new_for_path (data_dir);
        try {
            database_dir.make_directory_with_parents (null);
        } catch (GLib.Error err) {
            if (!(err is IOError.EXISTS)) {
                critical ("Could not create data directory: %s", err.message);
            }
        }

        var db_file = database_dir.get_child ("data-0.1"+".db");
        bool new_db = !db_file.query_exists ();
        if (new_db) {
            try {
                db_file.create (FileCreateFlags.PRIVATE);
            } catch (Error e) {
                critical (e.message);
            }
        }

        try {
            connection = new Gda.Connection.from_string ("SQLite", "DB_DIR=%s;DB_NAME=%s".printf (data_dir, DB_FILE), null, Gda.ConnectionOptions.NONE);
            connection.open ();
            ensure_databases ();
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void ensure_databases () {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
        builder.select_add_target ("sqlite_master", null);
        builder.select_add_field ("name", null, null);
        var id_field = builder.add_id ("type");
        var id_value = builder.add_expr_value (null, "table");
        var id_cond = builder.add_cond (Gda.SqlOperatorType.GEQ, id_field, id_value, 0);
        builder.set_where (id_cond);

        var tables = new Gee.LinkedList<string> ();
        try {
            var data_model = connection.statement_execute_select (builder.get_statement (), null);
            var data_model_iter = data_model.create_iter ();
            for (int i = 0; data_model_iter.move_to_row (i); i++) {
                unowned GLib.Value? name_val = data_model_iter.get_value_for_field ("name");
                if (name_val != null) {
                    tables.add (name_val.get_string ());
                }
            }
        } catch (Error e) {
            critical (e.message);
        }

        if (!(TABLE_STATIONS in tables)) {
            create_stations ();
        }
    }

    private void create_stations () {
        GLib.Error error = null;
        var operation = Gda.ServerOperation.prepare_create_table (connection, TABLE_STATIONS, error,
            "name", typeof(string), Gda.ServerOperationCreateTableFlag.NOT_NULL_FLAG,
            "id", typeof(string), Gda.ServerOperationCreateTableFlag.UNIQUE_FLAG,
            "latitude", typeof(double), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
            "longitude", typeof(double), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
            "parent_id", typeof(string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
            "description", typeof(string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
            "location_type", typeof(int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
            null);
        if (error != null) {
            critical (error.message);
        }

        try {
            operation.perform_create_table ();
        } catch (Error e) {
            critical (e.message);
        }
    }

    public async void watch_box (Champlain.BoundingBox bounding_box) {
        current_bounding_box = bounding_box;
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
        builder.select_add_target (TABLE_STATIONS, null);
        builder.select_add_field ("name", null, null);
        builder.select_add_field ("id", null, null);
        builder.select_add_field ("latitude", null, null);
        builder.select_add_field ("longitude", null, null);
        builder.select_add_field ("parent_id", null, null);
        builder.select_add_field ("description", null, null);
        builder.select_add_field ("location_type", null, null);
        var latitude_left_id_field = builder.add_id ("longitude");
        var latitude_left_id_value = builder.add_expr_value (null, bounding_box.left);
        var latitude_left_id_cond = builder.add_cond (Gda.SqlOperatorType.GEQ, latitude_left_id_field, latitude_left_id_value, 0);
        var latitude_right_id_field = builder.add_id ("longitude");
        var latitude_right_id_value = builder.add_expr_value (null, bounding_box.right);
        var latitude_right_id_cond = builder.add_cond (Gda.SqlOperatorType.LEQ, latitude_right_id_field, latitude_right_id_value, 0);
        var longitude_bottom_id_field = builder.add_id ("latitude");
        var longitude_bottom_id_value = builder.add_expr_value (null, bounding_box.bottom);
        var longitude_bottom_id_cond = builder.add_cond (Gda.SqlOperatorType.GEQ, longitude_bottom_id_field, longitude_bottom_id_value, 0);
        var longitude_top_id_field = builder.add_id ("latitude");
        var longitude_top_id_value = builder.add_expr_value (null, bounding_box.top);
        var longitude_top_id_cond = builder.add_cond (Gda.SqlOperatorType.LEQ, longitude_top_id_field, longitude_top_id_value, 0);
        Gda.SqlBuilderId[] conditions = {latitude_left_id_cond, latitude_right_id_cond, longitude_bottom_id_cond, longitude_top_id_cond};
        var id_where = builder.add_cond_v (Gda.SqlOperatorType.AND, conditions);
        builder.set_where (id_where);
        try {
            var data_model = connection.statement_execute_select (builder.get_statement (), null);
            int name_column = data_model.get_column_index ("name");
            int id_column = data_model.get_column_index ("id");
            int latitude_column = data_model.get_column_index ("latitude");
            int longitude_column = data_model.get_column_index ("longitude");
            int parent_id_column = data_model.get_column_index ("parent_id");
            int description_column = data_model.get_column_index ("description");
            int location_type_column = data_model.get_column_index ("location_type");
            var data_model_iter = data_model.create_iter ();
            var stations_to_load = new GLib.HashTable<string, Station> (str_hash, str_equal);
            for (int i = 0; data_model_iter.move_to_row (i); i++) {
                unowned GLib.Value? name_val = data_model_iter.get_value_at (name_column);
                unowned GLib.Value? id_val = data_model_iter.get_value_at (id_column);
                unowned GLib.Value? latitude_val = data_model_iter.get_value_at (latitude_column);
                unowned GLib.Value? longitude_val = data_model_iter.get_value_at (longitude_column);
                unowned GLib.Value? parent_station_val = data_model_iter.get_value_at (parent_id_column);
                unowned GLib.Value? description_val = data_model_iter.get_value_at (description_column);
                unowned GLib.Value? location_type_val = data_model_iter.get_value_at (location_type_column);
                if (name_val != null && id_val != null) {
                    unowned string id = id_val.get_string ();
                    var station = new Station (id, name_val.get_string ());
                    station.latitude = latitude_val.get_double ();
                    station.longitude = longitude_val.get_double ();
                    if (parent_station_val != null) {
                        station.parent_id = parent_station_val.get_string ();
                    }

                    if (description_val != null) {
                        station.description = description_val.get_string ();
                    }

                    if (location_type_val != null) {
                        station.location_type = location_type_val.get_int ();
                    }

                    stations_to_load[id] = station;
                }
            }

            visible_stations.foreach_remove ((key, val) => {
                if (!(key in stations_to_load)) {
                    station_hidden (val);
                    return true;
                } else {
                    stations_to_load.remove (key);
                    return false;
                }
            });

            stations_to_load.foreach ((id, station) => {
                visible_stations[id] = station;
                station_visible (station);
            });
        } catch (Error e) {
            critical (e.message);
        }
    }
}
