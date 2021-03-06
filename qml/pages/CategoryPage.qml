import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../JS/dbmanager.js" as DBmanager
import "../JS/preferences.js" as Preferences


Page {
    id: page

    property string categoryName
    property int percentage
    property var expenses
    property int totalThisMonth

    function refresh() {
        model.clear()
        expenses = DBmanager.getSpentThisMonthInCategory(categoryName)
        for(var i = 0; i < expenses.length; i++)
            model.append({"amount" : expenses[i].amount, "desc" : expenses[i].desc, "date" : expenses[i].date})
    }

    function makeMeABeautifulDate(date) {
        // note: constructor takes months values (0-11)!!
        var d = new Date(parseInt(date.substring(4,8)),
                         parseInt(date.substring(2,4)-1),
                         parseInt(date.substring(0,2)))

        return Qt.formatDate(d, Qt.DefaultLocaleShortDate)
    }

    Component.onCompleted: {
        percentage = DBmanager.getPercentageForCategory(categoryName)
        totalThisMonth = DBmanager.getTotalSpentThisMonthInCategory(categoryName)
        animationTimer.running = true
        expenses = DBmanager.getSpentThisMonthInCategory(categoryName)
        for(var i = 0; i < expenses.length; i++)
            model.append({"amount" : expenses[i].amount, "desc" : expenses[i].desc, "date" : expenses[i].date})
    }

    ListModel {id: model}

    Timer {
        id: animationTimer
        interval: 40
        repeat: true
        running: false
        onTriggered: {
            if(percentIndicator.value < percentage) percentIndicator.value++;
            else stop()
        }
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Delete Category")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../components/DeleteCategoryDialog.qml"),{"category":categoryName})
                }
            }

            MenuItem {
                text: qsTr("Add Entry")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../components/NewEntryDialog.qml"),{"category":categoryName})
                    dialog.accepted.connect(function() {
                        percentIndicator.value = 0
                        percentage = DBmanager.getPercentageForCategory(categoryName)
                        animationTimer.running = true
                        totalThisMonth = DBmanager.getTotalSpentThisMonthInCategory(categoryName)
                        model.clear()
                        expenses = DBmanager.getSpentThisMonthInCategory(categoryName)
                        for(var i = 0; i < expenses.length; i++)
                            model.append({"amount" : expenses[i].amount, "desc" : expenses[i].desc, "date" : expenses[i].date})
                    })
                }
            }
        }

        contentHeight: column.height

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: categoryName
            }

            Label {
                id: moneyLabel
                text: qsTr("%1 %2", "1 is amount and 2 is currency").arg(totalThisMonth).arg(Preferences.getCurrency())
                anchors {horizontalCenter: parent.horizontalCenter}
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge*3
            }

            Label {
                anchors {horizontalCenter: parent.horizontalCenter}
                text: qsTr("in %1 this month", "subtitle of the amount spent in the CategoryView").arg(categoryName)
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
            }

        }

        ProgressBar {
            id: percentIndicator
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: column.bottom
                topMargin: Theme.paddingLarge
            }
            width: parent.width
            minimumValue: 0
            maximumValue: 100
            value: 0
            valueText: qsTr("%1 %").arg(value)
            label: qsTr("of the total", "subtitle of the percentagebar")
        }

        Label {
            id: insertionsLabel
            x: Theme.paddingLarge
            anchors {
                top: percentIndicator.bottom
                topMargin: Theme.paddingLarge*1.2
            }
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeLarge
            text: qsTr("This month:")
        }

        SilicaListView {
            id: expensesListView
            model: model
            anchors {
                top: insertionsLabel.bottom
                topMargin: Theme.paddingLarge
            }
            clip:true
            width: parent.width
            height: page.height - column.height - percentIndicator.height - insertionsLabel.height - Theme.paddingLarge*2*1.2 - Theme.paddingSmall

            delegate: BackgroundItem {
                id: delegate
                height: 100

                Row {
                    id: dateAmountRow
                    x: Theme.paddingLarge*2
                    spacing: Theme.paddingLarge

                    Label {
                        id: dateLabel
                        text: makeMeABeautifulDate(date)
                        color: Theme.primaryColor
                    }

                    Label {
                        id: amountLabel
                        text: qsTr("amount: %1 %2", "1 is amount and 2 is currency").arg(amount).arg(Preferences.getCurrency())
                        color: Theme.primaryColor
                    }
                }

                Label {
                    id: descLabel
                    text: desc
                    visible: (desc !== undefined)
                    color: Theme.highlightColor
                    x: Theme.paddingLarge*2
                    anchors {
                        top: dateAmountRow.bottom
                        topMargin: Theme.paddingSmall
                    }
                }

                onPressAndHold: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../components/DeleteEntryDialog.qml"),{"category":categoryName,"amount": amount, "desc": desc, "date": date})
                    dialog.accepted.connect(function() {
                        percentIndicator.value = 0
                        percentage = DBmanager.getPercentageForCategory(categoryName)
                        animationTimer.running = true
                        totalThisMonth = DBmanager.getTotalSpentThisMonthInCategory(categoryName)
                        refresh()
                    })
                }
            }
            VerticalScrollDecorator {}
        }
    }
}
