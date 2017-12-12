module sqat::series1::A2_McCabe

import lang::java::jdt::m3::AST;
//import util::ValueUI;
import IO;

/*

Construct a distribution of method cylcomatic complexity. 
(that is: a map[int, int] where the key is the McCabe complexity, and the value the frequency it occurs)


Questions:
- which method has the highest complexity (use the @src annotation to get a method's location)

- how does pacman fare w.r.t. the SIG maintainability McCabe thresholds?

- is code size correlated with McCabe in this case (use functions in analysis::statistics::Correlation to find out)? 
  (Background: Davy Landman, Alexander Serebrenik, Eric Bouwers and Jurgen J. Vinju. Empirical analysis 
  of the relationship between CC and SLOC in a large corpus of Java methods 
  and C functions Journal of Software: Evolution and Process. 2016. 
  http://homepages.cwi.nl/~jurgenv/papers/JSEP-2015.pdf)
  
- what if you separate out the test sources?

Tips: 
- the AST data type can be found in module lang::java::m3::AST
- use visit to quickly find methods in Declaration ASTs
- compute McCabe by matching on AST nodes

Sanity checks
- write tests to check your implementation of McCabe

Bonus
- write visualization using vis::Figure and vis::Render to render a histogram.

*/

set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework|, true); 

alias CC = rel[loc method, int cc];

// overload used in ex3
CC cc(loc project) {
	return cc(createAstsFromEclipseProject(project, true));
}

CC cc(set[Declaration] decls) {
  CC result = {};
  
  for(Declaration d <- decls) {
  	visit(d) {
  		case m:method(_,_,_,_,body): result[m.src] = mcCabeComplexity(body);
  		case c:constructor(_,_,_,body): result[c.src] = mcCabeComplexity(body);
  	}
  }
  
  return result;
}

alias CCDist = map[int cc, int freq];

CCDist ccDist(CC cc) {
  CCDist distribution = ();
  
  // init map with 0
  for (c <- cc) {
  	distribution[c.cc] = 0;
  }
  
  for (c <- cc) {
  	distribution[c.cc] += 1;
  }
  
  return distribution;
}

tuple[loc, int] getMaxComplexityMethod(CC complexities) {
	tuple[loc method, int cc]  result = <|file://n0n3|, -1>;
	
	for (c <- complexities, c.cc > result.cc) {
		result = c;
	}
	
	return result;
}

void main() {
	CC complexities = cc(jpacmanASTs());
	CCDist complexityFrequency = ccDist(complexities);
	tuple[loc method, int cc] maxComplexity = getMaxComplexityMethod(complexities);
	
	println(complexityFrequency);
	println(maxComplexity);
}

void printLocationAndComplexity() {
	for(cc <- cc(jpacmanASTs())) {
		println("<cc>");
	}
}

int mcCabeComplexity(Statement body) {
	return countControlStatements(body)+1;
}

int countControlStatements (Statement body) {
	int count = 0;

	// Information on what counts as control statement was found here: http://checkstyle.sourceforge.net/config_metrics.html#CyclomaticComplexity
	visit(body) {
		case \for(_,_,_): count += 1;
		case \for(_,_,_,_): count += 1;
		case \foreach(_,_,_) : count +=1;
		case \if(_,_): count += 1;
		case \if(_,_,_): count += 1;
		case \do(_,_): count += 1;
		case \while(_,_): count += 1;
		case \switch(_,_): count += 1;
		case \case(_): count += 1;
		case \defaultCase(): count += 1;
		case \catch(_,_): count += 1;
	}
	
	return count;
}

test bool testCountControlStatements() {
	Declaration ast = createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/level/Level.java|, true);
	
	controlStatementCount = 0;
	
	visit(ast) {
		case method(_,_,_,_,body): controlStatementCount += countControlStatements(body);
  		case constructor(_,_,_,body): controlStatementCount += countControlStatements(body);
	}
	
	println("There are <controlStatementCount> control statements. Expected 20.");
	
	return controlStatementCount == 20;
	
}