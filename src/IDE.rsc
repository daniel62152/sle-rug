module IDE

import Syntax;
import AST;
import CST2AST;
import Resolve;
import Check;
import Compile;

import util::IDE;
import Message;
import ParseTree;


private str MyQL ="MyQL";

anno rel[loc, loc] Tree@hyperlinks;

void main() {
  registerLanguage(MyQL, "myql", Tree(str src, loc l) {
    return parse(#start[Form], src, l);
  });
  
  contribs = {
    annotator(Tree(Tree t) {
      if (start[Form] pt := t) {
        AForm ast = cst2ast(pt);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, collect(ast), useDef);
        return t[@messages=msgs][@hyperlinks=useDef];
      }
      return t[@messages={error("Not a form", t@\loc)}];
    }),
    
    builder(set[Message] (Tree t) {
      if (start[Form] pt := t) {
        AForm ast = cst2ast(pt);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, collect(ast), useDef);
        set[Message] errors = {};
        set[Message] warnings = {};
        for(m <- msgs){
        	if(warning(_, _) := m){
        		warnings += {m};
        	}else {
        		errors += {m};
        	} 
        }
        if (errors == {}) {
          compile(ast);
        }
        return msgs;
      }
      return {error("Not a form", t@\loc)};
    })
  };
  
  registerContributions(MyQL, contribs);
}
