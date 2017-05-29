project('com.github.tintou.locomotion', ['vala', 'c'])

i18n = import('i18n')
gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="com.github.tintou.locomotion"', language : 'c')

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk+-3.0')
champlain_gtk_dep = dependency('champlain-gtk-0.12')
champlain_dep = dependency('champlain-0.12')
clutter_dep = dependency('clutter-1.0')
clutter_gtk_dep = dependency('clutter-gtk-1.0')
libarchive_dep = dependency('libarchive')
gee_dep = dependency('gee-0.8')
json_dep = dependency('json-glib-1.0')
gda_dep = dependency('libgda-5.0')
geoclue_dep = dependency('libgeoclue-2.0')

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

sources = ['src/Application.vala',
           'src/Window.vala',
           'src/GTFSParser.vala',
           'src/Objects/Station.vala',
           'src/Database.vala',
           'src/Map.vala',
           'src/StationMarker.vala']
deps = [glib_dep,
        gobject_dep,
        gtk_dep,
        champlain_gtk_dep,
        champlain_dep,
        clutter_dep,
        clutter_gtk_dep,
        libarchive_dep,
        gee_dep,
        json_dep,
        gda_dep,
        geoclue_dep]

icon_resources = gnome.compile_resources('icons', 'data/icons/icons.gresource.xml', source_dir : 'data/icons/')

executable('com.github.tintou.locomotion', sources, icon_resources, dependencies : deps, install : true)

subdir('data')
