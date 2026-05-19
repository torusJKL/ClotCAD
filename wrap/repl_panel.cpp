#include "repl_panel.h"

static const int MAX_OUTPUT_LINES = 10000;

REPLPanel::REPLPanel(QWidget* parent)
  : QDockWidget(tr("REPL"), parent)
{
  setObjectName("REPLPanel");
  setFeatures(QDockWidget::DockWidgetClosable | QDockWidget::DockWidgetMovable);
  setMinimumWidth(200);
  setAllowedAreas(Qt::RightDockWidgetArea | Qt::LeftDockWidgetArea);

  QWidget* container = new QWidget(this);
  QVBoxLayout* layout = new QVBoxLayout(container);
  layout->setContentsMargins(4, 4, 4, 4);
  layout->setSpacing(4);

  myOutput = new QPlainTextEdit(container);
  myOutput->setReadOnly(true);
  myOutput->setFont(QFont("Courier New", 10));
  myOutput->setMaximumBlockCount(MAX_OUTPUT_LINES);
  myOutput->setLineWrapMode(QPlainTextEdit::NoWrap);
  layout->addWidget(myOutput, 1);

  myInput = new QLineEdit(container);
  myInput->setPlaceholderText(">  (enter Lisp expression)");
  myInput->setFont(QFont("Courier New", 10));
  layout->addWidget(myInput);

  setWidget(container);
  connect(myInput, &QLineEdit::returnPressed, this, &REPLPanel::onInputSubmitted);
}

void REPLPanel::appendOutput(const QString& text)
{
  myOutput->moveCursor(QTextCursor::End);
  myOutput->insertPlainText(text);
  myOutput->moveCursor(QTextCursor::End);
}

void REPLPanel::appendOutputSafe(const QString& text)
{
  appendOutput(text);
}

void REPLPanel::onInputSubmitted()
{
  QString code = myInput->text();
  if (code.isEmpty())
    return;

  myHistory.append(code);
  if (myHistory.size() > 1000)
    myHistory.removeFirst();
  myHistoryIndex = myHistory.size();

  myOutput->appendPlainText("> " + code);
  myOutput->moveCursor(QTextCursor::End);

  if (myEvalCallback)
  {
    char result[4096] = {};
    QByteArray codeUtf8 = code.toUtf8();
    myEvalCallback(codeUtf8.constData(), result, sizeof(result));
    myOutput->appendPlainText(QString::fromUtf8(result));
    myOutput->moveCursor(QTextCursor::End);
  }

  myInput->clear();
}

void REPLPanel::keyPressEvent(QKeyEvent* event)
{
  if (event->key() == Qt::Key_Up && myInput->hasFocus())
  {
    if (!myHistory.isEmpty() && myHistoryIndex > 0)
    {
      myHistoryIndex--;
      myInput->setText(myHistory[myHistoryIndex]);
    }
    event->accept();
    return;
  }
  if (event->key() == Qt::Key_Down && myInput->hasFocus())
  {
    if (myHistoryIndex < myHistory.size() - 1)
    {
      myHistoryIndex++;
      myInput->setText(myHistory[myHistoryIndex]);
    }
    else
    {
      myHistoryIndex = myHistory.size();
      myInput->clear();
    }
    event->accept();
    return;
  }
  QDockWidget::keyPressEvent(event);
}
