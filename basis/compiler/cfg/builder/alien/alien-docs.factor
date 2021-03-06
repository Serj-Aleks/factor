USING: alien alien.libraries compiler.cfg.builder help.markup
help.syntax literals make multiline sequences stack-checker.alien
strings ;
IN: compiler.cfg.builder.alien

<<
STRING: ex-caller-return
USING: compiler.cfg.builder.alien make prettyprint ;
[
    T{ ##alien-invoke { reg-outputs { { 1 int-rep RAX } } } } ,
    T{ alien-invoke-params { return pointer: void } }  caller-return
] { } make  .
{
    T{ ##alien-invoke { reg-outputs { { 1 int-rep RAX } } } }
    T{ ##box-alien { dst 116 } { src 1 } { temp 115 } }
}
;
>>

HELP: caller-linkage
{ $values
  { "params" alien-node-params }
  { "symbol" string }
  { "dll" dll }
}
{ $description "This word gets the name and library to use when linking to a function in a dynamically loaded dll. It is assumed that the library exports the undecorated name, regardless of calling convention." } ;

HELP: caller-return
{ $values { "params" alien-node-params } }
{ $description "If the last alien call returns a value, then this word will emit an instruction to the current sequence being constructed by " { $link make } " that boxes it." }
{ $examples { $unchecked-example $[ ex-caller-return ] } } ;

HELP: check-dlsym
{ $values { "symbol" string } { "library" library } }
{ $description "Checks that a symbol with the given name exists in the given library. Throws an error if not." } ;

HELP: unbox-parameters
{ $values { "parameters" sequence } { "vregs" sequence } { "reps" sequence } }
{ $description "Unboxes a sequence of parameters to send to an ffi function." } ;

ARTICLE: "compiler.cfg.builder.alien"
"CFG node emitter for alien nodes"
"The " { $vocab-link "compiler.cfg.builder.alien" } " vocab implements " { $link emit-node } " methods for alien nodes." ;

ABOUT: "compiler.cfg.builder.alien"
