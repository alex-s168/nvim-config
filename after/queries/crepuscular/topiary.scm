; do not format inside these
[(string_literal)
 (char_literal)
 (comment)
 (doc_comment)
 ] @leaf

; TODO: light asciidoc formatting

(definition) @allow_blank_line_before

(doc_comment_value) @append_hardline
(doc_comment) @prepend_hardline @append_hardline

(comment) @append_hardline

(let_binding
  "let" @prepend_spaced_softline @append_space
  "=" @prepend_space @append_space
  value: (_) @prepend_indent_start @append_indent_end @prepend_begin_measuring_scope @append_end_measuring_scope
  body: (_) @prepend_hardline
  (#scope_id! "def"))
; ; remove `in`
; (let_binding
;  "in" @delete)
; add `in`
(let_binding
  value: (_) @append_delimiter @append_space
  (#delimiter! " in"))

(def
  ":" @prepend_space @append_spaced_softline
  signature: (_) @prepend_spaced_softline @prepend_indent_start @append_indent_end)
(def
  "=" @prepend_space @append_spaced_softline
  value: (_) @prepend_indent_start @prepend_begin_measuring_scope
             @append_indent_end @append_end_measuring_scope
  (#scope_id! "def"))
(def "def" @append_space)

(if_expr
  then: (_) @prepend_begin_measuring_scope @append_end_measuring_scope
  (#scope_id! "if_expr.then"))
(if_expr
  else: (_) @prepend_begin_measuring_scope @append_end_measuring_scope
  (#scope_id! "if_expr.else"))
(if_expr
  "if" @prepend_space @append_space
  "then" @prepend_space @append_spaced_softline
  then: (_) @prepend_indent_start
            @append_indent_end @append_hardline
  "else" @prepend_space @append_spaced_softline
  else: (_) @prepend_indent_start
            @append_indent_end)

; enable when delete OR add
(match_expr
  "with"
  . "|" @delete)
; enable when add
(match_expr
  "with"
  . (match_arm) @prepend_delimiter @prepend_space
  (#delimiter! "|"))

((match_arm) @append_hardline . (match_arm))
(match_arm
  "->" @prepend_space @append_spaced_softline)
(match_arm
  "|" @prepend_spaced_softline @append_space)
(match_expr
  "|" @append_space)
(match_expr
  "match" @append_space
  "with" @prepend_space @append_hardline
  . "|"?
  . (match_arm) @prepend_indent_start @append_indent_end)

; add newline between two consecutive definitions
((definition) @append_hardline . (definition))

(list_expression 
  "," @append_spaced_softline)

(list_expression
  "[" @append_begin_measuring_scope @append_empty_softline @append_indent_start
  "]" @append_end_measuring_scope @prepend_empty_softline @append_indent_end
  (#scope_id! "list_expr"))

; remove trailing comma
(list_expression
  "," @delete . "]")

(extensible_union
  "extensible" @append_space
  "union" @append_space)

(extend_decl
  "extend" @append_space
  "with" @prepend_spaced_softline @append_space
  tag: (_) @append_space)

(atom
  "(" @delete
  . (expression (atom))
  . ")" @delete)

(full_partial_type_definition
  "type" @append_space
  "=" @prepend_space @append_spaced_softline)

(type_definition
  "[" @prepend_space
  "]" @append_space)
(type_definition
  "," @append_space)
(type_definition
  arg: (_) @append_space)
(type_definition
  "type" @append_space
  "=" @prepend_space @append_spaced_softline)

(function_call
  "," @append_spaced_softline)



; ==== SIMILAR TO record_type ====
(record_expr_field
  ":" @append_spaced_softline)
(record_expr
  "," @append_spaced_softline)
(record_expr
  "{" @append_empty_softline @append_begin_measuring_scope @append_indent_start
  "}" @prepend_empty_softline ; TODO: make this one configurable; also see lists and others
      @append_end_measuring_scope @prepend_indent_end
  (#scope_id! "record_expr"))
; remove trailing comma
(record_expr
  "," @delete . "}")
; ====^^^^^^^^^^^^========

(atom
  "(" @append_begin_measuring_scope @append_empty_softline @append_indent_start
  ")" @append_end_measuring_scope @prepend_empty_softline @append_indent_end
  (#scope_id! "paren_expr"))

(await_expr
  "await" @append_space)

(type_downcast
  "::" @prepend_spaced_softline @append_space)

(lambda
  ":" @prepend_space @append_space)
(lambda
  "->" @prepend_space @append_spaced_softline
  body: (_) @prepend_indent_start @append_indent_end)

(tag_expr
  tag: (_) @append_space)

(binary_expr
  left: (_) @append_spaced_softline
  right: (_) @prepend_space)




(type_atom
  "(" @append_begin_measuring_scope @append_empty_softline @append_indent_start
  ")" @append_end_measuring_scope @prepend_empty_softline @append_indent_end
  (#scope_id! "paren_type"))

(fn_type
  "->" @prepend_space @append_spaced_softline)


; ==== SIMILAR TO record_expr ====
(record_type_field
  ":" @append_spaced_softline)
(record_type
  "," @append_spaced_softline)
(record_type
  "{" @append_empty_softline @append_begin_measuring_scope @append_indent_start
  "}" @prepend_empty_softline ; TODO: make this one configurable; also see lists and others
      @append_end_measuring_scope @prepend_indent_end
  (#scope_id! "record_type"))
; remove trailing comma
(record_type
  "," @delete . "}")
; ====^^^^^^^^^^^^========

; 'Tag Unit -> 'Tag
(tagged_type
  type: (type_atom (just_type (path
          (identifier) @delete
            (#eq? @delete "Unit")))))
(tagged_type
  type: (_) @prepend_space)

(type_atom
  "(" @delete
  . (type (type_atom))
  . ")" @delete)

; TODO:
; $.union_type,
; $.partial_union_type,
; $.parametrized_type,
; $.with_type,
; $.recursive_type,


; TODO: disable-format-regions
; TODO: folding query
; TODO: wrap confusing expressions (in terms of precedence) in parens
