module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(AId name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = ifCond(AExpr cond, list[AQuestion] then)
  | ifElseCond(AExpr cond, list[AQuestion] ifTrue, list[AQuestion] ifFalse)
  | normalQ(str phrase, AId name, AType typeName)
  | computedQ(str phrase, AId name, AType typeName, AExpr expr)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | var(str string)
  //| var(int val)
  //| var(bool boolean)
  | not(AExpr arg)
  | mul(AExpr expr1, AExpr expr2)
  | div(AExpr expr1, AExpr expr2)
  | add(AExpr expr1, AExpr expr2)
  | sub(AExpr expr1, AExpr expr2)
  | gt(AExpr lhs, AExpr rhs)
  | lt(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = typeof(str typeName);