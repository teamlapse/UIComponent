//  Created by Alex Little on 01/02/2025.

import Perception
import Testing
@testable import UIComponent
import UIKit


@Perceptible
class TestModel {
    var value: String

    init(value: String) {
        self.value = value
    }
}

struct TestView: ComponentBuilder {
    let model: TestModel

    func build() -> some Component {
        Text(model.value)
    }
}

@Perceptible
class MultipleModelTest {
    var value: String
    let deep = DeepModel()

    init(value: String) {
        self.value = value
    }

    @Perceptible
    class DeepModel {
        let test = TestModel(value: "testModel")
    }
}

struct MultipleModelTestView: ComponentBuilder {
    let model: MultipleModelTest

    func build() -> some Component {
        HStack {
            Text(model.value)

            ObservableComponent(
                component: DeepView(model: model),
                width: 100,
                height: 30
            )
        }
    }

    struct DeepView: ComponentBuilder {
        let model: MultipleModelTest

        func build() -> some Component {
            Text(model.deep.test.value)
        }
    }
}


struct DeepViewParent: ComponentBuilder {
    let model: TestModel

    func build() -> some Component {
        VStack {
            Text("hello")

            ObservableComponent(
                component: BottomLevel(model: model),
                width: 100,
                height: 30
            )
        }
    }

    struct BottomLevel: ComponentBuilder {
        let model: TestModel

        func build() -> some Component {
            Text(model.value)
        }
    }
}

@Suite("Observation")
@MainActor
struct ObservationTests {
    @Test func testBasicObservation() throws {
        let view = ComponentView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.engine.component = TestView(model: model)
        view.engine.reloadData()

        #expect(view.engine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "initial")

        model.value = "updated"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 1)
        #expect((view.subviews.first as? UILabel)?.text == "updated")
    }

    @Test func testBasicObservationDeep() throws {
        let view = ComponentView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = MultipleModelTest(value: "initial")

        view.engine.component = MultipleModelTestView(model: model)
        view.engine.reloadData()

        let deepView = view.subviews.last as? ComponentView
        deepView?.engine.reloadData()

        #expect(view.engine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "initial")
        #expect((deepView?.subviews.last as? UILabel)?.text == "testModel")

        model.value = "test"
        model.deep.test.value = "updated"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 1)
        #expect((view.subviews.first as? UILabel)?.text == "test")
        #expect((deepView?.subviews.last as? UILabel)?.text == "updated")
    }

    @Test func testMultipleUpdatesInOneRunloopIteration() throws {
        let view = ComponentView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.engine.component = TestView(model: model)
        view.engine.reloadData()

        #expect(view.engine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "initial")

        model.value = "updated"
        model.value = "updated 2"

        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 1)
        #expect((view.subviews.first as? UILabel)?.text == "updated 2")
    }

    @Test func testMultipleObservations() throws {
        let view = ComponentView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.engine.component = TestView(model: model)
        view.engine.reloadData()
        #expect(view.engine.observationReloadCount == 0)

        // Multiple updates should each trigger a reload
        model.value = "update1"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 1)

        model.value = "update2"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 2)

        model.value = "update3"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 3)
    }

    @Test func testExcessiveReloads() throws {
        let view = ComponentView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        // Configure debug settings
        view.engine.debugReloadThreshold = .reloads(count: 3, timeWindow: 0.1)

        view.engine.component = TestView(model: model)
        view.engine.reloadData()
        #expect(view.engine.observationReloadCount == 0)

        // Multiple updates should each trigger a reload
        model.value = "update1"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 1)

        model.value = "update2"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 2)

        withKnownIssue {
            model.value = "update3"
        } matching: { issue in
            issue.description == "Issue recorded: Excessive updates: 3 reloads/0.1s\nOptimise observable model updates in heirarchy for TestView(model: UIComponentTests.TestModel)"
        }
    }

    @Test func testResetObservationCount() throws {
        let view = ComponentView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.engine.component = TestView(model: model)
        view.engine.reloadData()

        #expect(view.engine.observationReloadCount == 0)

        model.value = "update1"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 1)

        // Setting a new component should reset the observation count
        view.engine.component = Text("static")
        #expect(view.engine.observationReloadCount == 0)
    }

    @Test func testHighObservationReloadCount() throws {
        let view = ComponentView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        withKnownIssue {
            view.engine.debugReloadThreshold = .reloads(count: 100, timeWindow: 0.1)
        } matching: { issue in
            issue.description == "Issue recorded: Abnormally high reload threshold, find the earliest opportunity to optimise"
        }
    }

    @Test func testObservationBoundary() throws {
        let view = ComponentView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.engine.component = DeepViewParent(model: model)
        view.engine.reloadData()

        guard let reloadableLabelContainer = view.subviews.last as? ComponentView else {
            #expect(Bool(false))
            return
        }

        reloadableLabelContainer.engine.reloadData()

        #expect(view.engine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "hello")

        #expect(reloadableLabelContainer.engine.observationReloadCount == 0)
        #expect((reloadableLabelContainer.subviews.first as? UILabel)?.text == "initial")

        model.value = "updated"
        RunLoop.syncMain()

        #expect(view.engine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "hello")

        #expect(reloadableLabelContainer.engine.observationReloadCount == 1)
        #expect((reloadableLabelContainer.subviews.first as? UILabel)?.text == "updated")
    }
}

extension RunLoop {
    static func syncMain() {
        RunLoop.main.run(until: .init(timeIntervalSinceNow: 0.001))
    }
}
