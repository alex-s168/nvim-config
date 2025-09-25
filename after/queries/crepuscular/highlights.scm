; megic

(identifier) @variable

(tag) @label ; @constructor

[
 "(" ")"
 "{" "}"
 "[" "]"
 ] @punctuation.bracket

[
 "."
 ","
 "|"
 "->"
 ":"
 ] @punctuation.delimiter

[
 (comment)
 (doc_comment)
 (section_comment)
 ] @comment

(num_literal) @constant.builtin

[(char_literal)
 (string_literal)
 ] @string

(escape_sequence) @escape

["+" "-"
 "*" "/"
 "=>" "++"
 "::"
 ] @operator

[
 "def"
 "type"
 "with"
 "extensible"
 "extend"
 "union"
 "def"
 "await"
 "let"
 "if"
 "then"
 "else"
 "in"
 "match"
 "and"
 "or"
 ] @keyword
