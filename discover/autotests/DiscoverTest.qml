import QtQuick 2.1
import QtTest 1.1
import org.kde.discover.app 1.0

Item
{
    id: testRoot

    signal reset()

    function verify(condition, msg) {
        if (!condition) {
            console.trace();
            var e = new Error(condition + ": " + msg)
            e.object = testRoot;
            throw e;
        }
    }

    function compare(valA, valB, msg) {
        if (valA !== valB) {
            console.trace();
            var e = new Error(valA + " !== " + valB + ": " + msg)
            e.object = testRoot;
            throw e;
        }
    }

    function isType(obj, typename) {
        return obj.toString().indexOf(typename+"_QMLTYPE_") == 0
    }

    function findChild(obj, typename) {
        if (isType(obj, typename))
            return obj;

        for(var v in obj.children) {
            var v = findChild(obj.children[v], typename)
            if (v)
                return v
        }
        return null
    }

    SignalSpy {
        id: spy
    }

    function waitForSignal(object, name, timeout) {
        if (!timeout) timeout = 5000;

        spy.signalName = ""
        spy.target = object;
        spy.signalName = name;
        verify(spy);

        try {
            spy.wait(timeout);
        } catch (e) {
            console.warn("wait for signal unsuccessful")
            return false;
        }
        return spy.count>0;
    }

    function waitForRendering() {
        return waitForSignal(Helpers.mainWindow, "frameSwapped")
    }

    Connections {
        target: ResourcesModel
        property bool done: false
        onIsFetchingChanged: {
            if (ResourcesModel.isFetching)
                return;

            done = true;
            for(var v in testRoot) {
                if (v.indexOf("test_") == 0) {
                    testRoot.reset();
                    testRoot[v]();
                }
            }
            Qt.quit();
        }
    }
}