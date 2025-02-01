//  Created by Alex Little on 01/02/2025.

import UIKit
import IssueReporting

/// Protects the ancestor or sibling views from reloading when model properties change that are accessed in this subheirarchy
/// This can isolate heavy model updates to a single component without reloading an entire screen
public struct ObservationBoundaryComponent<C: ComponentBuilder>: ComponentBuilder {
    let componentBuilder: C

    public init(component: C) {
        self.componentBuilder = component
    }

    public func build() -> some Component {
        ViewComponent<UIView>()
            .with(\.componentEngine.component, componentBuilder)
#if DEBUG
            .constraint { c in
                if c.maxSize.height == .infinity || (c.isTight && c.minSize.height == 0) {
                    reportIssue("You must provide a height for \(String(describing: componentBuilder)) in a ObservationBoundaryComponent's")
                }

                if c.maxSize.width == .infinity || (c.isTight && c.minSize.width == 0) {
                    reportIssue("You must provide a width for \(String(describing: componentBuilder)) in a ObservationBoundaryComponent's")
                }
                return c
            }
#endif
            .eraseToAnyComponentOfView()
    }
}

/// Protects the ancestor or sibling views from reloading when model properties change that are accessed in this subheirarchy
/// /// This can isolate heavy model updates to a single component without reloading an entire screen
public struct ObservationScrollBoundaryComponent<C: ComponentBuilder>: ComponentBuilder {
    let componentBuilder: C

    public init(component: C) {
        self.componentBuilder = component
    }


    public func build() -> AnyComponentOfView<UIScrollView> {
        ViewComponent<UIScrollView>()
            .with(\.componentEngine.component, componentBuilder)
#if DEBUG
            .constraint { c in
                if c.maxSize.height == .infinity || (c.isTight && c.minSize.height == 0) {
                    reportIssue("You must provide a height for \(String(describing: componentBuilder)) in a ObservationScrollBoundaryComponent's")
                }

                if c.maxSize.width == .infinity || (c.isTight && c.minSize.width == 0) {
                    reportIssue("You must provide a width for \(String(describing: componentBuilder)) in a ObservationScrollBoundaryComponent's")
                }
                return c
            }
#endif
            .eraseToAnyComponentOfView()
    }
}
