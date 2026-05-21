#include "repl_panel.h"
#include <QApplication>

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
  layout->setSpacing(0);

  myOutput = new QPlainTextEdit(container);
  myOutput->setReadOnly(true);
  myOutput->setFont(QFont("Courier New", 10));
  myOutput->setMaximumBlockCount(MAX_OUTPUT_LINES);
  myOutput->setLineWrapMode(QPlainTextEdit::NoWrap);

  myInput = new QPlainTextEdit(container);
  myInput->setPlaceholderText(">  (enter Lisp expression)");
  myInput->setFont(QFont("Courier New", 10));
  myInput->setMaximumBlockCount(100);
  myInput->setTabChangesFocus(false);
  myInput->installEventFilter(this);

  QSplitter* splitter = new QSplitter(Qt::Vertical, container);
  splitter->addWidget(myOutput);
  splitter->addWidget(myInput);
  splitter->setStretchFactor(0, 1);
  splitter->setStretchFactor(1, 0);
  splitter->setSizes({300, myInput->fontMetrics().lineSpacing() * 3 + 4});
  layout->addWidget(splitter);

  setWidget(container);
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

bool REPLPanel::eventFilter(QObject* obj, QEvent* event)
{
  if (obj == myInput && event->type() == QEvent::KeyPress)
  {
    QKeyEvent* keyEvent = static_cast<QKeyEvent*>(event);

    if (keyEvent->key() == Qt::Key_Return || keyEvent->key() == Qt::Key_Enter)
    {
      Qt::KeyboardModifiers mods = keyEvent->modifiers();

      if (mods == Qt::ShiftModifier)
      {
        QTextCursor cursor = myInput->textCursor();
        cursor.insertText("\n");
        event->accept();
        return true;
      }

      if (mods == static_cast<Qt::KeyboardModifier>(mySubmitModifier))
      {
        onInputSubmitted();
        event->accept();
        return true;
      }

      return false;
    }

    if (keyEvent->key() == Qt::Key_Up &&
        keyEvent->modifiers() == static_cast<Qt::KeyboardModifier>(myHistoryModifier))
    {
      if (!myHistory.isEmpty() && myHistoryIndex > 0)
      {
        myHistoryIndex--;
        myInput->setPlainText(myHistory[myHistoryIndex]);
        myInput->moveCursor(QTextCursor::End);
      }
      event->accept();
      return true;
    }

    if (keyEvent->key() == Qt::Key_Down &&
        keyEvent->modifiers() == static_cast<Qt::KeyboardModifier>(myHistoryModifier))
    {
      if (myHistoryIndex < myHistory.size() - 1)
      {
        myHistoryIndex++;
        myInput->setPlainText(myHistory[myHistoryIndex]);
        myInput->moveCursor(QTextCursor::End);
      }
      else
      {
        myHistoryIndex = myHistory.size();
        myInput->clear();
      }
      event->accept();
      return true;
    }

    if (keyEvent->key() == Qt::Key_Tab)
    {
      QTextCursor cursor = myInput->textCursor();
      cursor.insertText("  ");
      event->accept();
      return true;
    }
  }

  return QDockWidget::eventFilter(obj, event);
}

void REPLPanel::keyPressEvent(QKeyEvent* event)
{
  QDockWidget::keyPressEvent(event);
}

void REPLPanel::onInputSubmitted()
{
  QString code = myInput->toPlainText();
  if (code.trimmed().isEmpty())
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
