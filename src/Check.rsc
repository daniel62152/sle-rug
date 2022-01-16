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
set[Message] collect(AForm f) {//TEnv collect(AForm f) {
  RefGraph rg = resolve(f);
  TEnv collection = {<i.src, name, phrase, getType(typeName)> |/AQuestion q:= f, /normalQ(str phrase, AId i, AType typeName) := q, id(str name) := i}
  + {<i.src, name, phrase, getType(typeName)>| /AQuestion q := f, /computedQ(str phrase, AId i, AType typeName, _) := q, id(str name) := i};
  
  set[Message] msgs = {};
  
  for(/AQuestion q:= f) {
	  temp = check(q, collection, rg.useDef);
	  msgs += temp;
  };
   
  return msgs; 
}

//set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
//  return {}; 
//}

//Prerequisites:
// Check 1 - produce an error if there are declared questions with the same name but different types.
// Check 2 - duplicate labels should trigger a warning 
// Check 3 - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (q) {
    case normalQ(str phrase, AId i, AType t ):{
    	//---Check 1, 2
    	msgs += checkQuestionsDifferentTypes(i, t, phrase, tenv, useDef);
    }

    case computedQ(str phrase, AId i, AType t, AExpr expr):{
    	//---Check 1, 2 and 3
    	msgs += checkQuestionsDifferentTypes(i, t, phrase, tenv, useDef);
    }
  }
   return msgs;
}

//---Check 1, 2
set[Message] checkQuestionsDifferentTypes(AId i, AType t, str phrase, TEnv tenv, UseDef useDef) {
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
				
					msgs += { warning("There is a duplicate of this label.", i.src)};
				}
	    	}
	    	
		}
  return msgs; 
}



/*
set[str] seen = {};
    for(TEnv t <- tenv, <loc def, str name, str label, Type \type> := t){
    	if((label == phrase) && (def != i.src)){
    	
    	};
    };
*/


// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
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
 
 

