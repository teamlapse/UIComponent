//  Created by Luke Zhao on 6/14/21.

import UIComponent
import UIKit

class ComponentViewController: UIViewController {
    let componentView = ComponentView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(componentView)
        componentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            componentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            componentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            componentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            componentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        reloadComponent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    func reloadComponent() {
        componentView.component = component
    }

    var component: any Component {
        VStack(justifyContent: .center, alignItems: .center) {
            Text("Empty")
        }
        .size(width: .fill)
    }
}
