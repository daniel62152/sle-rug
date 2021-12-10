module CST2AST

import Syntax;
import AST;

import ParseTree;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  switch (f) {
  	case (Form)`form <Id f> {<Question* qs>}`: return form(id("<f>", src=f@\loc), [ cst2ast(q) | Question q <- qs ], src=f@\loc);
  	default: throw "Error in form";
  }
}

AQuestion cst2ast(Question q) {
  switch (q) {
    case quest:(Question)`if (<Expr e>) {<Question* qs>}`: return ifCond(cst2ast(e), [ cst2ast(q) | Question q <- qs ], src=quest@\loc);
    case quest:(Question)`if (<Expr e>) {<Question* qs1>} else {<Question* qs2>}`: return ifElseCond(cst2ast(e), [ cst2ast(q) | Question q <- qs1 ], [ cst2ast(q) | Question q <- qs2 ], src=quest@\loc);
    case quest:(Question)`"<Str s>" <Id f>: <Type t>`: return normalQ("<s>", id("<f>", src=f@\loc), typeof("<t>", src=t@\loc), src=quest@\loc);
    case quest:(Question)`"<Str s>" <Id f>: <Type t> = <Expr e>`:return computedQ("<s>", id("<f>", src=f@\loc), typeof("<t>", src=t@\loc), cst2ast(e), src=quest@\loc);
    default: throw "Error in question";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case exp:(Expr)`<Id x>`: return ref(id("<x>", src=x@\loc), src=exp@\loc);
    case exp:(Expr)`<Str x>`: return var("<x>", src=exp@\loc);
    case exp:(Expr)`<Int x>`: return var("<x>", src=exp@\loc);
    case exp:(Expr)`<Bool x>`: return var("<x>", src=exp@\loc);
    case exp:(Expr)`(<Expr e>)`: return cst2ast(e);
    case exp:(Expr)`!<Expr e>`: return not(cst2ast(e), src=exp@\loc);
    case exp:(Expr)`<Expr expr1> * <Expr expr2>`: return mul(cst2ast(expr1), cst2ast(expr2), src=exp@\loc);
    case exp:(Expr)`<Expr expr1> / <Expr expr2>`: return div(cst2ast(expr1), cst2ast(expr2), src=exp@\loc);
    case exp:(Expr)`<Expr expr1> + <Expr expr2>`: return add(cst2ast(expr1), cst2ast(expr2), src=exp@\loc);
    case exp:(Expr)`<Expr expr1> - <Expr expr2>`: return sub(cst2ast(expr1), cst2ast(expr2), src=exp@\loc);
    case exp:(Expr)`<Expr lhs> \> <Expr rhs>`: return gt(cst2ast(lhs), cst2ast(rhs), src=exp@\loc);
    case exp:(Expr)`<Expr lhs> \< <Expr rhs>`: return lt(cst2ast(lhs), cst2ast(rhs), src=exp@\loc);
    case exp:(Expr)`<Expr lhs> \>= <Expr rhs>`: return geq(cst2ast(lhs), cst2ast(rhs), src=exp@\loc);
    case exp:(Expr)`<Expr lhs> \<= <Expr rhs>`: return leq(cst2ast(lhs), cst2ast(rhs), src=exp@\loc);
    case exp:(Expr)`<Expr lhs> == <Expr rhs>`: return eq(cst2ast(lhs), cst2ast(rhs), src=exp@\loc);
    case exp:(Expr)`<Expr lhs> != <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=exp@\loc);
    case exp:(Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=exp@\loc);
    case exp:(Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=exp@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch (t) {
  	case (Type)`<Str s>`: return typeof("<s>", src=s@\loc);
  	default: throw "Error in type";
  }
}
