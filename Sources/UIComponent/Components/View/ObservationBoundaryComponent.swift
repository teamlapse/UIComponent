//  Created by Alex Little on 01/02/2025.

import UIKit
import IssueReporting

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
                if c.maxSize.height == .infinity {
                    reportIssue("You must provide a height for \(String(describing: componentBuilder)) in a ObservationBoundaryComponent's")
                }

                if c.maxSize.width == .infinity {
                    reportIssue("You must provide a width for \(String(describing: componentBuilder)) in a ObservationBoundaryComponent's")
                }
                return c
            }
#endif
    }
}
