module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
	list[AQuestion] temp = [];
	list[AQuestion] newQuestions = [];
	
	AExpr initial = boolVal(true);
	
	for(q <- f.questions) {
	  temp = transformQuestions(q, initial, false);
	  newQuestions = newQuestions + temp;
  	};
  	
  	f.questions = newQuestions;
  	
 	return f; 
}

//Uses recursion to flatten the list in the structure requested above
//But the list of conditions for each question of structure
list[AQuestion] transformQuestions(AQuestion q, AExpr expr, bool elseStatement) {
	list[AQuestion] temp = [];
	
	switch (q) {
	case ifCond(AExpr cond, list[AQuestion] then):{
		AExpr newE;
		if(elseStatement){
		newE = and(not(expr),cond);
		} else {
		newE = and(expr,cond);
		}
		for(AQuestion newQ <- then){
			temp += transformQuestions(newQ, newE, false);
		};
		return temp;
		
	}

	case ifElseCond(AExpr cond,list[AQuestion] ifTrue, list[AQuestion] ifFalse):{
		AExpr newE;
		if(elseStatement){
		newE = and(not(expr),cond);
		} else {
		newE = and(expr,cond);
		}
		
		for(AQuestion newQ <- ifTrue){
			temp += transformQuestions(newQ, newE, false);
		};
		
		for(AQuestion newQ <- ifFalse){
			temp += transformQuestions(newQ, newE, true);
		};
		
		return temp;
	}
	
	case normalQ(_ ,_ ,_ ):{
		temp += [q];
		AQuestion newQ = ifCond(expr, temp);
		return [newQ];
    }

    case computedQ(_, _, _, _):{
    	temp += [q];
    	AQuestion newQ = ifCond(expr, temp);
    	return [newQ];
    }
    
	
  }
  
  return temp;
  	 
}



/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
 } 


 start[Form] rename(start[Form] f, loc useOrDef, str newName) {
   RefGraph rg = resolve(cst2ast(f));
   
   set[loc] toRename = {};
   
   if(useOrDef in rg.defs<1>) {
	   //Definitions
	   toRename += {useOrDef};
	   toRename += { use | <loc use,useOrDef> <-rg.useDef};
   }
   else if (useOrDef in rg.uses<0>) {
	   if(<useOrDef, loc def> <- rg.useDef){
	   	toRename += {use | <loc use, def> <- rg.useDef};
	   }
   } else {
   	return f;
   }
   
   return visit(f){
   	case Id x => [Id]newName
   		when x@\loc in toRename
   };
 } 
 

