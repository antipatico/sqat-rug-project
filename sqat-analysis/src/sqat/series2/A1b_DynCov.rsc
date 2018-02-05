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
	Result of this program is 74% coverage, while EclEmma suggests that coverage is 76% which is 
	quite close. Difference could be because our program does not count in covered constructors.
	But then depends on how EclEmma is implemented.
	
- which methods have full line coverage?
- which methods are not covered at all, and why does it matter (if so)?
	We couldn't tell exactly because location of the method that was put into CSV file was different
	from the src of the method mentioned in m3.declarations. Because of this, it was impossible to tell,
	which methods did get called while running tests and which were not.
	
	Usually you want your code to be covered completely with the tests, because it leaves less space
	for errors and prevents "breaking" the code while adding some changes to it. Automatic testing 
	takes less time in the long run than manual testing does.

- what are the drawbacks of source-based instrumentation?
	It is slow (especially for bigger projects) and running instrumented code requires working 
	project which is not always the case in the process of developing. 

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

void instrumentMethods() {
	loc proj = |project://jpacman-framework/src/main|;
	set[loc] fs = files(proj);
	for (f <- fs, f.extension == "java") {
	    println(f);
	    Tree tree = parseJava(f);
	    
	    loc location = |project://none|;
	    
	    tree = visit(tree) {
	    	case m:(MethodDec)`<MethodDecHead mdh> <MethodBody mb>` => insertStm(mdh, mb, m@\loc)
	    }
	    
	    f.authority = "jpacman-instrumented";
	    writeFile(f, unparse(tree));
  	}
}

MethodDec insertStm(MethodDecHead mdh, MethodBody mb, loc location) {
	hitInfo = parse(#BlockStm, "nl.rug.CoverageAPI.hit(\"<location>\");");
	mb = visit(mb) {
		case (Block) `{ <BlockStm* bs> }` => (Block)`{ <BlockStm hitInfo> <BlockStm* bs> }`
	}
	
	return (MethodDec)`<MethodDecHead mdh> <MethodBody mb>`;
}

void methodCoverage() {
	M3 m3 = createM3FromEclipseProject(|project://jpacman-framework|);
	
	list[str] methodCoverageResults = readFileLines(|project://jpacman-instrumented/coverage-log.csv|);
	set[str] methodsHit = {};
	for (r <- methodCoverageResults) {
		methodsHit += r;
	}
	
	rel[loc name, loc src] allMethods = {m | m <- m3.declarations, isMethod(m.name) && !isConstructor(m.name) && !contains("<m.src>", "src/test/")};
	
	println("Method coverage is <size(methodsHit)*1.0/size(allMethods)>");
}

void main() {
	methodCoverage();
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