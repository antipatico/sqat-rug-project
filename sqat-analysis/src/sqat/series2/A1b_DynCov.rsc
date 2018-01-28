module sqat::series2::A1b_DynCov

import Java17ish;
import ParseTree;
import util::FileSystem;
import util::ValueUI;
import IO;
import lang::csv::IO;
import lang::java::jdt::m3::Core;
import String;
import Set;

/*

Assignment: instrument (non-test) code to collect dynamic coverage data.

- Write a little Java class that contains an API for collecting coverage information
  and writing it to a file. NB: if you write out CSV, it will be easy to read into Rascal
  for further processing and analysis (see here: lang::csv::IO)

- Write two transformations:
  1. to obtain method coverage statistics
     (at the beginning of each method M in class C, insert statement `hit("C", "M")`
  2. to obtain line-coverage statistics
     (insert hit("C", "M", "<line>"); after every statement.)

The idea is that running the test-suite on the transformed program will produce dynamic
coverage information through the insert calls to your little API.

Questions
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)
- which methods have full line coverage?
- which methods are not covered at all, and why does it matter (if so)?
- what are the drawbacks of source-based instrumentation?

Tips:
- create a shadow JPacman project (e.g. jpacman-instrumented) to write out the transformed source files.
  Then run the tests there. You can update source locations l = |project://jpacman/....| to point to the 
  same location in a different project by updating its authority: l.authority = "jpacman-instrumented"; 

- to insert statements in a list, you have to match the list itself in its context, e.g. in visit:
     case (Block)`{<BlockStm* stms>}` => (Block)`{<BlockStm insertedStm> <BlockStm* stms>}` 
  
- or (easier) use the helper function provide below to insert stuff after every
  statement in a statement list.

- to parse ordinary values (int/str etc.) into Java15 syntax trees, use the notation
   [NT]"...", where NT represents the desired non-terminal (e.g. Expr, IntLiteral etc.).  

*/

M3 m3 = createM3FromEclipseProject(|project://jpacman-framework|);

BlockStm updateInjectedStm(str clas, str meth) {
	return parse(#BlockStm, "nl.rug.CoverageAPI.hit(\"<clas>\", \"<meth>\");");
}

void methodCoverage(loc project) {
	for (f <- files(|project://jpacman-framework/src/main|), f.extension == "java") {
	    Tree tree = parseJava(f);
	    
	    str clas, meth = "none";
	    BlockStm injectedStm;
	    
	    tree = visit(tree) {
	    	case (EnumDecHead) `<EnumDecHead edh>`: {
	    		if(/([a-z]+\s*)*enum\s+<enumName:[a-zA-Z0-9]+>/ := "<edh>") {
	    			clas = enumName;
	    			injectedStm = updateInjectedStm(clas, meth);
	    		} else { 
	    			println("Enum parse failed!"); 
	    		}
	    	}
	    	case (ClassDecHead) `<ClassDecHead cdh>`: {
	    		if(/([a-z]+\s*)*class\s+<className:[a-zA-Z0-9]+>/ := "<cdh>") {
	    			clas = className;
	    			injectedStm = updateInjectedStm(clas, meth);
	    		} else { 
	    			println("Class parse failed!"); 
	    		}
	    	}
	    	case (MethodDecHead) `<MethodDecHead mdh>`: {
	    		if(/(\s*\@.+\n)?(\s|[\<\>A-Za-z0-9]+)*\s+<methodName:\w+>\(/ := "<mdh>") {
	    			meth = methodName;
	    			injectedStm = updateInjectedStm(clas, meth);
	    		} else { 
	    			println("Method parse failed!"); 
	    		}
	    	}
	    	case (Block)`{<BlockStm* stms>}` => (Block)`{<BlockStm injectedStm> <BlockStm* stms>}`
	    }
	    
	    f.authority = "jpacman-instrumented";
	    writeFile(f, unparse(tree));
	    //println(unparse(tree));
	    //break;
  	}
}

real calculateMethodCoverage() {
	r = readCSV(#rel[str class, str method], |project://jpacman-instrumented/coverage-log.csv|, header=false);
	text(r);
	set[loc] allMethods = {m.name | m <- m3.declarations, isMethod(m.name)};
	text(allMethods);
	return size(r)*1.0/size(allMethods);
}

void lineCoverage(loc project) {
  // to be done
}

// Helper function to deal with concrete statement lists
// second arg should be a closure taking a location (of the element)
// and producing the BlockStm to-be-inserted 
BlockStm* putAfterEvery(BlockStm* stms, BlockStm(loc) f) {
  
  Block put(b:(Block)`{}`) = (Block)`{<BlockStm s>}`
    when BlockStm s := f(b@\loc);
  
  Block put((Block)`{<BlockStm s0>}`) = (Block)`{<BlockStm s0> <BlockStm s>}`
    when BlockStm s := f(s0@\loc);
  
  Block put((Block)`{<BlockStm s0> <BlockStm+ stms>}`) 
    = (Block)`{<BlockStm s0> <BlockStm s> <BlockStm* stms2>}`
    when
      BlockStm s := f(s0@\loc), 
      (Block)`{<BlockStm* stms2>}` := put((Block)`{<BlockStm+ stms>}`);

  if ((Block)`{<BlockStm* stms2>}` := put((Block)`{<BlockStm* stms>}`)) {
    return stms2;
  }
}

str getClassName(loc name) {
	return head(tail(reverse(split("/", "<name>"))));
}

str getMethodName(loc name) {
	return head(split("(", head(reverse(split("/", "<name>")))));
}

test bool testGetClassName() {
	return "Level" == getClassName(|java+method:///nl/tudelft/jpacman/level/Level/isAnyPlayerAlive()|);
}

test bool testGetMethodName() {
	return "AnimatedSprite" == getMethodName(|java+constructor:///nl/tudelft/jpacman/sprite/AnimatedSprite/AnimatedSprite(nl.tudelft.jpacman.sprite.Sprite%5B%5D,int,boolean)|);
}