module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import String;

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
         '\<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '\<div\>
         '  \<input
         '    type=\"checkbox\"
         '    id=\"input<q.name.name>\"
         '    name=\"<q.name.name>\"
         '    onclick=\"execute()\"
         '  \>
         '\</div\>
         '<}>
         '<if (q.typeName.typeName == "integer") {>
         '\<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '\<div\>
         '  \<input
         '    type=\"number\"
         '    id=\"input<q.name.name>\"
         '    name=\"<q.name.name>\"
         '    onchange=\"execute()\"
         '  \>
         '\</div\>
         '\<br /\>\<br /\>
         '<}>
         <if (q.typeName.typeName == "string") {>
         '\<p id=\"<q.phrase>\"\><q.phrase>\</p\>
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
         '<if (q is computedQ) {>
         '<}>
         '<if (q is ifCond) {>
         ' <ifCond2div(q.then, q.cond)>
         '<}>
         '<if (q is ifElseCond) {>
         ' <ifCond2div(q.ifTrue, q.cond)>
         ' <elseCond2div(q.ifFalse, q.cond)>
         '<}>
         '<}>
         ";
}

str elseCond2div(list[AQuestion] questions, AExpr cond) {
  return "<for (AQuestion q <- questions) {>
  		 '  <if (q is normalQ) {>
  		 '  <if (q.typeName.typeName == "integer") {>
  		 '  \<div id=\"<q.name.name>\" style=\"display: block\"\>
  		 '    \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '    \<input
         '      type=\"number\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"execute()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
  		   '<}>
  		 '  <if (q.typeName.typeName == "string") {>
         '  \<div id=\"<q.name.name>\" style=\"display: block\"\>
         '    \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '    \<input
         '      type=\"text\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"execute()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
         '  <}>
         '  <if (q.typeName.typeName == "boolean") {>
         '  \<div id=\"<q.name.name>\" style=\"display: block\"\>
         '    \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '    \<div\>
         '      \<input
         '        type=\"checkbox\"
         '        id=\"input<q.name.name>\"
         '        name=\"<q.name.name>\"
         '        onclick=\"execute()\"
         '      \>
         '    \</div\>
         '  \</div\>
         '  <}>
         '  <}>
         '  <if (q is computedQ) {>
         '  \<div id=\"<q.name.name>\" style=\"display: block\"\>
         '    \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '    \<input
         '      type=\"text\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"execute()\"
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
         '    <elseCond2div(q.ifFalse, q.cond)>
         '  <}>
         '<}>
  		 ";
}

str ifCond2div(list[AQuestion] questions, AExpr cond) {
  return "<for (AQuestion q <- questions) {>
  		 '  <if (q is normalQ) {>
  		 '  <if (q.typeName.typeName == "integer") {>
  		 '  \<div id=\"div<q.name.name>\" style=\"display: none\"\>
  		 '    \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '    \<input
         '      type=\"number\"
         '      id=\"input<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"execute()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
  		   '<}>
  		 '  <if (q.typeName.typeName == "string") {>
         '  \<div id=\"div<q.name.name>\" style=\"display: none\"\>
         '    \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
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
         '    \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '    \<div\>
         '      \<input
         '        type=\"checkbox\"
         '        id=\"input<q.name.name>\"
         '        name=\"<q.name.name>\"
         '        onclick=\"execute()\"
         '      \>
         '      \<label for=\"yes<q.name.name>\"\>Yes\</label\>
         '    \</div\>
         '  \</div\>
         '  <}>
         '  <}>
         '  <if (q is computedQ) {>
         '  \<div id=\"div<q.name.name>\" style=\"display: none\"\>
         '    \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
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
         '    <elseCond2div(q.ifFalse, q.cond)>
         '  <}>
         '<}>
  		 ";
}

str form2js(AForm f) {
  map[str, str] store = ();
  return "function execute() {
         '<for (AQuestion q <- f.questions) {>
         '  <if (q is normalQ || q is computedQ) { store += (q.name.name: q.typeName.typeName);>
         '  <}>
         '  <if (q is ifCond) {>
         '    <ifCond2js(q.then, q.cond, store)>
         '  <}>
         '<}>
         '}
         ";
}

str computedQ2js() {
  return "
         '
         ";
}

str ifCond2js(list[AQuestion] questions, AExpr cond, map[str, str] store) {
    list[str] store2 = [];
    return "<for (AQuestion q <- questions) { store2 += q.name.name; >
           '  const <q.name.name> = document.getElementById(\"div<q.name.name>\");
    	   '<}>
    	   '<if (getCond(cond) in store){>
    	   '<if (store[getCond(cond)] == "boolean"){>
    	   '  if (<getExpression(cond, true)>.checked) {
    	   '  <for (id <- store2) { >
    	   '    <id>.style.display = \"block\";
    	   '  <}>    
    	   '  } else {
    	   '  <for (id <- store2) { >
    	   '    <id>.style.display = \"none\";
    	   '  <}>
    	   '  }
    	   '<}>
    	   '<} else {>
    	   '  if (<getExpression(cond, false)>) {
    	   '  <for (id <- store2) { >
    	   '    <id>.style.display = \"block\";
    	   '  <}>    
    	   '  } else {
    	   '  <for (id <- store2) { >
    	   '    <id>.style.display = \"none\";
    	   '  <}>
    	   '  }
    	   '<}>
    	   '
    	   
    	   '<for (AQuestion q <- questions) {>
    	   '<if (q is computedQ) {>
           '  document.getElementById(\"input<q.name.name>\").value=<getExpression(q.expr, false)>
    	   '<}>
    	   '<}>
    	   
    	   ";
}

str getExpression(AExpr expr, bool boolean) {
    str store = "";
    switch (expr) {
        case ref(AId id):{ 
          if (boolean) {
            store += "(document.getElementById(\"input<id.name>\"))";
          } else {
            store += "(document.getElementById(\"input<id.name>\").value)";
          }
        }
        case strVal(str string): store += "<string>";
        case intVal(int val): store += "<val>";
        case boolVal(bool boolean): store += "<boolean>";
        case not(AExpr arg): store += "!<getExpression(arg)>";
        case mul(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1, boolean)>*<getExpression(expr2, boolean)>)";
        case div(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1, boolean)>/<getExpression(expr2, boolean)>)";
        case add(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1, boolean)>+<getExpression(expr2, boolean)>)";
        case sub(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1, boolean)>-<getExpression(expr2, boolean)>)";
        case gt(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, boolean)>\><getExpression(rhs, boolean)>)";
        case lt(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, boolean)>\<<getExpression(rhs, boolean)>)";
        case geq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, boolean)>\>=<getExpression(rhs, boolean)>)";  
        case leq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, boolean)>\<=<getExpression(rhs, boolean)>)";
        case eq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, boolean)>==<getExpression(rhs, boolean)>)";
        case neq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, boolean)>!=<getExpression(rhs, boolean)>)";
        case and(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, boolean)>&&<getExpression(rhs, boolean)>)";
        case or(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs, boolean)>||<getExpression(rhs, boolean)>)";
    }
    return store;
}

str getCond(AExpr expr) {
    str store = "";
    switch (expr) {
        case ref(AId id): store += "<id.name>";
        case strVal(str string): store += "<string>";
        case intVal(int val): store += "<val>";
        case boolVal(bool boolean): store += "<boolean>";
        case not(AExpr arg): store += "!<getCond(arg)>";
        case mul(AExpr expr1, AExpr expr2): store += "(<getCond(expr1)>*<getCond(expr2)>)";
        case div(AExpr expr1, AExpr expr2): store += "(<getCond(expr1)>/<getCond(expr2)>)";
        case add(AExpr expr1, AExpr expr2): store += "(<getCond(expr1)>+<getCond(expr2)>)";
        case sub(AExpr expr1, AExpr expr2): store += "(<getCond(expr1)>-<getCond(expr2)>)";
        case gt(AExpr lhs, AExpr rhs): store += "(<getCond(lhs)>\><getCond(rhs)>)";
        case lt(AExpr lhs, AExpr rhs): store += "(<getCond(lhs)>\<<getCond(rhs)>)";
        case geq(AExpr lhs, AExpr rhs): store += "(<getCond(lhs)>\>=<getCond(rhs)>)";  
        case leq(AExpr lhs, AExpr rhs): store += "(<getCond(lhs)>\<=<getCond(rhs)>)";
        case eq(AExpr lhs, AExpr rhs): store += "(<getCond(lhs)>==<getCond(rhs)>)";
        case neq(AExpr lhs, AExpr rhs): store += "(<getCond(lhs)>!=<getCond(rhs)>)";
        case and(AExpr lhs, AExpr rhs): store += "(<getCond(lhs)>&&<getCond(rhs)>)";
        case or(AExpr lhs, AExpr rhs): store += "(<getCond(lhs)>||<getCond(rhs)>)";     
    }
   
    return store;
}


