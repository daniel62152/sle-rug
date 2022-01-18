module Check


import AST;
import Resolve;
import Message; // see standard library
import IO;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  RefGraph rg = resolve(f);
  TEnv collection = {<i.src, name, phrase, getType(typeName)> |/AQuestion q:= f, /normalQ(str phrase, AId i, AType typeName) := q, id(str name) := i}
  + {<i.src, name, phrase, getType(typeName)>| /AQuestion q := f, /computedQ(str phrase, AId i, AType typeName, _) := q, id(str name) := i};
  
  set[Message] msgs = check(f, collection,rg.useDef);
  return collection; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  for(/AQuestion q:= f) {
	  temp = check(q, tenv, useDef);
	  msgs += temp;
  };
  
  return msgs; 
}

//Prerequisites:
// Check 1 - produce an error if there are declared questions with the same name but different types.
// Check 2 - duplicate labels should trigger a warning 
// Check 3 - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (q) {
    case normalQ(str phrase, AId i, AType t):{
    	//---Check 1, 2
    	msgs += checkQuestionsDifferentTypes(i, t, phrase, tenv, useDef,q.src);
    }

    case computedQ(str phrase, AId i, AType t, AExpr expr):{
    	//---Check 1, 2
    	msgs += checkQuestionsDifferentTypes(i, t, phrase, tenv, useDef,q.src);
    	//---Check 3
    	msgs += checkQuestionsExpressionTypes(t, tenv, useDef);
    	msgs += check(expr, tenv, useDef);
    }
  }
   return msgs;
}


//---Check 3
set[Message] checkQuestionsExpressionTypes(AType t, TEnv tenv, UseDef useDef){
	set[Message] msgs = {};
	println(useDef<1>);
	for (<loc src, loc def> <- useDef) {
		for (<loc d, _ ,_ , Type ty> <- tenv) {
	    	//Check 3
		    if(def == d){
		        if(getType(t) != ty){
		        	msgs += { error("The declared type does not match the type of the expression.", src)};
		        }
			}
		}
	}
	
	return msgs;
}

//---Check 1, 2
set[Message] checkQuestionsDifferentTypes(AId i, AType t, str phrase, TEnv tenv, UseDef useDef, loc phraseLoc) {
  set[Message] msgs = {};
  
	    for (<loc d, str qname ,str label, Type ty> <- tenv) {
		    if(id(str name):=i){
		    	
		    	//Check 1
			    if((name == qname) && (d != i.src)){
			        if(getType(t) != ty){
			        	msgs += { error("Declared question with the same name and different types.", i.src)};	
			        }
				}
				
				//Check 2
				if((label == phrase) && (d != i.src)){
					msgs += { warning("There is a duplicate of this label.", phraseLoc)};
				}
	    	}
	    	
		}
  return msgs; 
}




// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case not(ref(AId x)):{
	    if(not(exp) := e){
	    	if(typeOf(exp, tenv, useDef) != tbool()){
		      msgs += { error("Error, expression must be a boolean!", x.src) | useDef[x.src] == {} };
		    }
	    }  
    }
    case mul(AExpr expr1, AExpr expr2):{
    	if(not(exp) := e){
	    	if(typeOf(exp1, tenv, useDef) == tint() && typeOf(exp2, tenv, useDef) == tint()){
		      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
		    }
	    }  
    }
    // etc.
  }
  
  return msgs; 
}

//Returns the type of an expression
Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        return t;
      }
    // etc.
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 //Getting the type of an AType
 Type getType(AType e) {
  switch (e) {
    case typeof(str string):  
      if (string == "boolean") {
       return tbool();
      } else if (string == "integer"){
      return tint();
      } else {
      return tstr();
      }
  }
  return tunknown(); 
}
 
 

