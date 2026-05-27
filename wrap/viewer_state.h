#ifndef VIEWER_STATE_H
#define VIEWER_STATE_H

#include <AIS_InteractiveContext.hxx>
#include <AIS_Shape.hxx>
#include <AIS_Trihedron.hxx>
#include <AIS_ViewCube.hxx>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "occt_viewer.h"

class ViewerWindow;
class ViewerWidget;

struct ViewerState {
  ViewerWindow* window = nullptr;
  ViewerWidget* widget = nullptr;

  Handle(AIS_InteractiveContext) context;

  std::map<std::string, Handle(AIS_Shape), std::less<>> shapes;
  std::vector<std::string> shape_names;

  // Reverse map: AIS_Shape* raw pointer → shape name
  std::map<Standard_Transient*, std::string> obj_to_name;

  Handle(AIS_Trihedron) axisTrihedron;
  Handle(AIS_ViewCube) viewCube;
  int currentOrientation = 0;

  // Callbacks
  eval_fn eval_callback = nullptr;
  file_op_fn file_op_callback = nullptr;
  drain_fn drain_callback = nullptr;
  color_scheme_fn color_scheme_callback = nullptr;
  visibility_fn visibility_callback = nullptr;
  selection_changed_fn selection_callback = nullptr;
  tree_selection_fn tree_callback = nullptr;
  viewcube_fn viewcube_callback = nullptr;

  // Mouse selection schemes: key = button | (flags << 16), value = AIS_SelectionScheme
  std::map<unsigned int, int> mouse_schemes;

  // Running state
  bool running = false;

  // Window state
  int maximized = 0;
};

#endif
