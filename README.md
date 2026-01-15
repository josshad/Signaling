# Description
In projects with Rx/Combine there may be a common pattern of sending events/actions to parent view models or coordinators.

In that case you may want to restrict sending events only from inside of a child view model. A common solution in this case would be something like this:

```swift
final class ViewModel {
  enum Action {
    case showAlert
  }

  private(set) lazy var onAction = actionRelay.asSignal()
  private let actionRelay = PublishRelay<Action>()

  func doSmth() {
    actionRelay.accept(.showAlert)
  }
}
```

In this case, in the parent entity you will subscribe to the `onAction` property. You have no ability to modify `onAction` or emit another action from any place except the ViewModel.

---

Main idea of this wrapper — to remove duplicating these two variables in any view model.


# Usage

## RxSwift
```swift
import RxSignaling

final class ViewModel {
  enum Action {
    case showAlert
  }

  @Signaling<Action> var actions

  func doSmth() {
    _actions.accept(.showAlert)
  }
}

final class Parent {
  private let viewModel = ViewModel()
  private let disposeBag = DisposeBag()

  init() {
    viewModel.$actions
      .emit(onNext: {
        switch $0 {
          ..
        }
      })
      .disposed(by: disposeBag)
  }
}
```

## Combine
```swift
import CombineSignaling

final class ViewModel {
  enum Action {
    case showAlert
  }

  @Signaling<Action> var actions

  func doSmth() {
    _actions.send(.showAlert)
  }
}

final class Parent {
  private let viewModel = ViewModel()
  private let cancallables = Set<AnyCancellable>()

  init() {
    viewModel.$actions
      .sink(receiveValue: {
        switch $0 {
          ..
        }
      })
      .store(in: cancellables)
  }
}
```

Pros: 
- the code becomes more compact
- we use common approach to subscribing to `$<variable>` as with `@Publisher` property wrapper
- you can't modify or emit event from outside of ViewModel
- you can't change property (as you still can do with `lazy var` in the first approach)

# Installation

### RxSwift
```
...
dependencies: [
  .package(url: "https://github.com/josshad/Signaling.git", .upToNextMajor(from: "1.0.0"))
],
targets: [
  .target(
    name: "...",
      dependencies: [
        .product(name: "RxSignaling", package: "signaling")
      ]
  ),
]
```

### Combine
```
...
dependencies: [
  .package(url: "https://github.com/josshad/Signaling.git", .upToNextMajor(from: "1.0.0"))
],
targets: [
  .target(
    name: "...",
      dependencies: [
        .product(name: "CombineSignaling", package: "signaling")
      ]
  ),
]
```
