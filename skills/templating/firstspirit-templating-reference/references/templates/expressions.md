# Templates: arithmetic expressions and constants

Operators and literal values for `$CMS_VALUE(...)$`, `$CMS_SET(...)$`, `$CMS_IF(...)$` and the other
instructions. **[odfs]** *Template development › Template syntax › Expressions* (Arithmetic
expressions, Constants), FirstSpirit 2026.5. Comparison and logic in conditions:
`variables-conditionals.md`. Not run on a server **[verify]**.

## Arithmetic

| Operator | Meaning | Example, result |
| --- | --- | --- |
| `+` | addition | `1 + 1` gives `2`; `3.1234 + 3.1234` gives `6.2468` |
| `-` | subtraction | `3.1234 - 2.1` gives `1.0234` |
| `*` | multiplication | `3.1234 * 2.1` gives `6.55914` |
| `/` | division | `2 / 2` gives `1`; `3.1234 / 2.1` gives `1.4873` |
| `%` | modulo (remainder of the division of two integers) | `7 % 2` gives `1` |

Operands may be constants or variables (`2 * x` after `$CMS_SET(x, 2)$`). Integers and decimals mix.
The precision and rounding of **division** are configurable: `#mathContext` (`system-objects.md`).

**Precedence**, highest first:

1. `*` `/` `%`
2. `+` `-`
3. `<` `>` `<=` `>=`
4. `==` `!=`
5. `&&`
6. `||`

Equal precedence is evaluated left to right; parentheses override, innermost first:
`2 + 3 * 4` is `14`, `(2 + 3) * 4` is `20`, `(2 * 3 + 6) / (2 + 2)` is `3`,
`(2 * (3 + 6)) / (2 + 2)` is `4.5`. Arithmetic is always evaluated before comparison and logic.
(Comparison operators: `<`, `>`, `<=`, `>=`.)

## Constants (literal values)

| Kind | Literal | Java type produced |
| --- | --- | --- |
| String | `"That is a text."`, with escaped quotes `"say \"hi\""` | `java.lang.String` |
| Integer | `42` | `java.math.BigInteger` |
| Decimal | `3.1333` | `java.math.BigDecimal` |
| Boolean | `true`, `false` | `java.lang.Boolean` |
| List | `["a", "b", "c"]`, mixed `[1, "a", false, 43.5]` | list |
| List, range | `[1..10]` (ascending or descending series, **lists only**) = `[1, 2, …, 10]` | list of `BigInteger` |
| Map | `{1:"alpha", "3":3, true:true}`, keys may be of any type | map |
| Set | `{"a", "b", "c"}`, `{1, 45, 10}` | set |

Seeing the type: `$CMS_VALUE(42.class)$` prints `java.math.BigInteger`. Numbers are therefore
**not** `Integer`/`Double`; keep that in mind when a method expects another number type. A `{…}`
with `key:value` pairs is a map, one with bare values a set.
A set literal has bare values only; `[ … ]` is always a list.
