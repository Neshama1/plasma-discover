/***************************************************************************
 *   Copyright © 2015 Aleix Pol Gonzalez <aleixpol@blue-systems.com>       *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or         *
 *   modify it under the terms of the GNU General Public License as        *
 *   published by the Free Software Foundation; either version 2 of        *
 *   the License or (at your option) version 3 or any later version        *
 *   accepted by the membership of KDE e.V. (or its successor approved     *
 *   by the membership of KDE e.V.), which shall act as a proxy            *
 *   defined in Section 14 of version 3 of the license.                    *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 ***************************************************************************/

import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1
import org.kde.discover 2.0
import org.kde.discover.app 1.0
import org.kde.kirigami 2.0 as Kirigami
import "navigation.js" as Navigation

Kirigami.GlobalDrawer {
    id: drawer
    property bool wideScreen: false
    bannerImageSource: "qrc:/banners/banner.svg"
    //make the left and bottom margins for search field the same
    topPadding: drawer.wideScreen ? -toploader.height - leftPadding : 0
    bottomPadding: 0

    resetMenuOnTriggered: false

    onBannerClicked: {
        Navigation.openHome();
        if (modal)
            drawerOpen = false
    }

    property string currentSearchText

    onCurrentSubMenuChanged: {
        if (currentSubMenu)
            currentSubMenu.trigger()
        else if (currentSearchText.length > 0)
            window.leftPage.category = null
        else
            Navigation.openHome()
    }

    topContent: ConditionalLoader {
        id: toploader
        condition: drawer.wideScreen
        Layout.fillWidth: true
        componentFalse: Item {
            Layout.minimumHeight: 1
            Keys.forwardTo: [window.pageStack]
        }
        componentTrue: SearchField {
            id: searchField

            visible: window.leftPage && (window.leftPage.searchFor != null || window.leftPage.hasOwnProperty("search"))
            Keys.forwardTo: [window.pageStack]

            page: window.leftPage

            onCurrentSearchTextChanged: {
                var curr = window.leftPage;
                if (!curr.hasOwnProperty("search")) {
                    Navigation.clearStack()
                    Navigation.openApplicationList( { search: currentSearchText })
                } else {
                    curr.search = currentSearchText;
                }
            }
        }
    }

    ColumnLayout {
        spacing: 0
        Layout.fillWidth: true
        Layout.leftMargin: -drawer.leftPadding
        Layout.rightMargin: -drawer.rightPadding

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        ProgressView {
            separatorVisible: false
        }

        ActionListItem {
            action: searchAction
        }
        ActionListItem {
            action: installedAction
        }
        ActionListItem {
            action: settingsAction
        }
        ActionListItem {
            objectName: "updateButton"
            action: updateAction

            backgroundColor: ResourcesModel.updatesCount>0 ? "orange" : Kirigami.Theme.viewBackgroundColor
        }

        states: [
            State {
                name: "full"
                when: drawer.wideScreen
                PropertyChanges { target: drawer; drawerOpen: true }
            },
            State {
                name: "compact"
                when: !drawer.wideScreen
                PropertyChanges { target: drawer; drawerOpen: false }
            }
        ]
    }

    function rootCategory(cat) {
        var ret = null
        while (cat) {
            ret = cat
            cat = cat.parent
        }
        return ret
    }

    Component {
        id: categoryActionComponent
        Kirigami.Action {
            property QtObject category
            readonly property bool itsMe: window.leftPage && window.leftPage.hasOwnProperty("category") && (window.leftPage.category == category)
            text: category.name
            checked: itsMe
            visible: (!window.leftPage
                   || !window.leftPage.subcategories
                   || window.leftPage.subcategories === undefined
                   || currentSearchText.length === 0
                   || (category && category.contains(window.leftPage.subcategories))
                     )
            onTriggered: {
                if (!window.leftPage.canNavigate)
                    Navigation.openCategory(category, currentSearchText)
                else {
                    window.leftPage.category = category
                    pageStack.currentIndex = 0
                }
            }
        }
    }

    function createCategoryActions(categories) {
        var actions = []
        for(var i in categories) {
            var cat = categories[i];
            var catAction = categoryActionComponent.createObject(drawer, {category: cat});
            catAction.children = createCategoryActions(cat.subcategories);
            actions.push(catAction)
        }
        return actions;
    }

    actions: createCategoryActions(CategoryModel.rootCategories)

    modal: !drawer.wideScreen
    handleVisible: !drawer.wideScreen
}
