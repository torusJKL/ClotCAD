#ifndef REPL_PANEL_H
#define REPL_PANEL_H

#include <Standard_WarningsDisable.hxx>
#include <QDockWidget>
#include <QPlainTextEdit>
#include <QLineEdit>
#include <QVBoxLayout>
#include <QStringList>
#include <QKeyEvent>
#include <QTimer>
#include <QTextCursor>
#include <Standard_WarningsRestore.hxx>

typedef void (*eval_fn)(const char* code, char* result, int maxlen);

class REPLPanel : public QDockWidget
{
  Q_OBJECT
public:
  REPLPanel(QWidget* parent = nullptr);

  void setEvalCallback(eval_fn fn) { myEvalCallback = fn; }
  void appendOutput(const QString& text);

public slots:
  void appendOutputSafe(const QString& text);

protected:
  void keyPressEvent(QKeyEvent* event) override;

private slots:
  void onInputSubmitted();

private:
  QPlainTextEdit* myOutput;
  QLineEdit* myInput;
  QStringList myHistory;
  int myHistoryIndex = -1;
  eval_fn myEvalCallback = nullptr;
};

#endif
