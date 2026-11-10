#ifndef FILTERCONTAINERFILTER_H
#define FILTERCONTAINERFILTER_H

#include "filter.h"
#include "filtercontainer.h"
#include <QObject>  // NOTE (PCP Qt): direct include required by Qt 5.6 moc

namespace qqsfpm {

class FilterContainerFilter : public Filter, public FilterContainer {
    Q_OBJECT
    Q_INTERFACES(qqsfpm::FilterContainer)
    Q_PROPERTY(QQmlListProperty<qqsfpm::Filter> filters READ filtersListProperty NOTIFY filtersChanged)
    Q_CLASSINFO("DefaultProperty", "filters")

public:
    using Filter::Filter;

    void proxyModelCompleted(const QQmlSortFilterProxyModel& proxyModel) override;

Q_SIGNALS:
    void filtersChanged();

private:
    void onFilterAppended(Filter* filter) override;
    void onFilterRemoved(Filter* filter) override;
    void onFiltersCleared() override;
};

}

#endif // FILTERCONTAINERFILTER_H
