module AST

import Syntax;

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
  = typeOf(str typeName);
  

AForm cst2ast(start[Form] f)
  = cst2ast(f.top);
  
AForm cst2ast((Form)`form <Id f> {<Question* qs>}`)
  = form(id("<f>"), [ cst2ast(q) | Question q <- qs ]); 
 
AQuestion cst2ast((Question)`if (<Expr e>) {<Question* qs>}`)
  = ifCond(cst2ast(e), [ cst2ast(q) | Question q <- qs ]);
  
AQuestion cst2ast((Question)`if (<Expr e>) {<Question* qs1>} else {<Question* qs2>}`)
  = ifElseCond(cst2ast(e), [ cst2ast(q) | Question q <- qs1 ], [ cst2ast(q) | Question q <- qs2 ]);

AQuestion cst2ast((Question)`"<Str s>" <Id f>: <Type t>`)
  = normalQ("<s>", id("<f>"), typeOf("<t>"));

AQuestion cst2ast((Question)`"<Str s>" <Id f>: <Type t> = <Expr e>`)
  = computedQ("<s>", id("<f>"), typeOf("<t>"), cst2ast(e));

AExpr cst2ast((Expr)`<Id x>`)
  = ref(id("<x>"));
 	
AExpr cst2ast((Expr)`<Str x>`)
  = var("<x>");
 	
AExpr cst2ast((Expr)`<Int x>`)
  = var("<x>");
 	
AExpr cst2ast((Expr)`<Bool x>`)
  = var("<x>");
 	
AExpr cst2ast((Expr)`(<Expr e>)`)
  = cst2ast(e);
  
AExpr cst2ast((Expr)`!<Expr e>`)
  = not(cst2ast(e)); 

AExpr cst2ast((Expr)`<Expr expr1> * <Expr expr2>`)
  = mul(cst2ast(expr1), cst2ast(expr2));
 	
AExpr cst2ast((Expr)`<Expr expr1> / <Expr expr2>`)
  = div(cst2ast(expr1), cst2ast(expr2));
	
AExpr cst2ast((Expr)`<Expr expr1> + <Expr expr2>`)
  = add(cst2ast(expr1), cst2ast(expr2));
	
AExpr cst2ast((Expr)`<Expr expr1> - <Expr expr2>`)
  = sub(cst2ast(expr1), cst2ast(expr2));
	
AExpr cst2ast((Expr)`<Expr lhs> \> <Expr rhs>`)
  = gt(cst2ast(lhs), cst2ast(rhs));

AExpr cst2ast((Expr)`<Expr lhs> \< <Expr rhs>`)
  = lt(cst2ast(lhs), cst2ast(rhs));

AExpr cst2ast((Expr)`<Expr lhs> \>= <Expr rhs>`)
  = geq(cst2ast(lhs), cst2ast(rhs));

AExpr cst2ast((Expr)`<Expr lhs> \<= <Expr rhs>`)
  = leq(cst2ast(lhs), cst2ast(rhs));

AExpr cst2ast((Expr)`<Expr lhs> == <Expr rhs>`)
  = eq(cst2ast(lhs), cst2ast(rhs));

AExpr cst2ast((Expr)`<Expr lhs> != <Expr rhs>`)
  = neq(cst2ast(lhs), cst2ast(rhs));

AExpr cst2ast((Expr)`<Expr lhs> && <Expr rhs>`)
  = and(cst2ast(lhs), cst2ast(rhs));
 	
AExpr cst2ast((Expr)`<Expr lhs> || <Expr rhs>`)
  = or(cst2ast(lhs), cst2ast(rhs));
  
AType cst2ast((Type)`<Str s>`)
  = typeOf("<s>");