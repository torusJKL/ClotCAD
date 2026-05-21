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

// --- Scene tree ---
void viewer_set_shape_visible(occt_viewer vwr, const char* name, int visible);
typedef void (*visibility_fn)(const char* name, int visible);
void viewer_set_visibility_callback(occt_viewer vwr, visibility_fn fn);

// --- Status bar ---
void viewer_set_status_text(occt_viewer vwr, const char* text);

// --- Grid ---
void viewer_show_grid(occt_viewer vwr, int show);
int  viewer_is_grid_visible(occt_viewer vwr);

// --- Axis ---
void viewer_show_axis(occt_viewer vwr, int show);
int  viewer_is_axis_visible(occt_viewer vwr);

// --- Dock panels ---
void viewer_show_dock(occt_viewer vwr, const char* dock_name, int show);

// --- Quality ---
void viewer_set_antialiasing(occt_viewer vwr, int enable);

// --- Theme ---
void viewer_set_stylesheet(occt_viewer vwr, const char* qss);
int  viewer_color_scheme(occt_viewer vwr);
typedef void (*color_scheme_fn)(int scheme);
void viewer_set_color_scheme_callback(occt_viewer vwr, color_scheme_fn fn);
void* viewer_get_view(occt_viewer vwr);
void* viewer_get_trihedron(occt_viewer vwr);
void viewer_set_placeholder_color(occt_viewer vwr, int r, int g, int b);

#ifdef __cplusplus
}
#endif

#endif
