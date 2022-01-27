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
		//msgs += checkIfBooleans(cond, cond.src, tenv, useDef);
		AType t = typeof("boolean");
		msgs += check(cond, tenv, useDef,t);
	}
	//--- Check 4
	case ifElseCond(AExpr cond,_, _):{
		//msgs += checkIfBooleans(cond, cond.src, tenv, useDef);
		AType t = typeof("boolean");
		msgs += check(cond, tenv, useDef,t);
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
    	msgs += check(expr, tenv, useDef, t);
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
			        } else {
			        	if(phrase != label)msgs += { warning("Duplicate question, however label is different!", phraseLoc)};
			        }
				}
				
				//Check 2
				if((label == phrase) && (d != i.src) && name != qname){
					msgs += { warning("There is a duplicate of this label.", phraseLoc)};
				}
	    	}
	    	
		}
  return msgs; 
}



// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef, AType t) {
  set[Message] msgs = {};
  Type newType = getType(t);
  
  switch(newType){
  case tbool():{msgs += checkBoolExpressions(e, tenv, useDef, e.src);
  }
  case tint():{
  	msgs += checkIntExpressions(e, tenv, useDef, e.src);
  }
  };
  
  return msgs; 
}


set[Message] checkIntExpressions(AExpr e, TEnv tenv, UseDef useDef, loc use) {
  set[Message] msgs = {};
  
  switch (e) {
	    case ref(AId x):{
	      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	      	if (<use, loc d> <- useDef, <d, _, _, Type t> <- tenv){
    			if(t != tint()) msgs += { error("Error, expression must be of type integer!", use) };
    		}
	    }
	    case intVal(_):{
	      return msgs;
	    }
	    case add(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case sub(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case mul(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case div(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    default: msgs = { error("Error, operation is not valid for type integer!", e.src)};
	  }
  
  return msgs; 
}


set[Message] checkBoolExpressions(AExpr e, TEnv tenv, UseDef useDef, loc use) {
  set[Message] msgs = {};
  
  switch (e) {
	    case ref(AId x):{
	      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	      	if (<use, loc d> <- useDef, <d, _, _, Type t> <- tenv){
    			if(t != tbool()) msgs += { error("Error, expression must be of type Boolean!", use) };
    		}
	    }
	    case boolVal(_):{
	      return msgs;
	    }
	    case not(AExpr arg):{
		    msgs += checkIntExpressions(arg, tenv, useDef, arg.src);
	    }
	    case and(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case or(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case gt(_,_):{
		    msgs += checkBoolExpressionWithInt(e, tenv, useDef, e.src);
	    }
	    case lt(_,_):{
		    msgs += checkBoolExpressionWithInt(e, tenv, useDef, e.src);
	    }
	    case geq(_,_):{
		    msgs += checkBoolExpressionWithInt(e, tenv, useDef, e.src);
	    }
	    case leq(_,_):{
		    msgs += checkBoolExpressionWithInt(e, tenv, useDef, e.src);
	    }
	    case eq(_,_):{
		    msgs += checkBoolExpressionWithInt(e, tenv, useDef, e.src);
	    }
	    case neq(_,_):{
		   msgs += checkBoolExpressionWithInt(e, tenv, useDef, e.src);
	    }
	    default: msgs = { error("Error, operation this is not a boolean expression!", e.src)};
	  }
  
  return msgs; 
}


set[Message] checkBoolExpressionWithInt(AExpr e, TEnv tenv, UseDef useDef, loc use) {
  set[Message] msgs = {};
  switch (e) {
	    case ref(AId x):{
	      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	      	if (<use, loc d> <- useDef, <d, _, _, Type t> <- tenv){
    			if(t != tint()) msgs += { error("Error, expression must be of type Integer for the use of a comparison operator!", use) };
    		}
	    }
	    case intVal(_):{
	      return msgs;
	    }
	    case gt(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case lt(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case geq(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case leq(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case eq(AExpr expr1, AExpr expr2):{
		    msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		    msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    case neq(AExpr expr1, AExpr expr2):{
		   msgs += checkIntExpressions(expr1, tenv, useDef, expr1.src);
		   msgs += checkIntExpressions(expr2, tenv, useDef, expr1.src);
	    }
	    default: msgs = { error("Error, operation is not valid when using comparison operators!", e.src)};
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
 
 

