//  Created by Alex Little on 27/05/2024.

import Foundation

extension Component {
    func perceptionView() -> ModifierComponent<ViewComponent<ComponentView>, KeyPathUpdateRenderNode<(any Component)?, ViewRenderNode<ComponentView>>> {
        ViewComponent<ComponentView>()
            .component(self.environment(\.self, value: EnvironmentValues.current)) /// Required to forward the environment down the chain, otherwise you can't access the interactors
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionView(width: SizeStrategy, height: SizeStrategy) -> PerceptionViewWithSize {
        perceptionView()
            .size(width: width, height: height)
    }

    typealias PerceptionViewWithSize = ConstraintOverrideComponent<ModifierComponent<ViewComponent<ComponentView>, KeyPathUpdateRenderNode<(any Component)?, ViewRenderNode<ComponentView>>>>
}

extension Component {
    func perceptionScrollView() -> ModifierComponent<ViewComponent<ComponentScrollView>, KeyPathUpdateRenderNode<(any Component)?, ViewRenderNode<ComponentScrollView>>> {
        ViewComponent<ComponentScrollView>()
            .component(self.environment(\.self, value: EnvironmentValues.current)) /// Required to forward the environment down the chain, otherwise you can't access the interactors
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionScrollView(width: SizeStrategy, height: SizeStrategy) -> PerceptionScrollViewWithSize {
        perceptionScrollView()
            .size(width: width, height: height)
    }

    typealias PerceptionScrollViewWithSize = ConstraintOverrideComponent<ModifierComponent<ViewComponent<ComponentScrollView>, KeyPathUpdateRenderNode<(any Component)?, ViewRenderNode<ComponentScrollView>>>>
}


public struct ObservableComponent<C: Component>: ComponentBuilder {
    let component: C
    let width: SizeStrategy
    let height: SizeStrategy

    public init(component: C, width: SizeStrategy = .fill, height: SizeStrategy = .fill) {
        self.component = component
        self.width = width
        self.height = height
    }

    public func build() -> some Component {
        component
            .perceptionView(width: width, height: height)
    }
}

extension ObservableComponent {
    public init(component: C, width: CGFloat, height: SizeStrategy) {
        self.component = component
        self.width = .absolute(width)
        self.height = height
    }

    public init(component: C, width: SizeStrategy, height: CGFloat) {
        self.component = component
        self.width = width
        self.height = .absolute(height)
    }

    public init(component: C, width: CGFloat, height: CGFloat) {
        self.component = component
        self.width = .absolute(width)
        self.height = .absolute(height)
    }
}


public struct ObservableScrollComponent<C: Component>: ComponentBuilder {
    let component: C
    let width: SizeStrategy
    let height: SizeStrategy

    public init(component: C, width: SizeStrategy = .fill, height: SizeStrategy = .fill) {
        self.component = component
        self.width = width
        self.height = height
    }

    public func build() -> some Component {
        component
            .perceptionScrollView(width: width, height: height)
    }
}

extension ObservableScrollComponent {
    public init(component: C, width: CGFloat, height: SizeStrategy) {
        self.component = component
        self.width = .absolute(width)
        self.height = height
    }

    public init(component: C, width: SizeStrategy, height: CGFloat) {
        self.component = component
        self.width = width
        self.height = .absolute(height)
    }

    public init(component: C, width: CGFloat, height: CGFloat) {
        self.component = component
        self.width = .absolute(width)
        self.height = .absolute(height)
    }
}
