module Resolve

import AST;

/*
 * Name resolution for QL
 */


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses,
  Def defs,
  UseDef useDef
];

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  return {<e.src, name>| /AQuestion q := f, ifCond(/AExpr cond,_) := q, /e:ref(/AId i) := cond, id(str name) := i}
  +{<e.src, name>| /AQuestion q := f, ifElseCond(/AExpr cond,_,_) := q, /e:ref(/AId i) := cond, id(str name) := i}
  +{<e.src, name> | /AQuestion q := f, computedQ(_, _, _, /AExpr expr) := q, /e:ref(/AId i) := expr, id(str name) := i}
  ;
}


Def defs(AForm f) {
  return {<string, i.src> | /AQuestion q := f, normalQ(_, /AId i, _) := q, id(str string) := i}
  + {<string, i.src> | /AQuestion q := f, computedQ(_, /AId i, _, _) := q, id(str string) := i};
}
