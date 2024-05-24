//  Created by Luke Zhao on 2018-12-13.

import UIComponent
import UIKit
import Perception

class ViewController: ComponentViewController {
    let model = PlaygroundModel()

    override var component: any Component {
        PlaygroundView(model: model)
            .view()
    }
}

@Perceptible
class PlaygroundModel {
    var text: String = "hey"
}

struct PlaygroundView: ComponentBuilder {
    let model: PlaygroundModel

    func build() -> some Component {
        let _ = print("BUILDING PLAYGROUND VIEW")
        return VStack {
            Test(model: model)
                .view()
        }
    }
}

struct Test: ComponentBuilder {
    let model: PlaygroundModel

    func build() -> some Component {
        let _ = print("BUILDING TEXT: \(model.text)")
        return Text(model.text)
            .tappableView {
                model.text = "testinggg + \(Int.random(in: 0..<1000))"
            }
    }
}

struct ExampleItem: ComponentBuilder {
    @Environment(\.viewController)
    var parentViewController: UIViewController?

    let name: String
    let viewController: () -> UIViewController

    init(name: String, viewController: @autoclosure @escaping () -> UIViewController) {
        self.name = name
        self.viewController = viewController
    }

    func build() -> some Component {
        VStack {
            Text(name)
        }
        .inset(20)
        .tappableView { [weak parentViewController] in
            print("Test")
            parentViewController?.present(viewController(), animated: true)
        }
    }
}

struct ViewControllerEnvironmentKey: EnvironmentKey {
    static var defaultValue: UIViewController? {
        nil
    }
    static var isWeak: Bool {
        true
    }
}

extension EnvironmentValues {
    var viewController: UIViewController? {
        get { self[ViewControllerEnvironmentKey.self] }
        set { self[ViewControllerEnvironmentKey.self] = newValue }
    }
}

extension Component {
    func viewController(_ viewController: UIViewController) -> some Component {
        environment(\.viewController, value: viewController)
    }
}
