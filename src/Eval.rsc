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
        if(typeof(str tName) := typeName) {
          if(id(str name) := i) {
            setDefaultValue(tName, name, initial);
          }
        }
      }
      case computedQ(_, AId i, AType typeName, _): {
        if(typeof(str tName) := typeName) {
          if(id(str name) := i) {
            setDefaultValue(tName, name, initial);
          }
        }
      }
    }
  }
  return initial;
}

void setDefaultValue(str tName, str name, VEnv init) {
  switch (tName) {
    case "integer": init[name] = vint(0);
    case "string": init[name] = vstr("");
    case "boolean": init[name] = vbool(false);
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
  VEnv env = ();
  for(/AQuestion q:= f) {
    env += eval(q, inp, venv);
  }
  return env; 
}


VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  VEnv env = venv;
  switch (q) {
    case ifCond(AExpr cond, list[AQuestion] then): {
      if (eval(cond, env).b) {
        for (qs <- then) {
          env = eval(qs, inp, env);
        }
      }
    }
    case ifElseCond(AExpr cond, list[AQuestion] ifTrue, list[AQuestion] ifFalse): {
      if (eval(cond, env).b) {
        for (qs <- ifTrue) {
          env = eval(qs, inp, env);
        }
      } else {
        for (qs <- ifFalse) {
          env = eval(qs, inp, env);
        }
      }
    }
    case computedQ(_, AId name, _, AExpr expr): {
      if (eval(expr, env).b) {
        env[name.name] = eval(expr,env);
      }
    }
  }
  return env;
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