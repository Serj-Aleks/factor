IN: ui.tools.error-list
USING: help.markup help.syntax ui.tools.common ui.commands ;

ARTICLE: "ui.tools.error-list" "UI error list tool"
"The error list tool displays messages generated by tools which process source files and definitions. To display the error list, press " { $command tool "common" show-error-list } " in any UI tool window."
$nl
"The " { $vocab-link "source-files.errors" } " vocabulary contains backend code used by this tool."
{ $heading "Message icons" }
{ $table
    { "Icon" "Message type" "Reference" }
    { { $image "vocab:ui/tools/error-list/icons/note.tiff" } "Parser note" { $link "parser" } }
    { { $image "vocab:ui/tools/error-list/icons/syntax-error.tiff" } "Syntax error" { $link "syntax" } }
    { { $image "vocab:ui/tools/error-list/icons/compiler-warning.tiff" } "Compiler warning" { $link "compiler-errors" } }
    { { $image "vocab:ui/tools/error-list/icons/compiler-error.tiff" } "Compiler error" { $link "compiler-errors" } }
    { { $image "vocab:ui/tools/error-list/icons/unit-test-error.tiff" } "Unit test failure" { $link "tools.test" } }
    { { $image "vocab:ui/tools/error-list/icons/help-lint-error.tiff" } "Help lint failure" { $link "help.lint" } }
    { { $image "vocab:ui/tools/error-list/icons/linkage-error.tiff" } "Linkage error" { $link "compiler-errors" } }
} ;

ABOUT: "ui.tools.error-list"
