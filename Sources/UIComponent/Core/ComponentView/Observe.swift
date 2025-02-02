import ConcurrencyExtras
import Perception
import Foundation

func observe(
    _ apply: @escaping @Sendable () -> Void,
    task: @escaping @Sendable (
        _ operation: @escaping @Sendable () -> Void
    ) -> Void = {
        Task(operation: $0)
    }
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
public final class ObserveToken: Sendable, HashableObject {
    fileprivate let _isCancelled = LockIsolated(false)
    public let onCancel: @Sendable () -> Void

    public var isCancelled: Bool {
        _isCancelled.withValue { $0 }
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
        _isCancelled.withValue { isCancelled in
            guard !isCancelled else { return }
            defer { isCancelled = true }
            onCancel()
        }
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
    /// Observe access to properties of an observable (or perceptible) object.
    ///
    /// This tool allows you to set up an observation loop so that you can access fields from an
    /// observable model in order to populate your view, and also automatically track changes to
    /// any accessed fields so that the view is always up-to-date.
    ///
    /// It is most useful when dealing with non-SwiftUI views, such as UIKit views and controller.
    /// You can invoke the ``observe(_:)`` method a single time in the `viewDidLoad` and update all
    /// the view elements:
    ///
    /// ```swift
    /// override func viewDidLoad() {
    ///   super.viewDidLoad()
    ///
    ///   let countLabel = UILabel()
    ///   let incrementButton = UIButton(primaryAction: UIAction { [weak self] _ in
    ///     self?.model.incrementButtonTapped()
    ///   })
    ///
    ///   observe { [weak self] in
    ///     guard let self
    ///     else { return }
    ///
    ///     countLabel.text = "\(model.count)"
    ///   }
    /// }
    /// ```
    ///
    /// This closure is immediately called, allowing you to set the initial state of your UI
    /// components from the feature's state. And if the `count` property in the feature's state is
    /// ever mutated, this trailing closure will be called again, allowing us to update the view
    /// again.
    ///
    /// Generally speaking you can usually have a single ``observe(_:)`` in the entry point of your
    /// view, such as `viewDidLoad` for `UIViewController`. This works even if you have many UI
    /// components to update:
    ///
    /// ```swift
    /// override func viewDidLoad() {
    ///   super.viewDidLoad()
    ///
    ///   observe { [weak self] in
    ///     guard let self
    ///     else { return }
    ///
    ///     countLabel.isHidden = model.isObservingCount
    ///     if !countLabel.isHidden {
    ///       countLabel.text = "\(model.count)"
    ///     }
    ///     factLabel.text = model.fact
    ///   }
    /// }
    /// ```
    ///
    /// This does mean that you may execute the line `factLabel.text = model.fact` even when
    /// something unrelated changes, such as `store.model`, but that is typically OK for simple
    /// properties of UI components. It is not a performance problem to repeatedly set the `text` of
    /// a label or the `isHidden` of a button.
    ///
    /// However, if there is heavy work you need to perform when state changes, then it is best to
    /// put that in its own ``observe(_:)``. For example, if you needed to reload a table view or
    /// collection view when a collection changes:
    ///
    /// ```swift
    /// override func viewDidLoad() {
    ///   super.viewDidLoad()
    ///
    ///   observe { [weak self] in
    ///     guard let self
    ///     else { return }
    ///
    ///     dataSource = model.items
    ///     tableView.reloadData()
    ///   }
    /// }
    /// ```
    ///
    /// ## Cancellation
    ///
    /// The method returns an ``ObserveToken`` that can be used to cancel observation. For
    /// example, if you only want to observe while a view controller is visible, you can start
    /// observation in the `viewWillAppear` and then cancel observation in the `viewWillDisappear`:
    ///
    /// ```swift
    /// var observation: ObserveToken?
    ///
    /// func viewWillAppear() {
    ///   super.viewWillAppear()
    ///   observation = observe { [weak self] in
    ///     // ...
    ///   }
    /// }
    /// func viewWillDisappear() {
    ///   super.viewWillDisappear()
    ///   observation?.cancel()
    /// }
    /// ```
    ///
    /// - Parameter apply: A closure that contains properties to track and is invoked when the value
    ///   of a property changes.
    /// - Returns: A cancellation token.
    @discardableResult
    public func observe(
        _ apply: @escaping @MainActor @Sendable () -> Void,
        sideEffect: @escaping @Sendable () -> Void
    ) -> ObserveToken {
        let token = UIComponent.observe {
            MainActor._assumeIsolated {
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

extension MainActor {
  // NB: This functionality was not back-deployed in Swift 5.9
    static func _assumeIsolated<T: Sendable>(
    _ operation: @MainActor () throws -> T,
    file: StaticString = #fileID,
    line: UInt = #line
  ) rethrows -> T {
    #if swift(<5.10)
      typealias YesActor = @MainActor () throws -> T
      typealias NoActor = () throws -> T

      guard Thread.isMainThread else {
        fatalError(
          "Incorrect actor executor assumption; Expected same executor as \(self).",
          file: file,
          line: line
        )
      }

      return try withoutActuallyEscaping(operation) { (_ fn: @escaping YesActor) throws -> T in
        let rawFn = unsafeBitCast(fn, to: NoActor.self)
        return try rawFn()
      }
    #else
      return try assumeIsolated(operation, file: file, line: line)
    #endif
  }
}
