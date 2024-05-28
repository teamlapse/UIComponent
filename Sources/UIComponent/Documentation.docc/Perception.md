# Perception

Examples of how to use Perception efficiently to only reload leaf nodes when the properties they use change

## Overview

We have 2 types of perception components in UIComponent, both introduce ``ComponentView`` layers with their own Engine's. This allows their engine to only listen to changes in it's own ``Component/layout(_:)`` or ``ComponentBuilder/build()`` methods  

##### ObservableComponent

The ``ObservableComponent`` modifier introduces a normal ``ComponentView`` layer

##### ObservableScrollView

The ``ObservableScrollComponent`` modifier introduces a scroll view ``ComponentScrollView`` layer

### Usage

The do's and do not's of using perception with UIComponent.

All publically available apis for perception views enforce you give sizing information, this is because we are wrapping ``ViewComponent`` underneath which has no information about sizing. This means we have to be explicit with sizing or it will default to zero

Both of these options must be initialised with a struct directly, wrap the content you want in it's own Component Builder struct before using either

#### Isolating reloads

In these examples we'll be working with a list of images in a waterfall layout. When a user taps on the image, it increments a like counter which is deployed ontop of the image.

##### Example

This example shows how we can isolate changes to the elements inside of a list rather than reloading the entire list.

When the user taps the image and increments the like counter, only that ImageContainer we be re-evaluated, meaning it's ``ComponentBuilder/build()`` will be called again. However the parent component will not be re-evaluated

```swift
func build() -> some Component {
    Waterfall(columns: 2, spacing: 1) {
        for (index, image) in model.images.enumerated() {
            ObservableComponent(
                component: ImageContainer(model: model, image: image, index: index),
                width: .fill,
                height: .aspectPercentage(image.size.height / image.size.width)
            )
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

#### Environment Propogation

##### Example

This example will propogate the `viewController` environment into `Screen` correctly

```swift
func build() -> some Component {
    ObservableScrollView(
        component: Screen(model: model),
        width: .fill,
        height: .fill
    )
    .viewController(self)
}
```
