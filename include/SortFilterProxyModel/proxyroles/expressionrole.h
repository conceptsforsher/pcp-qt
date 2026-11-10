#ifndef EXPRESSIONROLE_H
#define EXPRESSIONROLE_H

#include "singlerole.h"
#include <QQmlScriptString>
#include <QObject>  // NOTE (PCP Qt): direct include required by Qt 5.6 moc

class QQmlExpression;

namespace qqsfpm {

class ExpressionRole : public SingleRole
{
    Q_OBJECT
    Q_PROPERTY(QQmlScriptString expression READ expression WRITE setExpression NOTIFY expressionChanged)

public:
    using SingleRole::SingleRole;

    const QQmlScriptString& expression() const;
    void setExpression(const QQmlScriptString& scriptString);

    void proxyModelCompleted(const QQmlSortFilterProxyModel& proxyModel) override;

Q_SIGNALS:
    void expressionChanged();

private:
    QVariant data(const QModelIndex& sourceIndex, const QQmlSortFilterProxyModel& proxyModel) override;
    void updateContext(const QQmlSortFilterProxyModel& proxyModel);
    void updateExpression();

    QQmlScriptString m_scriptString;
    QQmlExpression* m_expression = nullptr;
    QQmlContext* m_context = nullptr;
};

}

#endif // EXPRESSIONROLE_H
