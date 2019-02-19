/*
 * Copyright (C) 2017 Lains
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Quilter.Services.FileManager {
    public File tmp_file;
    public File file;
    public MainWindow win;
    public Widgets.EditView view;
    private string[] files;

    public void save_file (string path) throws Error {
        try {
            GLib.FileUtils.set_contents (path, Widgets.EditView.buffer.text);
        } catch (Error err) {
            print ("Error writing file: " + err.message);
        }
    }

    public File setup_tmp_file () {
        debug ("Setupping cache...");
        string cache_path = Path.build_filename (Environment.get_user_data_dir (), "com.github.lainsce.quilter");
        var cache_folder = File.new_for_path (cache_path);
        if (!cache_folder.query_exists ()) {
            try {
                cache_folder.make_directory_with_parents ();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        tmp_file = cache_folder.get_child ("temp.md");
        return tmp_file;
    }

    private void save_tmp_file () {
        setup_tmp_file ();
        string file_path = tmp_file.get_path ();

        debug ("Saving cache...");
        if ( tmp_file.query_exists () ) {
            try {
                tmp_file.delete();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }

        }

        try {
            save_file (file_path);
        } catch (Error e) {
            warning ("Exception found: "+ e.message);
        }
    }

    // File I/O
    public void new_file () {
        debug ("New button pressed.");
        debug ("Buffer was modified. Asking user to save first.");
        string cache = Path.build_filename (Environment.get_user_data_dir (), "com.github.lainsce.quilter" + "/temp.md");
        var dialog = new Services.DialogUtils.Dialog.display_save_confirm (Application.win);
        dialog.show ();
        dialog.response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.YES:
                    debug ("User saves the file.");

                    try {
                        Services.FileManager.save_as ();
                        var settings = AppSettings.get_default ();
                        file = File.new_for_path (cache);
                        settings.current_file = "No Documents Open";
                        view.is_modified = false;

                    } catch (Error e) {
                        warning ("Unexpected error during save: " + e.message);
                    }
                    break;
                case Gtk.ResponseType.NO:
                    debug ("User doesn't care about the file, shoot it to space.");

                    var settings = AppSettings.get_default ();
                    file = File.new_for_path (cache);
                    settings.current_file = "No Documents Open";
                    view.is_modified = false;
                    break;
                case Gtk.ResponseType.CANCEL:
                    debug ("User cancelled, don't do anything.");
                    break;
                case Gtk.ResponseType.DELETE_EVENT:
                    debug ("User cancelled, don't do anything.");
                    break;
            }
            dialog.destroy();
        });
    }

    public bool open_from_outside (MainWindow win, File[] ofiles, string hint) {
        var settings = AppSettings.get_default ();
        if (ofiles.length > 0) {
            var file = ofiles[0];
            string text;
            string file_path = file.get_path ();
            settings.current_file = file_path;
            files += file_path;
            settings.last_files = files;
            if (win.sidebar != null) {
                win.sidebar.add_file (file_path);
            }

            try {
                GLib.FileUtils.get_contents (file_path, out text);
                Widgets.EditView.buffer.text = text;
            } catch (Error e) {
                warning ("Error: %s", e.message);
            }
        }
        return true;
    }

    public void open (MainWindow win) throws Error {
        debug ("Open button pressed.");
        var settings = AppSettings.get_default ();
        var file = Services.DialogUtils.display_open_dialog ();
        string file_path = file.get_path ();
        settings.current_file = file_path;
        files += file_path;
        settings.last_files = files;
        if (win.sidebar != null) {
            win.sidebar.add_file (settings.current_file);
        }

        try {
            debug ("Opening file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                string text;
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.EditView.buffer.text = text;
            }
        } catch (Error e) {
            warning ("Unexpected error during open: " + e.message);
        }

        view.is_modified = false;
        file = null;
    }

    public void save () throws Error {
        debug ("Save button pressed.");
        var settings = AppSettings.get_default ();
        string file_path = settings.current_file;

        try {
            debug ("Saving file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                save_file (file_path);
            }
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }
        file = null;
        view.is_modified = false;
    }

    public void save_as () throws Error {
        debug ("Save as button pressed.");
        var file = Services.DialogUtils.display_save_dialog ();
        string file_path = file.get_path ();

        try {
            debug ("Saving file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                save_file (file_path);
            }
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }
        file = null;
        view.is_modified = false;
    }
}
