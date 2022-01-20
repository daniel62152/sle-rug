module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

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
         '    type=\"radio\"
         '    id=\"yes<q.name.name>\"
         '    name=\"<q.name.name>\"
         '    value=\"yes<q.name.name>\"
         '    onclick=\"setBoolean(true, \'<q.name.name>\')\"
         '  \>
         '  \<label for=\"yes<q.name.name>\"\>Yes\</label\>
         '\</div\>
         '
         '\<div\>
         '  \<input
         '    type=\"radio\"
         '    id=\"no<q.name.name>\"
         '    name=\"<q.name.name>\"
         '    value=\"no<q.name.name>\"
         '    onclick=\"setBoolean(false, \'<q.name.name>\')\"
         '    checked
         '  \>
         '  \<label for=\"no<q.name.name>\"\>No\</label\>
         '\</div\>
         '<}>
         '<if (q.typeName.typeName == "integer") {>
         '\<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '\<div\>
         '  \<input
         '    type=\"number\"
         '    id=\"<q.name.name>\"
         '    name=\"<q.name.name>\"
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
         '    id=\"<q.name.name>\"
         '    name=\"<q.name.name>\"
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
  return "\<div id=\"else<getCond(cond)>\" class=\"else<getCond(cond)>\" style=\"display: block\"\>
  		 '<for (AQuestion q <- questions) {>
  		 '  <if (q is normalQ) {>
  		 '  <if (q.typeName.typeName == "integer") {>
  		 '  \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
  		 '  \<div\>
         '    \<input
         '      type=\"number\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"getValue()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
  		   '<}>
  		 '  <if (q.typeName.typeName == "string") {>
         '  \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '  \<div\>
         '    \<input
         '      type=\"text\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"getValue()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
         '  <}>
         '  <if (q.typeName.typeName == "boolean") {>
         '  \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '  \<div\>
         '    \<input
         '      type=\"radio\"
         '      id=\"yes<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      value=\"yes<q.name.name>\"
         '      onclick=\"setBoolean(true, \'<q.name.name>\')\"
         '    \>
         '    \<label for=\"yes<q.name.name>\"\>Yes\</label\>
         '  \</div\>
         '
         '  \<div\>
         '    \<input
         '      type=\"radio\"
         '      id=\"no<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      value=\"no<q.name.name>\"
         '      onclick=\"setBoolean(false, \'<q.name.name>\')\"
         '      checked
         '    \>
         '    \<label for=\"no<q.name.name>\"\>No\</label\>
         '  \</div\>
         '  <}>
         '  <}>
         '  <if (q is computedQ) {>
         '  \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '  \<div\>
         '    \<input
         '      type=\"text\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      disabled
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
         '  <}>
         '  <if (q is ifCond) {>
         '    <ifCond2div(q.then, q.cond)>
         '  <}>  
         '<}>
         '\</div\>
  		 ";
}

str ifCond2div(list[AQuestion] questions, AExpr cond) {
  return "\<div id=\"<getCond(cond)>\" class=\"<getCond(cond)>\" style=\"display: none\"\>
  		 '<for (AQuestion q <- questions) {>
  		 '  <if (q is normalQ) {>
  		 '  <if (q.typeName.typeName == "integer") {>
  		 '  \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
  		 '  \<div\>
         '    \<input
         '      type=\"number\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"getValue()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
  		   '<}>
  		 '  <if (q.typeName.typeName == "string") {>
         '  \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '  \<div\>
         '    \<input
         '      type=\"text\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      onchange=\"getValue()\"
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
         '  <}>
         '  <if (q.typeName.typeName == "boolean") {>
         '  \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '  \<div\>
         '    \<input
         '      type=\"radio\"
         '      id=\"yes<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      value=\"yes<q.name.name>\"
         '      onclick=\"setBoolean(true, \'<q.name.name>\')\"
         '    \>
         '    \<label for=\"yes<q.name.name>\"\>Yes\</label\>
         '  \</div\>
         '
         '  \<div\>
         '    \<input
         '      type=\"radio\"
         '      id=\"no<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      value=\"no<q.name.name>\"
         '      onclick=\"setBoolean(false, \'<q.name.name>\')\"
         '      checked
         '    \>
         '    \<label for=\"no<q.name.name>\"\>No\</label\>
         '  \</div\>
         '  <}>
         '  <}>
         '  <if (q is computedQ) {>
         '  \<p id=\"<q.phrase>\"\><q.phrase>\</p\>
         '
         '  \<div\>
         '    \<input
         '      type=\"text\"
         '      id=\"<q.name.name>\"
         '      name=\"<q.name.name>\"
         '      disabled
         '    \>
         '  \</div\>
         '  \<br /\>\<br /\>
         '  <}>
         '  <if (q is ifCond) {>
         '    <ifCond2div(q.then, q.cond)>
         '  <}>  
         '<}>
         '\</div\>
  		 ";
}

str form2js(AForm f) {
  list[str] store = [];
  return "<for (AQuestion q <- f.questions) {>
         '<if (q is normalQ) {>
         '<if (q.typeName.typeName == "boolean" && !("setBoolean" in store)) { store += "setBoolean";>
         'function setBoolean(show, id) {
         '  const x = document.getElementById(id);
         '  const y = document.getElementById(\"else\"+id);
         '  if (show) {
         '    x.style.display = \"block\";
         '    y.style.display = \"none\";
         '  } else {
         '    x.style.display = \"none\";
         '    y.style.display = \"block\";
         '  }
         '}
         '<}>
         '<}>
         '<if (q is computedQ) {>
         '<if (q.typeName.typeName == "integer" && !("getValue" in store)) { store += "getValue";>
         'function getValue() {
         '  <getExpression(q.expr)>
         '}
         '<}>
         '<}>
         '<if (q is ifCond) {>
         ' <ifCond2js(q.then, store)>
         '<}>
         '<}>
         ";
}

str ifCond2js(list[AQuestion] questions, list[str] store) {
    return "function getValue() {
    	   '<for (AQuestion q <- questions) {>
    	   '<if (q is computedQ) {>
           '  document.getElementById(\"<q.name.name>\").value=<getExpression(q.expr)>
    	   '<}>
    	   '<}>
    	   '}
    	   ";
}

str getExpression(AExpr expr) {
    str store = "";
    switch (expr) {
        case ref(AId id): store += "(document.getElementById(\"<id.name>\").value)";
        case strVal(str string): store += "<string>";
        case intVal(int val): store += "<val>";
        case boolVal(bool boolean): store += "<boolean>";
        case not(AExpr arg): store += "!<getExpression(arg)>";
        case mul(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1)>*<getExpression(expr2)>)";
        case div(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1)>/<getExpression(expr2)>)";
        case add(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1)>+<getExpression(expr2)>)";
        case sub(AExpr expr1, AExpr expr2): store += "(<getExpression(expr1)>-<getExpression(expr2)>)";
        case gt(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs)>\><getExpression(rhs)>)";
        case lt(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs)>\<<getExpression(rhs)>)";
        case geq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs)>\>=<getExpression(rhs)>)";  
        case leq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs)>\<=<getExpression(rhs)>)";
        case eq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs)>==<getExpression(rhs)>)";
        case neq(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs)>!=<getExpression(rhs)>)";
        case and(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs)>&&<getExpression(rhs)>)";
        case or(AExpr lhs, AExpr rhs): store += "(<getExpression(lhs)>||<getExpression(rhs)>)";     
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


