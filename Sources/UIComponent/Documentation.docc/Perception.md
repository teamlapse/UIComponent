# Perception

Examples of how to use Perception efficiently to only reload leaf nodes when the properties they use change

## Overview

We have 2 types of perception extensions in UIComponent, both introduce ``ComponentView`` layers with their own Engine's. This allows their engine to only listen to changes in it's own ``Component/layout(_:)`` or ``ComponentBuilder/build()`` methods  

##### PerceptionView

The ``Component/perceptionViewFill()`` modifier introduces a normal ``ComponentView`` layer, other sizing options are available

##### PerceptionScrollView

The ``Component/perceptionScrollViewFill()`` modifier introduces a scroll view ``ComponentScrollView`` layer, other sizing options are available

### Usage

The do's and do not's of using perception with UIComponent.

All publically available apis for perception views enforce you give sizing information, this is because we are wrapping ``ViewComponent`` underneath which has no information about sizing. This means we have to be explicit with sizing or it will default to zero

#### Isolating reloads

In these examples we'll be working with a list of images in a waterfall layout. When a user taps on the image, it increments a like counter which is deployed ontop of the image.

##### Working examples

This example shows how we can isolate changes to the elements inside of a list rather than reloading the entire list.

When the user taps the image and increments the like counter, only that ImageContainer we be re-evaluated, meaning it's ``ComponentBuilder/build()`` will be called again. However the parent component will not be re-evaluated

```swift
func build() -> some Component {
    Waterfall(columns: 2, spacing: 1) {
        for (index, image) in model.images.enumerated() {
            ImageContainer(model: model, image: image, index: index)
                .perceptionView(width: .fill, height: .aspectPercentage(image.size.height / image.size.width))
                .id(image.url.absoluteString)
        }
    }
}

struct ImageContainer: ComponentBuilder {
    let model: PerceptionModel
    let image: PerceptionImage
    let index: Int

    func build() -> some Component {
        AsyncImage(image.url)
            .fill()
            .tappableView { [weak image] in
                image?.likes += 1
            }
            .overlay {
                ZStack(verticalAlignment: .center, horizontalAlignment: .center) {
                    Text("\(image.likes)")
                        .textColor(.red)
                        .font(.boldSystemFont(ofSize: 20))
                }
                .fill()
            }
    }
}
```

##### Broken examples

This example shows how placing the `perceptionView` modifier in the wrong place can cause more to reload than we want

In this example, the content within `ImageContainer` will be evaluated and owned by the parent's ``ComponentView`` as the access to the model/image properties is recorded within the parent view's layout call, not the child components. This means the entire Waterfall layout will be called again and our screen is doing alot more work than required

```swift
func build() -> some Component {
    Waterfall(columns: 2, spacing: 1) {
        for (index, image) in model.images.enumerated() {
            ImageContainer(model: model, image: image, index: index)
                .id(image.url.absoluteString)
        }
    }
}

struct ImageContainer: ComponentBuilder {
    let model: PerceptionModel
    let image: PerceptionImage
    let index: Int

    func build() -> some Component {
        AsyncImage(image.url)
            .fill()
            .tappableView { [weak image] in
                image?.likes += 1
            }
            .overlay {
                ZStack(verticalAlignment: .center, horizontalAlignment: .center) {
                    Text("\(image.likes)")
                        .textColor(.red)
                        .font(.boldSystemFont(ofSize: 20))
                }
                .fill()
            }
            .perceptionView(width: .fill, height: .aspectPercentage(image.size.height / image.size.width))
    }
}
```

#### Environment Propogation

##### Working examples

This example will propogate the `viewController` environment into `Screen` correctly because it's set before the perception component view layer

```swift
func build() -> some Component {
    Screen(model: model)
        .viewController(self)
        .perceptionScrollViewFill()
}
```

This example would also work as we're introducing an extra ``Component`` or ``ComponentBuilder`` layer into the heirachy where the environment has been propogated by the ``ComponentEngine`` layout code. 
```swift
func build() -> some Component {
    ScreenContainer(model: model)
        .viewController(self)
}

struct ScreenContainer: ComponentBuilder {
    let model: Model

    func build() -> some Component {
        Screen(model: model)
            .perceptionScrollViewFill()
    }
}
```

##### Broken examples

This example will not propogate the `viewController` environment into `Screen` correctly because it's set after the perception component view layer

```swift
func build() -> some Component {
    Screen(model: model)
        .perceptionScrollViewFill()
        .viewController(self)
}
```
