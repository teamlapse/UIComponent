//  Created by Luke Zhao on 6/14/21.

import Kingfisher
import UIComponent
import UIKit

public struct AsyncImage: ComponentBuilder {

    public typealias AsyncIndicatorType = IndicatorType
    public typealias ConfigurationBuilder = (KF.Builder) -> KF.Builder

    public let url: URL?
    public let indicatorType: AsyncIndicatorType
    public let configurationBuilder: ConfigurationBuilder?

    public init(
        _ url: URL?,
        indicatorType: AsyncIndicatorType = .none,
        configurationBuilder: ConfigurationBuilder? = nil
    ) {
        self.url = url
        self.indicatorType = indicatorType
        self.configurationBuilder = configurationBuilder
    }

    public init(
        _ urlString: String,
        indicatorType: AsyncIndicatorType = .none,
        configurationBuilder: ConfigurationBuilder? = nil
    ) {
        self.url = URL(string: urlString)
        self.indicatorType = indicatorType
        self.configurationBuilder = configurationBuilder
    }

    public func build() -> UpdateComponent<ViewComponent<UIImageView>> {
        ViewComponent<UIImageView>()
            .update {
                $0.kf.indicatorType = indicatorType
                $0.contentMode = .scaleAspectFill
                $0.clipsToBounds = true
                if let configurationBuilder = configurationBuilder {
                    configurationBuilder(KF.url(url)).set(to: $0)
                } else {
                    KF.url(url).set(to: $0)
                }
            }
    }
}
