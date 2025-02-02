import UIComponent
import UIKit
import Perception

class PerceptionViewController: ComponentViewController {
    let model = PerceptionModel()

    override var component: any Component {
        PerceptionScreen(model: model)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        componentView.animator = TransformAnimator()
        title = "Perception Example"
    }
}

@Perceptible
class PerceptionModel {
    var text: String = "hey"
    var number: Int = 0

    var images = [
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/Yn0l7uwBrpw/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 427)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/J4-xolC4CCU/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 800)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/biggKnv1Oag/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 434)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/MR2A97jFDAs/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 959)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/oaCnDk89aho/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 426)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/MOfETox0bkE/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 426)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/Ga7aBzN7qDw/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 427)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/kbv1PTv_1SM/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 800)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/zLNgFaJNANo/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 434)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/O0pcpmaR4eA/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 959)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/-jOic-c0jK0/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 426)
        ),
        PerceptionImage(
            url: URL(string: "https://unsplash.com/photos/kI-DsaRmg-Q/download?force=true&w=640")!,
            size: CGSize(width: 640, height: 426)
        ),
    ]
}

@Perceptible
class PerceptionImage {
    var url: URL
    var size: CGSize

    var likes: Int = 0

    init(url: URL, size: CGSize) {
        self.url = url
        self.size = size
    }
}

struct PerceptionScreen: ComponentBuilder {
    let model: PerceptionModel

    func build() -> some Component {
        print("RELOADING WATERFALL")
        return ObservableScrollComponent(
            component: WaterfallComponent(model: model),
            width: .fill,
            height: .fill
        )
    }

    struct WaterfallComponent: ComponentBuilder {
        let model: PerceptionModel

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
    }
}

struct ImageContainer: ComponentBuilder {
    @Environment(\.viewController) var viewController

    let model: PerceptionModel
    let image: PerceptionImage
    let index: Int

    func build() -> some Component {
        print("IMAGE RELOADING: \(index)")
        print("HAS ENV: \(viewController != nil)")
        return AsyncImage(image.url)
            .size(width: .fill, height: .aspectPercentage(image.size.height / image.size.width))
            .tappableView { [weak viewController] in
                let detailVC = AsyncImageDetailViewController()
                detailVC.image = .init(url: image.url, size: image.size)
                image.likes += 1

                viewController?.present(detailVC, animated: true)
            }
            .contextMenuProvider { _ in
                UIMenu(children: [
                    UIAction(
                        title: "Delete",
                        image: UIImage(systemName: "trash"),
                        attributes: [.destructive],
                        handler: { action in
                            model.images.remove(at: index)
                        }
                    )
                ])
            }
            .overlay {
                ZStack(verticalAlignment: .center, horizontalAlignment: .center) {
                    Text("\(image.likes)")
                        .textColor(.red)
                        .font(.boldSystemFont(ofSize: 20))
                }
                .fill()
            }
//            .perceptionView() /// Using perception view inside of here will not work correctly, any access to `model/image` with perception will be tracked as the parent's control, which would reload `PerceptionScreen` instead. You need to wrap content `Component` or `ComponentBuilder` struct first and then call `perceptionView()` on the struct not inside the structs `layout` or `build` methods
    }
}
