//  Created by Alex Little on 01/02/2025.

#if DEBUG
    import IssueReporting
#endif

import UIKit

/// Protects the ancestor or sibling views from reloading when model properties change that are accessed in this subheirarchy
/// This can isolate heavy model updates to a single component without reloading an entire screen
public struct ObservationBoundaryComponent<C: ComponentBuilder>: ComponentBuilder {
    let componentBuilder: C

    public init(component: C) {
        componentBuilder = component
    }

    public func build() -> some Component {
        ViewComponent<UIView>()
            .with(\.componentEngine.component, componentBuilder)
        #if DEBUG
            .constraint { c in
                let hasInvalidHeight = (c.maxSize.height == .infinity && c.minSize.height == 0) ||
                    (c.maxSize.height > 0 && c.minSize.height == 0) ||
                    c.minSize.height == -.infinity
                let hasInvalidWidth = (c.maxSize.width == .infinity && c.minSize.width == 0) ||
                    (c.maxSize.width > 0 && c.minSize.width == 0) ||
                    c.minSize.width == -.infinity

                if hasInvalidHeight, hasInvalidWidth {
                    withIssueReporters([.runtimeWarning, .breakpoint]) {
                        reportIssue("View cannot layout - dimensions are not properly constrained (invalid or missing size constraints) for \(String(describing: componentBuilder)) in ObservationBoundaryComponent")
                    }
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
        componentBuilder = component
    }

    public func build() -> AnyComponentOfView<UIScrollView> {
        ViewComponent<UIScrollView>()
            .with(\.componentEngine.component, componentBuilder)
        #if DEBUG
            .constraint { c in
                let hasInvalidHeight = (c.maxSize.height == .infinity && c.minSize.height == 0) ||
                    (c.maxSize.height > 0 && c.minSize.height == 0) ||
                    c.minSize.height == -.infinity
                let hasInvalidWidth = (c.maxSize.width == .infinity && c.minSize.width == 0) ||
                    (c.maxSize.width > 0 && c.minSize.width == 0) ||
                    c.minSize.width == -.infinity

                if hasInvalidHeight, hasInvalidWidth {
                    withIssueReporters([.runtimeWarning, .breakpoint]) {
                        reportIssue("View cannot layout - dimensions are not properly constrained (invalid or missing size constraints) for \(String(describing: componentBuilder)) in ObservationScrollBoundaryComponent")
                    }
                }
                return c
            }
        #endif
            .eraseToAnyComponentOfView()
    }
}
