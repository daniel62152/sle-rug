module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// Syntax for question, computed question, block, if-then-else, if-then
syntax Question
  =  "if" "("Expr")" "{" Question* "}"
  | "if" "("Expr")" "{" Question* "}" "else" "{" Question* "}"
  | Str Id":" Type
  | Str Id":" Type "=" Expr 
  ;

// Syntax for Expressions in QL
// true/false are reserved keywords for some of the expressions.
syntax Expr 
  = Id \ "true" \ "false"
  | Str
  | Int
  | Bool
  | bracket "(" Expr ")"
  | "!" Expr
  >
  non-assoc (
      left Expr "*" Expr \ "true" \ "false"
    | non-assoc Expr "/" Expr \ "true" \ "false"
  )
  >
  left (
      left Expr "+" Expr \ "true" \ "false"
    | left Expr "-" Expr \ "true" \ "false"
  )
  >
  non-assoc (
  	  non-assoc Expr "\>" Expr \ "true" \ "false"
    | non-assoc Expr "\<" Expr \ "true" \ "false"
    | non-assoc Expr "\>=" Expr \ "true" \ "false"
    | non-assoc Expr "\<=" Expr \ "true" \ "false"
  )
  >
  left (
      left Expr "==" Expr
    | left Expr "!=" Expr
  )
  > left Expr "&&" Expr
  > left Expr "||" Expr
  ;
  
// Types that are accepted in QL
syntax Type
  = "string"
  | "integer"
  | "boolean"
  ;  

// String lexical in QL  
lexical Str = "\"" ![\"]* "\"" ;

// Int lexical in QL
lexical Int = [0-9]+;

// Bool lexical in QL
lexical Bool = "true" | "false";
