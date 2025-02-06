//  Created by Luke Zhao on 8/23/20.

import Foundation
import OSLog

/// A Component that builds a Component.
/// Use this instead of ``Component`` when you want to implement ``build()`` instead of ``Component/layout(_:)``.
/// This saves you from calling ``Component/layout(_:)`` on your child before returning it.
/// See <doc:CustomComponent> for detail.
public protocol ComponentBuilder: Component {
    associatedtype ResultComponent: Component
    /// Builds and returns the `ResultComponent`.
    func build() -> ResultComponent
}

extension ComponentBuilder {
    public func layout(_ constraint: Constraint) -> ResultComponent.R {
        if UIComponentDebugOptions.enableDebugSignposts {
            let signpostId = OSSignpostID(log: SignpostLog.componentLayout)
            let componentName = description

            os_signpost(
                .begin,
                log: SignpostLog.componentLayout,
                name: "ComponentBuilder",
                signpostID: signpostId,
                "Component:%{public}@",
                componentName
            )

            let built = build()

            let renderNode = built.layout(constraint)

            os_signpost(
                .end,
                log: SignpostLog.componentLayout,
                name: "ComponentBuilder",
                signpostID: signpostId,
                "Complete"
            )

            return renderNode
        } else {
            return build().layout(constraint)
        }
    }
}
