module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv initial = ();
  
  for(/AQuestion q:= f) {
    switch (q) {
      case normalQ(_, AId i, AType typeName): {
        initial[i.name] = setDefaultValue(typeName.typeName);
      }
      case computedQ(_, AId i, AType typeName, _): {
        initial[i.name] = setDefaultValue(typeName.typeName);
      }
    }
  }
  return initial;
}

Value setDefaultValue(str tName) {
  switch (tName) {
    case "integer": return vint(0);
    case "string": return vstr("");
    case "boolean": return vbool(false);
    default: throw "Unknown type";
  }
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(/AQuestion q <- f) {
    venv += eval(q, inp, venv);
  }
  return venv; 
}


VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch (q) {
    case normalQ(_, AId name, _): {
      if (inp.question == name.name) {
        venv[name.name] = inp.\value;
      }
    }
    case computedQ(_, AId name, _, AExpr expr): {
        venv[name.name] = eval(expr, venv);
    }
    case ifCond(AExpr cond, list[AQuestion] then): {
      if (eval(cond, venv).b) {
        for (q2 <- then) {
          venv += eval(q2, inp, venv);
        }
      }
    }
    case ifElseCond(AExpr cond, list[AQuestion] ifTrue, list[AQuestion] ifFalse): {
      if (eval(cond, venv).b) {
        for (q2 <- ifTrue) {
          venv += eval(q2, inp, venv);
        }
      } else {
        for (q2 <- ifFalse) {
          venv += eval(q2, inp, venv);
        }
      }
    }
  }
  return venv;
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case strVal(str x): return vstr(x);
    case intVal(int x): return vint(x);
    case boolVal(bool x): return vbool(x);
    case not(AExpr arg): return vbool(!eval(arg, venv).b);
    case mul(AExpr expr1, AExpr expr2): return vint(eval(expr1, venv).n * eval(expr2, venv).n);
    case div(AExpr expr1, AExpr expr2): {
      if (eval(expr2, venv).n == 0) {
        throw "It cannot be divided by 0";
      } else {
        return vint(eval(expr1, venv).n / eval(expr2, venv).n);  
      }
    }
    case add(AExpr expr1, AExpr expr2): return vint(eval(expr1, venv).n + eval(expr2, venv).n);
    case sub(AExpr expr1, AExpr expr2): return vint(eval(expr1, venv).n - eval(expr2, venv).n);
    case gt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case lt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case geq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
    case leq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    case eq(AExpr lhs, AExpr rhs): {
      if (eval(lhs, venv) has b && eval(rhs, venv) has b) {
        return vbool(eval(lhs, venv).b == eval(rhs, venv).b);
      } else {
        return vbool(eval(lhs, venv).n == eval(rhs, venv).n);
      }
    }
    case neq(AExpr lhs, AExpr rhs): {
      if (eval(lhs, venv) has b && eval(rhs, venv) has b) {
        return vbool(eval(lhs, venv).b != eval(rhs, venv).b);
      } else {
        return vbool(eval(lhs, venv).n != eval(rhs, venv).n);
      }
    }
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    default: throw "Unsupported expression <e>";
  }
}