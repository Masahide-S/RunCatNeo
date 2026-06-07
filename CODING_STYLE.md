# Coding Style Guidelines

These are the authoritative style rules for all Swift code in this repository.

## Language

- All code, identifiers, comments, and commit messages must be written in **English**.
- User-facing text must go through the localization system (`UserInterface/Resources`).

## Naming

- Use meaningful and descriptive names.
- Acronyms are all-lowercase or all-uppercase (✅ `userID`, `fileURL`; ❌ `userId`, `fileUrl`).
- In principle, avoid abbreviated names (✅ `count`, `image`; ❌ `cnt`, `img`).

## Comments

- Default to no code comments; choose names that make the code self-explanatory.
- Do not use `// MARK:` comments; organize members by the ordering convention instead.

## Formatting

- In multiline string literals, indent the content and the closing `"""` one level (4 spaces) deeper than the line containing the opening `"""`:

  ```swift
  let json = """
      { "title": "Card" }
      """
  ```

- When a function signature or call does not fit on one line, put one parameter per line and the closing parenthesis on its own line.
- Do not put a trailing comma after the last element of parameter and argument lists.
- Put a trailing comma after the last element of multiline collection literals:

  ```swift
  userDefaultsClient.register([
      .runnerID: RunnerKind.cat.id,
      .speedDecreasesUnderLoad: false,
  ])
  ```

## Code Patterns

- Prefer `guard` with early return over nested `if` for optional unwrapping and validation.
- Write simple value mappings as switch expressions with single-line cases (`case .cat: 5`).
- Prefer leading-dot shorthand and semantic constants when the type is inferable (`.zero` over `0`).
- Within a type, order members as: stored dependencies (`private let`), state properties, `init`, public methods, private helpers, nested types at the end.

## SwiftUI

- Pass `bundle: .module` to every localized `Text`/`Label` initializer.
- Do not add `#Preview` blocks.

## Tests

- Name test functions in snake_case as `subject_condition_expectation` (e.g. `decode_throws_when_title_missing`, `send_task_reloads_customMetricsSources_from_user_defaults`).
- Separate arrange, act, and assert blocks with single blank lines.
- Compare whole `Equatable` values with a single `#expect` instead of asserting properties one by one; add `Equatable` conformance to entities when tests need it.
- Use `AllocatedUnfairLock` for mutable state captured by mock dependency closures.

## License Headers

- Every source file under `LocalPackage/Sources/` carries the Apache-2.0 license header. Preserve it when editing and include it when creating new files.
- Test files under `LocalPackage/Tests/` omit the header by convention and start directly with `import`.

## Simplicity

- Avoid unnecessary complexity.
- Prefer readable and self-explanatory code over clever solutions.
