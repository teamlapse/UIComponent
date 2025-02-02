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

struct DeepViewParent: ComponentBuilder {
    let model: TestModel

    func build() -> some Component {
        VStack {
            Text("hello")

            ObservationBoundaryComponent(component: BottomLevel(model: model))
                .size(width: 100, height: 30)
        }
    }

    struct BottomLevel: ComponentBuilder {
        let model: TestModel

        func build() -> some Component {
            Text(model.value)
        }
    }
}

struct DeepViewParentInfiniteHeight: ComponentBuilder {
    let model: TestModel

    func build() -> some Component {
        VStack {
            Text("hello")

            ObservationBoundaryComponent(component: BottomLevel(model: model))
        }
    }

    struct BottomLevel: ComponentBuilder {
        let model: TestModel

        func build() -> some Component {
            Text(model.value)
        }
    }
}

struct DeepViewParentInfiniteWidth: ComponentBuilder {
    let model: TestModel

    func build() -> some Component {
        HStack {
            Text("hello")

            ObservationBoundaryComponent(component: BottomLevel(model: model))
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
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.componentEngine.component = TestView(model: model)
        view.componentEngine.reloadData()

        #expect(view.componentEngine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "initial")

        model.value = "updated"
        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 1)
        #expect((view.subviews.first as? UILabel)?.text == "updated")
    }

    @Test func testMultipleUpdatesInOneRunloopIteration() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.componentEngine.component = TestView(model: model)
        view.componentEngine.reloadData()

        #expect(view.componentEngine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "initial")

        model.value = "updated"
        model.value = "updated 2"

        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 1)
        #expect((view.subviews.first as? UILabel)?.text == "updated 2")
    }

    @Test func testMultipleObservations() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.componentEngine.component = TestView(model: model)
        view.componentEngine.reloadData()
        #expect(view.componentEngine.observationReloadCount == 0)

        // Multiple updates should each trigger a reload
        model.value = "update1"
        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 1)

        model.value = "update2"
        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 2)

        model.value = "update3"
        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 3)
    }

    @Test func testExcessiveReloads() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        view.componentEngine.debugReloadsEnabled = true
        let model = TestModel(value: "initial")

        // Configure debug settings
        view.componentEngine.debugReloadThreshold = .reloads(count: 3, timeWindow: 0.1)

        view.componentEngine.component = TestView(model: model)
        view.componentEngine.reloadData()
        #expect(view.componentEngine.observationReloadCount == 0)

        // Multiple updates should each trigger a reload
        model.value = "update1"
        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 1)

        model.value = "update2"
        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 2)

        withKnownIssue {
            model.value = "update3"
        } matching: { issue in
            issue.description == "Issue recorded: Excessive updates: 3 reloads/0.1s\nOptimise observable model updates in heirarchy for TestView(model: UIComponentTests.TestModel)"
        }
    }

    @Test func testResetObservationCount() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.componentEngine.component = TestView(model: model)
        view.componentEngine.reloadData()

        #expect(view.componentEngine.observationReloadCount == 0)

        model.value = "update1"
        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 1)

        // Setting a new component should reset the observation count
        view.componentEngine.component = Text("static")
        #expect(view.componentEngine.observationReloadCount == 0)
    }

    @Test func testHighObservationReloadCount() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        withKnownIssue {
            view.componentEngine.debugReloadThreshold = .reloads(count: 100, timeWindow: 0.1)
        } matching: { issue in
            issue.description == "Issue recorded: Abnormally high reload threshold, find the earliest opportunity to optimise"
        }
    }

    @Test func testObservationBoundary() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.componentEngine.component = DeepViewParent(model: model)
        view.componentEngine.reloadData()

        guard let reloadableLabelContainer = view.subviews.last else {
            #expect(Bool(false))
            return
        }

        reloadableLabelContainer.componentEngine.reloadData()

        #expect(view.componentEngine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "hello")

        #expect(reloadableLabelContainer.componentEngine.observationReloadCount == 0)
        #expect((reloadableLabelContainer.subviews.first as? UILabel)?.text == "initial")

        model.value = "updated"
        RunLoop.syncMain()

        #expect(view.componentEngine.observationReloadCount == 0)
        #expect((view.subviews.first as? UILabel)?.text == "hello")

        #expect(reloadableLabelContainer.componentEngine.observationReloadCount == 1)
        #expect((reloadableLabelContainer.subviews.first as? UILabel)?.text == "updated")
    }

    @Test func testObservationBoundaryInfiniteHeight() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.componentEngine.component = DeepViewParentInfiniteHeight(model: model)

        withKnownIssue {
            view.componentEngine.reloadData()
        } matching: { issue in
            issue.description == "Issue recorded: View cannot layout - dimensions are not properly constrained (invalid or missing size constraints) for BottomLevel(model: UIComponentTests.TestModel) in ObservationBoundaryComponent"
        }
    }

    @Test func testObservationBoundaryInfiniteWidth() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let model = TestModel(value: "initial")

        view.componentEngine.component = DeepViewParentInfiniteWidth(model: model)

        withKnownIssue {
            view.componentEngine.reloadData()
        } matching: { issue in
            issue.description == "Issue recorded: View cannot layout - dimensions are not properly constrained (invalid or missing size constraints) for BottomLevel(model: UIComponentTests.TestModel) in ObservationBoundaryComponent"
        }
    }
}

extension RunLoop {
    static func syncMain() {
        RunLoop.main.run(until: .init(timeIntervalSinceNow: 0.001))
    }
}
