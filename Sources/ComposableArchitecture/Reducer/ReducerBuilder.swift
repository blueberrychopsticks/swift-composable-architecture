/// A result builder for combining reducers into a single reducer by running each, one after the
/// other, and merging their effects.
///
/// It is most common to encounter a reducer builder context when conforming a type to
/// ``ReducerProtocol`` and implementing its ``ReducerProtocol/body-swift.property-97ymy`` property.
///
/// See ``CombineReducers`` for an entry point into a reducer builder context.
@resultBuilder
public enum ReducerBuilder<State, Action> {
  @inlinable
  public static func buildArray<R: ReducerProtocol>(_ reducers: [R]) -> _SequenceMany<R>
  where R.State == State, R.Action == Action {
    _SequenceMany(reducers: reducers)
  }

  @inlinable
  public static func buildBlock() -> EmptyReducer<State, Action> {
    EmptyReducer()
  }

  @inlinable
  public static func buildBlock<R: ReducerProtocol>(_ reducer: R) -> R
  where R.State == State, R.Action == Action {
    reducer
  }

  @inlinable
  public static func buildEither<R0: ReducerProtocol, R1: ReducerProtocol>(
    first reducer: R0
  ) -> _Conditional<R0, R1>
  where R0.State == State, R0.Action == Action {
    .first(reducer)
  }

  @inlinable
  public static func buildEither<R0: ReducerProtocol, R1: ReducerProtocol>(
    second reducer: R1
  ) -> _Conditional<R0, R1>
  where R0.State == State, R0.Action == Action {
    .second(reducer)
  }

  @inlinable
  public static func buildExpression<R: ReducerProtocol>(_ expression: R) -> R
  where R.State == State, R.Action == Action {
    expression
  }

  @inlinable
  public static func buildFinalResult<R: ReducerProtocol>(_ reducer: R) -> R
  where R.State == State, R.Action == Action {
    reducer
  }

  @inlinable
  public static func buildLimitedAvailability<R: ReducerProtocol>(
    _ wrapped: R
  ) -> Reduce<State, Action>
  where R.State == State, R.Action == Action {
    Reduce(wrapped)
  }

  @inlinable
  public static func buildOptional<R: ReducerProtocol>(_ wrapped: R?) -> R?
  where R.State == State, R.Action == Action {
    wrapped
  }

  @inlinable
  public static func buildPartialBlock<R: ReducerProtocol>(
    first: R
  ) -> R
  where R.State == State, R.Action == Action {
    first
  }

  @inlinable
  public static func buildPartialBlock<R0: ReducerProtocol, R1: ReducerProtocol>(
    accumulated: R0, next: R1
  ) -> _Sequence<R0, R1>
  where R0.State == State, R0.Action == Action {
    _Sequence(accumulated, next)
  }

  public enum _Conditional<First: ReducerProtocol, Second: ReducerProtocol>: ReducerProtocol
  where
    First.State == Second.State,
    First.Action == Second.Action
  {
    case first(First)
    case second(Second)

    @inlinable
    public func reduce(into state: inout First.State, action: First.Action) -> EffectTask<
      First.Action
    > {
      switch self {
      case let .first(first):
        return first.reduce(into: &state, action: action)

      case let .second(second):
        return second.reduce(into: &state, action: action)
      }
    }
  }

  public struct _Sequence<R0: ReducerProtocol, R1: ReducerProtocol>: ReducerProtocol
  where R0.State == R1.State, R0.Action == R1.Action {
    @usableFromInline
    let r0: R0

    @usableFromInline
    let r1: R1

    @usableFromInline
    init(_ r0: R0, _ r1: R1) {
      self.r0 = r0
      self.r1 = r1
    }

    @inlinable
    public func reduce(into state: inout R0.State, action: R0.Action) -> EffectTask<R0.Action> {
      self.r0.reduce(into: &state, action: action)
        .merge(with: self.r1.reduce(into: &state, action: action))
    }
  }

  public struct _SequenceMany<Element: ReducerProtocol>: ReducerProtocol {
    @usableFromInline
    let reducers: [Element]

    @usableFromInline
    init(reducers: [Element]) {
      self.reducers = reducers
    }

    @inlinable
    public func reduce(
      into state: inout Element.State, action: Element.Action
    ) -> EffectTask<Element.Action> {
      self.reducers.reduce(.none) { $0.merge(with: $1.reduce(into: &state, action: action)) }
    }
  }
}
