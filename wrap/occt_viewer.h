#ifndef OCCT_VIEWER_H
#define OCCT_VIEWER_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void* occt_viewer;
typedef void* occt_shape;

typedef struct {
  const char* name;
  void* shape_ptr;
  int checked;
  int show_in_tree;
  int shape_changed;
} ShapeSyncItem;

// --- Lifecycle ---
occt_viewer viewer_create(const char* title, int width, int height);
void        viewer_destroy(occt_viewer vwr);
void        viewer_show(occt_viewer vwr);
void        viewer_run(occt_viewer vwr);
void        viewer_quit(occt_viewer vwr);
int         viewer_is_running(occt_viewer vwr);

// --- Inter-thread wake ---
void viewer_post_event(occt_viewer vwr);
void viewer_post_event_delayed(occt_viewer vwr, int ms);
void viewer_redraw(occt_viewer vwr);

// --- Shapes ---
void viewer_sync_shapes(occt_viewer vwr, ShapeSyncItem* items, int count);
void viewer_fit_all(occt_viewer vwr);

// --- Callbacks ---
typedef void (*eval_fn)(const char* code, char* result, int maxlen);
void viewer_set_eval_callback(occt_viewer vwr, eval_fn fn);
typedef void (*file_op_fn)(const char* path, int op);
void viewer_set_file_op_callback(occt_viewer vwr, file_op_fn fn);
typedef void (*drain_fn)(void);
void viewer_set_drain_callback(occt_viewer vwr, drain_fn fn);

// --- REPL ---
void viewer_append_repl_output(occt_viewer vwr, const char* text);
void viewer_set_repl_history_modifier(occt_viewer vwr, int mod);
void viewer_set_repl_submit_modifier(occt_viewer vwr, int mod);

// --- Scene tree ---
void viewer_set_shape_visible(occt_viewer vwr, const char* name, int visible);
typedef void (*visibility_fn)(const char* name, int visible);
void viewer_set_visibility_callback(occt_viewer vwr, visibility_fn fn);

// --- Status bar ---
void viewer_set_status_text(occt_viewer vwr, const char* text);
void viewer_set_import_status(occt_viewer vwr, int show, int current, int total);

// --- Grid ---
void viewer_show_grid(occt_viewer vwr, int show);
int  viewer_is_grid_visible(occt_viewer vwr);

// --- Axis ---
void viewer_show_axis(occt_viewer vwr, int show);
int  viewer_is_axis_visible(occt_viewer vwr);

// --- ViewCube ---
void viewer_show_viewcube(occt_viewer vwr, int show);
int  viewer_is_viewcube_visible(occt_viewer vwr);
void viewer_set_view(occt_viewer vwr, int orientation);
int  viewer_get_view_orientation(occt_viewer vwr);
typedef void (*viewcube_fn)(int orientation);
void viewer_set_viewcube_callback(occt_viewer vwr, viewcube_fn fn);
void viewer_set_viewcube_color(occt_viewer vwr, double r, double g, double b);
void viewer_set_viewcube_text_color(occt_viewer vwr, double r, double g, double b);
void viewer_set_viewcube_inner_color(occt_viewer vwr, double r, double g, double b);
void viewer_set_viewcube_transparency(occt_viewer vwr, double t);
void viewer_set_viewcube_size(occt_viewer vwr, double size);
void viewer_set_viewcube_axis_color(occt_viewer vwr, int part, double r, double g, double b);
void viewer_set_viewcube_draw_axes(occt_viewer vwr, int show);
int  viewer_get_viewcube_draw_axes(occt_viewer vwr);
void viewer_set_viewcube_hilight_color(occt_viewer vwr, double r, double g, double b);

// --- Dock panels ---
void viewer_show_dock(occt_viewer vwr, const char* dock_name, int show);

// --- Quality ---
void viewer_set_antialiasing(occt_viewer vwr, int enable);

// --- Theme ---
void viewer_set_stylesheet(occt_viewer vwr, const char* qss);
void viewer_set_icon_palette(occt_viewer vwr, const char* fg_color);
int  viewer_color_scheme(occt_viewer vwr);
typedef void (*color_scheme_fn)(int scheme);
void viewer_set_color_scheme_callback(occt_viewer vwr, color_scheme_fn fn);
void* viewer_get_view(occt_viewer vwr);
void* viewer_get_trihedron(occt_viewer vwr);
void viewer_set_trihedron_text_color(occt_viewer vwr, int part, double r, double g, double b);
void viewer_set_placeholder_color(occt_viewer vwr, int r, int g, int b);

// --- Selection ---
void* viewer_get_context(occt_viewer vwr);
void* viewer_get_ais_object(occt_viewer vwr, const char* name);
typedef void (*selection_changed_fn)(void);
void viewer_set_selection_callback(occt_viewer vwr, selection_changed_fn fn);
typedef void (*tree_selection_fn)(const char** names, int count);
void viewer_set_tree_selection_callback(occt_viewer vwr, tree_selection_fn fn);
void viewer_set_mouse_selection_scheme(occt_viewer vwr, int key, int scheme);
void viewer_sync_tree_selection(occt_viewer vwr);
void viewer_select_names(occt_viewer vwr, const char** names, int count);
int  viewer_is_shape_selected(occt_viewer vwr, const char* name);

#ifdef __cplusplus
}
#endif

#endif
