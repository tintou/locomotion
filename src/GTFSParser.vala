public class Locomotion.GTFSParser : GLib.Object {
    GLib.File directory;
    construct {
        
    }

    public GTFSParser (GLib.File directory) {
        this.directory = directory;
    }

    public void import_stations () {
        unowned Gda.Connection connection = Locomotion.Database.get_default ().connection;
        try {
            connection.begin_transaction (null, Gda.TransactionIsolation.SERIALIZABLE);
        } catch (Error e) {
            critical (e.message);
            return;
        }

        DataInputStream dis;
        try {
            dis = new DataInputStream (directory.get_child ("stops.txt").read ());
        } catch (Error e) {
            critical (e.message);
            return;
        }

        var headers = new Gee.HashMap<string, int> ();
        string line = null;
        try {
            line = dis.read_line ();
            if (line != null) {
                var parts = line.split (",");
                for (int i = 0; i < parts.length; i++) {
                    headers[parts[i]] = i;
                }
            }

            line = dis.read_line ();
        } catch (Error e) {
            critical (e.message);
            return;
        }

        while (line != null) {
            var parts = split_line (line, headers.size);
            var id = parts[headers["stop_id"]];
            var name = parts[headers["stop_name"]];
            var latitude = double.parse (parts[headers["stop_lat"]]);
            var longitude = double.parse (parts[headers["stop_lon"]]);

            var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
            builder.set_table (Locomotion.Database.TABLE_STATIONS);
            builder.add_field_value_as_gvalue ("name", name);
            builder.add_field_value_as_gvalue ("id", id);
            builder.add_field_value_as_gvalue ("latitude", latitude);
            builder.add_field_value_as_gvalue ("longitude", longitude);
            if ("stop_desc" in headers) {
                var description = parts[headers["stop_desc"]];
                builder.add_field_value_as_gvalue ("description", description);
            }
            if ("location_type" in headers) {
                var location_type = int.parse (parts[headers["location_type"]]);
                builder.add_field_value_as_gvalue ("location_type", location_type);
            }
            if ("parent_station" in headers) {
                var parent_id = parts[headers["parent_station"]];
                builder.add_field_value_as_gvalue ("parent_id", parent_id);
            }
            Gda.Set last_insert_row;

            try {
                connection.statement_execute_non_select (builder.get_statement (), null, out last_insert_row);
            } catch (Error e) {
                critical (e.message);
            }

            try {
                line = dis.read_line ();
            } catch (Error e) {
                critical (e.message);
            }
        }

        try {
            connection.commit_transaction (null);
        } catch (Error e) {
            critical (e.message);
            return;
        }
    }
    
    private static string[] split_line (string line, int size) {
        if ("\"" in line) {
            var parts = line.split (",");
            string[] result = {};
            bool in_quote = false;
            for (int i = 0; i < parts.length; i++) {
                var part = parts[i].replace ("\"\"", "@+@quote@+@");
                int len = part.char_count ();
                part = part.replace ("\"", "");
                int single_quotes = len - part.char_count ();
                part = part.replace ("@+@quote@+@", "\"");

                bool remaining_quote = single_quotes%2 == 1;
                len = result.length;
                if (in_quote) {
                    result[len-1] = "%s,%s".printf(result[len-1], part);
                    if (remaining_quote) {
                        in_quote = false;
                    }
                } else {
                    result += part;
                    if (remaining_quote) {
                        in_quote = true;
                    }
                }
            }

            return result;
        } else {
            return line.split (",");
        }
    }
}
