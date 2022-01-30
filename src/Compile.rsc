module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import String;
import List;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, form2html(f));
}

str form2html(AForm f) {
  str fileLoc = "<f.src[extension="js"].top>"[23..-1];
  return "\<!DOCTYPE html\>
         '\<html\>
         '  \<head\>
         '    \<title\><f.name.name>\</title\>
         '  \</head\>
         '  \<body\>
         '  \<h1\><f.name.name>\</h1\>
         '  <questions2div(f.questions)>
         '  \</body\>
         '  \<script type=\"text/javascript\" src=\"<fileLoc>\"\>\</script\>
         '\</html\>
         ";
}

str questions2div(list[AQuestion] questions) {
  return "<for (AQuestion q <- questions) {>
         '<if (q is normalQ) {>
         '<if (q.typeName.typeName == "boolean") {>
         '\<p id=\'<q.phrase>\'\><q.phrase>\</p\>
         '
         '\<div\>
         '  \<input
         '    type=\"checkbox\"
         '    id=\"input<q.name.name>\"
         '    name=\"<q.name.name>\"
         '    value=\"false\"
         '    onclick=\"onCheck(\'input<q.name.name>\')\"
         '  \>
         '\</div\>
         '<}>
         '<if (q.typeName.typeName == "integer") {>
         '\<p id=\'<q.phrase>\'\><q.phrase>\</p\>
         '
         '\<div\>
         '  \<input
         '    type=\"number\"
         '    id=\"input<q.name.name>\"
         '    name=\"<q.name.name>\"
         '    value=\"0\"
         '    onchange=\"execute()\"
         '  \>
         '\</div\>
         '\<br /\>\<br /\>
         '<}>
         <if (q.typeName.typeName == "string") {>
         '\<p id=\'<q.phrase>\'\><q.phrase>\</p\>
         '
         '\<div\>
         '  \<input
         '    type=\"text\"
         '    id=\"input<q.name.name>\"
         '    name=\"<q.name.name>\"
         '    onchange=\"execute()\"
         '  \>
         '\</div\>
         '\<br /\>\<br /\>
         '<}>
         '<}>
         '<if (q is ifCond) {>
         ' <ifCond2div(q.then, q.cond)>
         '<}>
         '<if (q is ifElseCond) {>
         ' <ifCond2div(q.ifTrue, q.cond)>
         ' <ifCond2div(q.ifFalse, q.cond)>
         '<}>
         '<}>
         ";
}

str ifCond2div(list[AQuestion] questions, AExpr cond) {
  return "<for (AQuestion q <- questions) {>
  		 '  <if (q is normalQ) {>
  		 '  <if (q.typeName.typeName == "integer") {>
  		 '  \<div id=\"div<q.name.name>\" style=\"display: none\"\>
  		 '    \<p id=\'<q.phrase>\'\><q.phrase>\</p\>
         '    \<input
         '      type=\"number\"
         '      id=\"input<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      value=\"0\"
         '      onchange=\"execute()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
  		   '<}>
  		 '  <if (q.typeName.typeName == "string") {>
         '  \<div id=\"div<q.name.name>\" style=\"display: none\"\>
         '    \<p id=\'<q.phrase>\'\><q.phrase>\</p\>
         '    \<input
         '      type=\"text\"
         '      id=\"input<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"execute()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
         '  <}>
         '  <if (q.typeName.typeName == "boolean") {>
         '  \<div id=\"div<q.name.name>\" style=\"display: none\"\>
         '    \<p id=\'<q.phrase>\'\><q.phrase>\</p\>
         '      \<input
         '        type=\"checkbox\"
         '        id=\"input<q.name.name>\"
         '        name=\"<q.name.name>\"
         '        value=\"false\"
         '        onclick=\"onCheck(\'input<q.name.name>\')\"
         '      \>
         '  \</div\>
         '  <}>
         '  <}>
         '  <if (q is computedQ) {>
         '  \<div id=\"div<q.name.name>\" style=\"display: none\"\>
         '    \<p id=\'<q.phrase>\'\><q.phrase>\</p\>
         '    \<input
         '      type=\"text\"
         '      id=\"input<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      disabled
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
         '  <}>
         '  <if (q is ifCond) {>
         '    <ifCond2div(q.then, q.cond)>
         '  <}>
         '  <if (q is ifElseCond) {>
         '    <ifCond2div(q.ifTrue, q.cond)>
         '    <ifCond2div(q.ifFalse, q.cond)>
         '  <}>
         '<}>
  		 ";
}

str form2js(AForm f) {
  return "document.addEventListener(\'DOMContentLoaded\', function() {
  		 '  execute();
  		 '});
  		 '
  		 'function onCheck(input) {
  	     '  const checkbox = document.getElementById(input);
  	     '  if (checkbox.value == \"false\") {
  	     '    checkbox.value = \"true\";
  	     '  } else {
  	     '    checkbox.value = \"false\";
  	     '  }
  	     '  execute();
  	     '}
  	     '
  		 'function isTrue(input) {
  	     '  if (String(input).toLowerCase() == \"true\") {
  	     '    return true;
  	     '  } else {
  	     '    return false;
  	     '  }
  	     '}
  	     '
  	     'function showDiv(id) {
  	     '  document.getElementById(\"div\"+id).style.display = \'block\';
  	     '}
  	     'function hideDiv(id) {
  	     '  document.getElementById(\"div\"+id).style.display = \'none\';
  	     '}    
  		 'function execute() {
         '<for (AQuestion q <- f.questions) {>
         '<execute(q)>
         '<}>
         '}
         ";
}

str execute(AQuestion q) {
  set[str] storeIfCond = {};
  set[str] storeElseCond = {};
  return "<if (q is ifCond || q is ifElseCond) {>
         '  <if (q is ifCond) {>
         '    <for (question <- q.then) {storeIfCond += getNestedStatements(question, storeIfCond);>
         '    <}>
         '  <}>
         '  <if (q is ifElseCond) {>
         '    <for (question <- q.ifTrue) {storeIfCond += getNestedStatements(question, storeIfCond);>
         '    <}>
         '    <for (question <- q.ifFalse) {storeElseCond += getNestedStatements(question, storeElseCond);>
         '    <}>
         '  <}>
         '	<if (q is ifCond) { >
         '	<ifCond2js(storeIfCond, q)>
         '	<}>
         '	<if (q is ifElseCond) {>
         '	<ifElseCond2js(storeIfCond, storeElseCond, q)>
         '	<}>
         '  
         '<}>
         '<if (q is computedQ) {>
  		 'document.getElementById(\"input<q.name.name>\").value=<getExpression(q.expr, true)>
         '<}>  
  		 '
  	     ";
}

set[str] getNestedStatements(AQuestion q, set[str] store) {
  if (q is ifCond) { 
	for (q2 <- q.then) {
	  store += getNestedStatements(q2, store);
	}
  }
  if (q is ifElseCond) { 
	for (q2 <- q.ifTrue) {
	  store += getNestedStatements(q2, store);
	}
	for (q2 <- q.ifFalse) {
	  store += getNestedStatements(q2, store);
	}
  }
  if (q is normalQ || q is computedQ) { 
	store += q.name.name;
  }
  return store;
}

str ifCond2js(set[str] storeIfCond, AQuestion question) {
  return "  if (isTrue(<getExpression(question.cond, true)>)) {
    	 '    <for (id <- storeIfCond) { >
    	 '      showDiv(\"<id>\");
    	 '    <}>
    	 '	<for (q <- question.then) {>
    	 '	<execute(q)>
    	 '	<}>
    	 '  } else if (!isTrue(<getExpression(question.cond, true)>)) {
    	 '    <for (id <- storeIfCond) { >
    	 '      hideDiv(\"<id>\");
    	 '    <}>
    	 '  }
    	 ";
}

str ifElseCond2js(set[str] storeIfCond, set[str] storeElseCond, AQuestion question) {
  return "  if (isTrue(<getExpression(question.cond, true)>)) {
    	 '    <for (id <- storeIfCond) { >
    	 '	  showDiv(\"<id>\");
    	 '    <}>
    	 '	<for (id <- storeElseCond) { >
		 '	  hideDiv(\"<id>\");
    	 '    <}>
    	 '	<for (q <- question.ifTrue) {>
    	 '	<execute(q)>
    	 '	<}>
    	 '  } else {
    	 '    <for (id <- storeElseCond) { >
    	 '      showDiv(\"<id>\");
    	 '    <}>
    	 '	<for (id <- storeIfCond) { >
    	 '      hideDiv(\"<id>\");
    	 '    <}>
    	 '	<for (q <- question.ifFalse) {>
    	 '	<execute(q)>
    	 '	<}>
    	 '  }
    	 ";
}

str getExpression(AExpr expr, bool withValue) {
  str store = "";
  switch (expr) {
    case ref(AId id):{ 
      if (withValue) {
        store += "(document.getElementById(\"input<id.name>\")).value";
      } else {
        store += "(document.getElementById(\"input<id.name>\"))";
      }
    }
    case strVal(str string): store += "<string>";
    case intVal(int val): store += "<val>";
    case boolVal(bool boolean): store += "<boolean>";
    case not(AExpr arg): store += "!<getExpression(arg, withValue)>";
    case mul(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1, withValue)>*<getExpression(expr2, withValue)>)";
    case div(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1, withValue)>/<getExpression(expr2, withValue)>)";
    case add(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1, withValue)>+<getExpression(expr2, withValue)>)";
    case sub(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1, withValue)>-<getExpression(expr2, withValue)>)";
    case gt(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, withValue)>\><getExpression(rhs, withValue)>)";
    case lt(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, withValue)>\<<getExpression(rhs, withValue)>)";
    case geq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, withValue)>\>=<getExpression(rhs, withValue)>)";  
    case leq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, withValue)>\<=<getExpression(rhs, withValue)>)";
    case eq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, withValue)>==<getExpression(rhs, withValue)>)";
    case neq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, withValue)>!=<getExpression(rhs, withValue)>)";
    case and(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, withValue)>&&<getExpression(rhs, withValue)>)";
    case or(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, withValue)>||<getExpression(rhs, withValue)>)";
  }
  return store;
}