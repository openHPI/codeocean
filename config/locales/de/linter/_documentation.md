# PyLint translation

The files in this folder are used to translate PyLint results from the original English output to German.

## Structure

The following hierarchy has been implemented:

1. `severity` of the linter check result
   1. The `severity_name` translates the severity itself
2. code of the linter check result
3. A list of required values for the actual translation
   1. `example`: not used anywhere, just for reference when editing this yml file
   2. `name`: Title of the linter check
   3. `regex`: A regex used to translate dynamic parts with _named_ capture groups
   4. `replacement`: A fix replacement translation which is used instead of the
                     original English output. It may refer to one of the named capture
                     groups to include dynamic content from the English original
   5. `log_missing`: Specifies whether missing translations should be logged to Sentry
4. Optionally a named capture group from the regex
5. A list of fix translations for _values / matches_ of the named capture group

## Additional information for `error.syntax-error`

- `replacement`: `context`, and `line` are matched as well but are currently not used
- `what.invalid decimal literal`: An example would be `100_years`
- `waht_exactly`: 
  - It must start with a space character
  - The following errors are used in the context of an f-string:
    - `empty expression not allowed`
    - `single`
    - `unmatched`
- The following capture groups are used without translation:
  - `actual`
  - `suggestion`
  - `context`
  - `line`
