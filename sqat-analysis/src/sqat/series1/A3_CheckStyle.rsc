module sqat::series1::A3_CheckStyle

import sqat::series1::A2_McCabe;
import lang::java::jdt::m3::AST;
import Java17ish;
import Message;
import IO;
import List;

/*

Assignment: detect style violations in Java source code.
Select 3 checks out of this list:  http://checkstyle.sourceforge.net/checks.html
Compute a set[Message] (see module Message) containing 
check-style-warnings + location of  the offending source fragment. 

Plus: invent your own style violation or code smell and write a checker.

Note: since concrete matching in Rascal is "modulo Layout", you cannot
do checks of layout or comments (or, at least, this will be very hard).

JPacman has a list of enabled checks in checkstyle.xml.
If you're checking for those, introduce them first to see your implementation
finds them.

Questions
- for each violation: look at the code and describe what is going on? 
  Is it a "valid" violation, or a false positive?

Tips 

- use the grammar in lang::java::\syntax::Java15 to parse source files
  (using parse(#start[CompilationUnit], aLoc), in ParseTree)
  now you can use concrete syntax matching (as in Series 0)

- alternatively: some checks can be based on the M3 ASTs.

- use the functionality defined in util::ResourceMarkers to decorate Java 
  source editors with line decorations to indicate the smell/style violation
  (e.g., addMessageMarkers(set[Message]))

  
Bonus:
- write simple "refactorings" to fix one or more classes of violations 

*/


set[Message] checkStyle(loc project) {
  set[Message] result = {};
  set[Declaration] AST = createAstsFromEclipseProject(project, true);
  
  result = checkCyclomaticComplexity(AST);
  result += checkMethodNames(AST);
  result += checkParameterNumber(AST, 6);
  
  return result;
}


set[Message] checkCyclomaticComplexity(set[Declaration] AST) {
  set[Message] result = {};
  CC complexities = cc(AST);
  for(c <- complexities) {
  	if(c.cc > 7 && c.cc < 11)
  	  result += warning("Complexity exceeds 8, consider refactoring.", c.method);
  	else if(c.cc > 10)
  	  result += warning("Complexity exceeds 10, needs refactoring.", c.method);
  }
  return result;
}


set[Message] checkMethodNames(set[Declaration] AST) {
  set[Message] result = {};
  visit(AST) {
  	case m:method(_,name,_,_,_): {
  		if (!(/^[a-z][a-zA-Z0-9]*$/ := name))
  			result += warning("Method name not following the format.",m.src);
  	}
  }
  
  return result;
}

set[Message] checkParameterNumber(set[Declaration] AST, int maxParameterNumber) {
  set[Message] result = {};
  visit(AST) {
    case m:method(_,_,parameters,_,_): {
      if (size(parameters) > maxParameterNumber) result += warning("Parameter number exceeds the limit of <maxParameterNumber>!", m.src); 
    }
  }
  
  return result;
}

void main() {
	println(checkStyle(|project://jpacman-framework|));
}