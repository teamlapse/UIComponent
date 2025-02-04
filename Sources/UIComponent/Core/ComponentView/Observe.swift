import ConcurrencyExtras
import Perception
import Foundation

func observe(
    _ apply: @escaping @Sendable () -> Void,
    task: @escaping @Sendable (
        _ operation: @escaping @Sendable () -> Void
    ) -> Void
) -> ObserveToken {
    let token = ObserveToken()
    onChange(
        { [weak token] in
            guard
                let token,
                !token.isCancelled
            else { return }

            let perform: @Sendable () -> Void = { apply() }
            perform()
        },
        task: task
    )
    return token
}

private func onChange(
    _ apply: @escaping @Sendable () -> Void,
    task: @escaping @Sendable (_ operation: @escaping @Sendable () -> Void) -> Void
) {
    withPerceptionTracking {
        apply()
    } onChange: {
        task {
            onChange(apply, task: task)
        }
    }
}

/// A token for cancelling observation.
///
/// When this token is deallocated it cancels the observation it was associated with. Store this
/// token in another object to keep the observation alive. You can do with this with a set of
/// ``ObserveToken``s and the ``store(in:)-4bp5r`` method:
///
/// ```swift
/// class Coordinator {
///   let model = Model()
///   var tokens: Set<ObserveToken> = []
///
///   func start() {
///     observe { [weak self] in
///       // ...
///     }
///     .store(in: &tokens)
///   }
/// }
/// ```
public final class ObserveToken: HashableObject {
    fileprivate var _isCancelled = false
    public let onCancel: @Sendable () -> Void

    public var isCancelled: Bool {
        _isCancelled
    }

    public init(onCancel: @escaping @Sendable () -> Void = {}) {
        self.onCancel = onCancel
    }

    deinit {
        cancel()
    }

    /// Cancels observation that was created with ``observe(isolation:_:)-9xf99``.
    ///
    /// > Note: This cancellation is lazy and cooperative. It does not cancel the observation
    /// > immediately, but rather next time a change is detected by `observe` it will cease any future
    /// > observation.
    public func cancel() {
        guard !_isCancelled else { return }
        _isCancelled = true
        onCancel()
    }

    /// Stores this observation token instance in the specified collection.
    ///
    /// - Parameter collection: The collection in which to store this observation token.
    public func store(in collection: inout some RangeReplaceableCollection<ObserveToken>) {
        collection.append(self)
    }

    /// Stores this observation token instance in the specified set.
    ///
    /// - Parameter set: The set in which to store this observation token.
    public func store(in set: inout Set<ObserveToken>) {
        set.insert(self)
    }
}

public protocol HashableObject: AnyObject, Hashable {}

extension HashableObject {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

import Dispatch
import ObjectiveC

@MainActor
extension NSObject {
    @discardableResult
    public func observe(
        _ apply: @escaping @MainActor @Sendable () -> Void,
        sideEffect: @escaping @Sendable () -> Void
    ) -> ObserveToken {
        let token = UIComponent.observe {
            MainActor.assumeIsolated {
                apply()
            }
        } task: { work in
            sideEffect()
            RunLoop.main.perform(inModes: [.default, .common, .tracking]) {
                work()
            }
        }
        tokens.append(token)
        return token
    }

    fileprivate var tokens: [Any] {
        get {
            objc_getAssociatedObject(self, Self.tokensKey) as? [Any] ?? []
        }
        set {
            objc_setAssociatedObject(self, Self.tokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private static let tokensKey = malloc(1)!
}
