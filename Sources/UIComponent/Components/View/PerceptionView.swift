//  Created by Alex Little on 27/05/2024.

import Foundation

public extension Component {
    private func perceptionView() -> ModifierComponent<ViewComponent<ComponentView>, KeyPathUpdateRenderNode<(any Component)?, ViewRenderNode<ComponentView>>> {
        ViewComponent<ComponentView>()
            .component(self.environment(\.self, value: EnvironmentValues.current)) /// Required to forward the environment down the chain, otherwise you can't access the interactors
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionView(width: SizeStrategy, height: SizeStrategy) -> PerceptionViewWithSize {
        perceptionView()
            .size(width: width, height: height)
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionView(width: CGFloat, height: SizeStrategy = .fit) -> PerceptionViewWithSize {
        perceptionView()
            .size(width: width, height: height)
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionView(width: SizeStrategy = .fit, height: CGFloat) -> PerceptionViewWithSize {
        perceptionView()
            .size(width: width, height: height)
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionView(width: CGFloat, height: CGFloat) -> PerceptionViewWithSize {
        perceptionView()
            .size(width: width, height: height)
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionViewFill() -> PerceptionViewWithSize {
        perceptionView()
            .fill()
    }

    typealias PerceptionViewWithSize = ConstraintOverrideComponent<ModifierComponent<ViewComponent<ComponentView>, KeyPathUpdateRenderNode<(any Component)?, ViewRenderNode<ComponentView>>>>
}

public extension Component {
    private func perceptionScrollView() -> ModifierComponent<ViewComponent<ComponentScrollView>, KeyPathUpdateRenderNode<(any Component)?, ViewRenderNode<ComponentScrollView>>> {
        ViewComponent<ComponentScrollView>()
            .component(self.environment(\.self, value: EnvironmentValues.current)) /// Required to forward the environment down the chain, otherwise you can't access the interactors
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionScrollView(width: SizeStrategy, height: SizeStrategy) -> PerceptionScrollViewWithSize {
        perceptionScrollView()
            .size(width: width, height: height)
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionScrollView(width: CGFloat, height: SizeStrategy = .fit) -> PerceptionScrollViewWithSize {
        perceptionScrollView()
            .size(width: width, height: height)
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionScrollView(width: SizeStrategy = .fit, height: CGFloat) -> PerceptionScrollViewWithSize {
        perceptionScrollView()
            .size(width: width, height: height)
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionScrollView(width: CGFloat, height: CGFloat) -> PerceptionScrollViewWithSize {
        perceptionScrollView()
            .size(width: width, height: height)
    }

    /// Introduces a break in the heirachy where if the child components listen to model changes, then only this component and it's children will be called to reload
    func perceptionScrollViewFill() -> PerceptionScrollViewWithSize {
        perceptionScrollView()
            .fill()
    }

    typealias PerceptionScrollViewWithSize = ConstraintOverrideComponent<ModifierComponent<ViewComponent<ComponentScrollView>, KeyPathUpdateRenderNode<(any Component)?, ViewRenderNode<ComponentScrollView>>>>
}
