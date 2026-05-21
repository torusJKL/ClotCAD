#ifndef REPL_PANEL_H
#define REPL_PANEL_H

#include <Standard_WarningsDisable.hxx>
#include <QDockWidget>
#include <QPlainTextEdit>
#include <QVBoxLayout>
#include <QSplitter>
#include <QStringList>
#include <QKeyEvent>
#include <QTextCursor>
#include <Standard_WarningsRestore.hxx>

typedef void (*eval_fn)(const char* code, char* result, int maxlen);

class REPLPanel : public QDockWidget
{
  Q_OBJECT
public:
  REPLPanel(QWidget* parent = nullptr);

  void setEvalCallback(eval_fn fn) { myEvalCallback = fn; }
  void setHistoryModifier(int mod) { myHistoryModifier = mod; }
  void setSubmitModifier(int mod) { mySubmitModifier = mod; }
  void appendOutput(const QString& text);

public slots:
  void appendOutputSafe(const QString& text);

protected:
  bool eventFilter(QObject* obj, QEvent* event) override;
  void keyPressEvent(QKeyEvent* event) override;

private slots:
  void onInputSubmitted();

private:
  QPlainTextEdit* myOutput;
  QPlainTextEdit* myInput;
  QStringList myHistory;
  int myHistoryIndex = -1;
  int myHistoryModifier = Qt::ControlModifier;
  int mySubmitModifier = Qt::NoModifier;
  eval_fn myEvalCallback = nullptr;
};

#endif
