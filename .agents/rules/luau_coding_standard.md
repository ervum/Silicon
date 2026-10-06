---
trigger: always_on
---



### 1. File Initialization & Pragmas
- **Line 1**: Every file MUST begin with `--!strict` followed by an empty line (`1 \n`).
- Every variable, parameter, return value, and placeholder discard token must be explicitly typed.

---

### 2. Spatial Architecture & Logical Sectioning (Soft vs. Hard Newlines)
Code readability is spatial geometry. Whitespace signifies semantic distance:
- **Soft Sectioning (`1 \n` / 1 empty line)**: Used inside functions and local scopes to separate logical sub-steps within the same operational unit (e.g., variable preparation -> core logic -> diagnostics/logging).
  - **Operational Isolation**: Within any block or scope, distinct operational phases (state mutation, external call, diagnostic logging, and return) must NEVER be visually glued together on adjacent lines.
  - **Terminal Return Isolation**: A `return` or `return <value>` at the end of a block or function must always be preceded by an empty line (`1 \n`) if any statements precede it in that scope.
  - **Canonical Example**:
    ```luau
    -- CORRECT:
    LastKnownScriptHashes[RelativePath] = nil;

    print(`[Silicon Export] Synchronized deletion of <{BaseName}> to local disk.`);

    return;

    -- INCORRECT (FORBIDDEN):
    LastKnownScriptHashes[RelativePath] = nil;
    print(`[Silicon Export] Synchronized deletion of <{BaseName}> to local disk.`);
    return;
    ```
- **Hard Sectioning (`3 \n` / 3 empty lines)**: Used at the outermost module scope to delineate major macroscopic chapters of the file:
  - File pragma & imports -> `3 \n`
  - Service locators & dependencies -> `3 \n`
  - Settings, definitions & configuration tables -> `3 \n`
  - Function declarations -> `3 \n`
  - Event listeners & main execution code -> `3 \n`
  - Final module return

---

### 3. Semicolons & Single-Line Guard Termination
- **Mandatory Statement Semicolons**: Every statement, variable assignment, function call, and multiline return must terminate with a semicolon (`;`).
- **No Semicolons After `end`**: The `end` keyword inherently signifies closure; placing a semicolon after `end` is forbidden.
- **Single-Line Guard Exception**: In single-line guard statements (`if ... then break end`, `if ... then continue end`, `if ... then return end`), semicolons are completely omitted from the line.

---

### 4. Expression Isolation (Parenthesitis vs. Atomic Syntax)
Code is categorized as either **atomic** (already resolved values, literals, identifiers, or natural English logic) or an **expression** (an unsolved operation or compound lookup that yields a result):
- **Must Wrap in `(...)`**:
  - Member access on dependencies and instances: `(Dependencies.Import)`, `(script.Name)`, `(Player.Character)`
  - Enum items: `(Enum.HttpContentType.ApplicationJson)`
  - Arithmetic and math bounds: `(#PathObjects - 1)`, `for i = 0, (math.huge) do`
  - Mathematical computations: subdivide compound math into nested logical components:
    `local Obtained: boolean = (((1 / Chance) * Luck) > 50.0);`
- **Do NOT Wrap**:
  - Implicit boundaries: Function call arguments already possess an enclosing boundary: `foo(bar.baz)` (never `foo((bar.baz))`).
  - English logical keywords: `and`, `or`, and `not` represent grammatical glue, not mathematical expressions:
    `local Fallback: Instance = Primary or Default;`

---

### 5. Columnar Alignment & Table Formatting
- **Tables Only**: Columnar alignment of `=` and `:` is **strictly reserved for tables** (dictionaries, configurations, and type definitions). General procedural variable declarations use standard single-space formatting.
- **Trailing Commas**: Multiline table declarations must include a trailing comma on the final entry. Single-line table declarations omit trailing commas.
- **Spaced Empty Tables**: Empty tables are always written with an internal space: `{ }` (never `{}`).

---

### 6. Comment Taxonomy & Symbol Mentions
- **Permanent Architectural Comments**: Always use a triple-hyphen arrow: `---> <Explanation>`.
- **Temporary / Action Comments**: Use standard double hyphens: `-- TODO: <Note>`.
- **Multiline Comments**: Enclosed in three brackets: `--[[[ ... ]]]--`.
- **Symbol Delimiters**: When referencing functions, variables, instances, or types inside comments, enclose them in angle brackets `<Symbol>` or backticks \`Symbol\`.

---

### 7. Variable Naming Conventions
- **Unused Placeholders**: Unused variables must be named `_` and **must still be explicitly typed** (`_: number`).
- **Descriptive PascalCase**: Variables must be written in full, unabbreviated **PascalCase**, even if long (`PlayerCharacter`, `ExportDebounceTime`). Never abbreviate local variables inside statement scopes (e.g., do not write `local CN = ...`; write `local ClassName: string = ...`).
- **Exception A (Roblox Services & Core Singletons)**: Abbreviated to standard capital initials:
  `WS` (Workspace), `SSS` (ServerScriptService), `HRP` (HumanoidRootPart), `CHS` (ChangeHistoryService), `SES` (ScriptEditorService), `HTTP` (HttpService), `RS` (RunService), `D` (Debris).
- **Exception B (Loop Iterators)**: Temporal, universally understood indices `i`, `j`, `k` are permitted.
- **THE ABSOLUTE BAN ON `v`**: The variable name `v` is strictly forbidden. Values must always be given a descriptive name reflecting their type (e.g., `ChildInstance`, `PlayerEntity`, `Connection`).
- **Exception C (English Acronyms & Initialisms)**: Standard English acronyms (`ID`, `TV`, `URL`, `HTTP`, `JSON`, `API`, `UI`, `GUI`, `FPS`, `UUID`, `RGB`) are always written in **FULL CAPS** with **NO underscores or hyphens**:
  `PlayerID`, `PlaceID`, `AssetID`, `SmartTV`, `TargetURL`, `JSONPayload`, `UserUI`, `TargetFPS`.

---

### 8. Luau Type System Idiosyncrasies
- **Tail-Casting Anonymous Values**: Anonymous table literals, anonymous closure returns, and pure type modules must use tail casting (`:: <Type>;`) to enforce explicit contracts. Named returns (`return Connect;`, `return Table;`) never use tail casts.
- **Optional Index Keys**: Maps and arrays must type keys with optional markers to reflect nullable lookups in strict mode: `{ [string?]: any }`, `{ [number?]: RBXScriptConnection }`.
- **Spaced Variadics**: Variadic arguments and returns must have internal padding: `(( ... any) -> ( ... any))`.
- **Explicit Parentheses on Return Types**: Because `()` signifies void, functions returning values must enclose their return type in parentheses: `(): ()`, `(): (boolean)`, `(): (Instance, number)`.
- **The 3-Parentheses Function Type Rule**: Function signatures assigned to types or variables must consist of three pairs of parentheses:
  `((Params) -> (Returns))`
  Example:
  ```luau
  type ActionCallback = ((Instance, number?) -> (boolean));
  local Handler: ((string) -> ()) = (Dependencies.Handler);
  ```

---

### 9. Standard Library Shadowing
- Never shadow global libraries (`table`, `math`, `os`, `string`) as a performance micro-optimization.
- Only shadow and reassign a global library if you are **actively adding, modifying, or monkey-patching methods** on that global within the module.

---

### 10. Data Structures, Traversal & Expression Idioms
- **Zero-Indexed Traversal**: Mathematical offsets, chunk pagination, and hierarchical traversal structures explicitly start at index `0`:
  `local Paths: { [number?]: Instance } = { [0] = RootInstance };`
  `for Index: number = 0, (math.huge) do`
- **Boolean Normalization**:
  - Default true: `Variable = (Variable ~= false);`
  - Default false: `Variable = Variable or false;`
  - Prefer ternary assignments: `Result = Condition and TrueValue or FalseValue;`
- **String Literals vs. Interpolation**:
  - Plain strings use single quotes: `'Heartbeat'`, `'Script'`, `'POSTGETData'`.
  - Dynamic strings with embedded variables or inline ternaries use backticks:
    `print(`Successfully transferred {Count} item{(Count ~= 1) and 's' or ''}!`);`

---

### 11. Serialization Metaproperties & Control Sentinels
- Engine/metadata fields use double underscores: `__Properties__`, `__Attributes__`, `__Tags__`, `__Source__`, `__DuplicatedIndex__`, `__Unnamed__`.
- Execution control sentinels use uppercase bracketed strings: `'{STOP UNTIL TIMEOUT}'`, `'{RETURNED ARGUMENTS}'`, `'{NO TIMEOUT}'`.

---

### 12. Globalization & Unification (Zero Literal Repetition)
Never repeat literals, magic numbers, or hardcoded strings across operational scripts. Centralize all static data into single-source-of-truth modules:
1. **Geometric / Dimensional Tables**: Group axis and component names (`{ 'X', 'Y', 'Z' }`) into a centralized `Dimensions` module.
2. **Units & Mathematical Ratios**: Group conversion ratios (e.g., `SecondsPerMinute = 60`, `SecondsPerHour = 3600`) into a `TimeUnits` or `Conversion` module.
3. **Gameplay & Policy Configuration**: Decouple limits (e.g., `MaxJumpCount`, `SprintSpeed`) into dedicated `Settings` or `Configurations` modules.
4. **Localization & Human Text**: Place all player-facing and system notification text into dedicated language dictionaries (`English`, `Spanish`).

---

### 13. Polyglot Parity: Python & Tooling Scripts
When authoring or modifying Python scripts (e.g., companion daemons like `Silicon/Silicon.py`, automation utilities) in this workspace, the author's architectural philosophy and formatting invariants apply with equal force:
1. **Mandatory Statement Semicolons**: Every statement, variable assignment, import, function call, and return must terminate with a semicolon (`;`). (No semicolons after `def`, `class`, `if:`, `for:`, `while:`, `try:`, `except:`).
2. **Strict PascalCase Only**: All variables, parameters, functions, classes, and exception handles (`except Exception as Error:`) must use unabbreviated **PascalCase**. Snake_case and camelCase are strictly forbidden.
3. **Parenthesized Return Types**: Function return type annotations must be wrapped in parentheses: `def Handler(...) -> (None):`, `def Check() -> (bool):`.
4. **Spatial Geometry**:
   - `3 \n` between macroscopic chapters (Imports -> Globals/Tables -> Functions -> Main block).
   - `1 \n` between operational steps within functions.
5. **Columnar Alignment & Collections**: Columnar alignment of `:` is strictly reserved for dictionaries. Spaced empty collections `{ }`, `[ ]` and trailing commas on multiline dictionaries are mandatory.