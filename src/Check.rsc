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
// Check 4 - See that if conditions contain a boolean type
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (q) {
	case ifCond(AExpr cond, _):{
	//--- Check 4
		msgs += checkIfBooleans(cond, cond.src, tenv, useDef);
	}
	//--- Check 4
	case ifElseCond(AExpr cond,_, _):{
		msgs += checkIfBooleans(cond, cond.src, tenv, useDef);
	}
    case normalQ(str phrase, AId i, AType t):{
    	//---Check 1, 2
    	msgs += checkQuestionsDifferentTypes(i, t, phrase, tenv, useDef,q.src);
    }

    case computedQ(str phrase, AId i, AType t, AExpr expr):{
    	//---Check 1, 2
    	msgs += checkQuestionsDifferentTypes(i, t, phrase, tenv, useDef,q.src);
    	//---Check 3
    	msgs += checkQuestionsExpressionTypes(q, tenv, useDef);
    	msgs += check(expr, tenv, useDef, q);
    }
  }
   return msgs;
}

//--- Check 4
set[Message] checkIfBooleans(AExpr e, loc use, TEnv tenv, UseDef useDef){
	set[Message] msgs = {};
	if (<use, loc d> <- useDef, <d, _, _, Type t> <- tenv){
	        if(t != tbool()){
	        	msgs += { error("The declared type has to be a boolean!", use)};
	        }
		}
		
	switch (e) {
	    case ref(AId x):{
	      msgs += { error("Undeclared boolean!", x.src) | useDef[x.src] == {} };
	    }
	}
	return msgs;
}

//---Check 3
set[Message] checkQuestionsExpressionTypes(AQuestion q, TEnv tenv, UseDef useDef){
	set[Message] msgs = {};
	//Getting a list of all the individual expression id's with 
	rel[Type typeName, str name, loc use] expressions = {<getType(typeName), name, i.src> | computedQ(_, _, AType typeName, /AExpr expr) := q, ref(/AId i) := expr, id(str name) := i};
	for (<Type typeName, str name, loc use><-expressions) {
		if (<use, loc d> <- useDef, <d, _, _, Type t> <- tenv){
	        if(t != typeName){
	        	msgs += { error("The declared type does not match the type of the expression.", use)};
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
set[Message] check(AExpr e, TEnv tenv, UseDef useDef, AQuestion q) {
  set[Message] msgs = {};
  rel[Type typeName, str name, loc use] expressions = {<getType(typeName), name, i.src> | computedQ(_, _, AType typeName, /AExpr expr) := q, ref(/AId i) := expr, id(str name) := i};
  
 
	  switch (e) {
	    case ref(AId x):{
	      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	    }
	    case not(_):{
		    msgs += checkBoolError(expressions, useDef, tenv);
	    }
	    case add(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case sub(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case mul(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case div(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case gt(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case lt(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case geq(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case leq(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case eq(_,_):{
		    msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case neq(_,_):{
		   msgs += checkIntError(expressions, useDef, tenv);
	    }
	    case and(_,_):{
		    msgs += checkBoolError(expressions, useDef, tenv);
	    }
	    case or(_,_):{
		    msgs += checkBoolError(expressions, useDef, tenv);
	    }
	    
	    
	  }
  
  
  return msgs; 
}

//Used for printing errors for expression types and their operation
set[Message] checkBoolError(rel[Type typeName, str name, loc use] expressions, UseDef useDef, TEnv tenv){
	set[Message] msgs = {};
	
	for (<_,_, loc use><-expressions) {
    	if (<use, loc d> <- useDef, <d, _, _, Type t> <- tenv){
    		if(t != tbool()) msgs += { error("Error, expression must be an boolean!", use) };
    	}
	}
	
	return msgs;
}

set[Message] checkIntError(rel[Type typeName, str name, loc use] expressions, UseDef useDef, TEnv tenv){
	set[Message] msgs = {};
	
	for (<_,_, loc use><-expressions) {
    	if (<use, loc d> <- useDef, <d, _, _, Type t> <- tenv){
    		if(t != tint()) msgs += { error("Error, expression must be an integer!", use) };
    	}
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
 
 

