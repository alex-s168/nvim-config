
["impl"   "const" "dyn"   "let" "mut"
 "struct" "pub"   "enum"  "fn"  "trait" "impl" "if" "else"
 "await"  "async" "match" "as"  "yield" "loop" "while" "for"
 "is"     "not"   "and"   "or"  "varpos" "vardict"
] @keyword

(for_expr "in" @keyword)

[(void)
 "self"
 (self_t_expr)
 (trait_t_expr)
 ] @variable.builtin

(binary_op operator: (_) @operator)

(field_def
  def: (kv_arg
         key: (_) @property))

[(comment)
 (doc_comment)
 ] @comment

(doc_comment_value) @comment.documentation

((doc_comment_value) @injection.content
 (#set! injection.language "typst")
 )

[(decimal_num)
 (hex_num)
 (bin_num)
] @number

[(null)
 (true)
 (false)
] @constant.builtin

(str_template
  "${" @punctuation.special
  expr: (_) @embedded
  "}" @punctuation.special)

(str_escape) @escape

(str) @string
(raw_str) @string

(id) @variable

((id) @type
 (#match? @type "^[A-Z]"))

((id) @type
 (#match? @type "^(bool|int|uint|u8|u16|u32|u64|i8|i16|i32|i64)$"))

(call_expr
  fn: (id) @function.call
  (#match? @function.call "^[a-z_]"))

(call_expr
  fn: (access_expr
        field: (_) @function.call
        (#match? @function.call "^[a-z_]")))

(call_expr
  fn: (inferred_access_expr
        field: (_) @function.call
        (#match? @function.call "^[a-z_]")))

(paren_arglist
  (kv_arg
    key: (_) @variable.parameter))

(fn_arg name: (_) @variable.parameter)

(fn_def name: (_) @function)

["(" ")"
 "{" "}"
 "[" "]"
 ] @punctuation.bracket

(lambda ["|"] @punctuation.bracket)

[
  "<:" "," "." "=>" ":" "=" ";"
 ] @punctuation.delimiter

(access_expr ["."] @operator)

[
  ">>" "<<" "<=" ">=" ">" "<" ".." "..<" "..="
  "==" "!=" "?"
] @operator

(outer_attr) @attribute
