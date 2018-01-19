module sqat::series2::A1a_StatCov

import IO;
import String;
import Set;
import lang::java::jdt::m3::Core;
import util::ValueUI;

/*

Implement static code coverage metrics by Alves & Visser 
(https://www.sig.eu/en/about-sig/publications/static-estimation-test-coverage)


The relevant base data types provided by M3 can be found here:

- module analysis::m3::Core:

rel[loc name, loc src]        M3.declarations;            // maps declarations to where they are declared. contains any kind of data or type or code declaration (classes, fields, methods, variables, etc. etc.)
rel[loc name, TypeSymbol typ] M3.types;                   // assigns types to declared source code artifacts
rel[loc src, loc name]        M3.uses;                    // maps source locations of usages to the respective declarations
rel[loc from, loc to]         M3.containment;             // what is logically contained in what else (not necessarily physically, but usually also)
list[Message]                 M3.messages;                // error messages and warnings produced while constructing a single m3 model
rel[str simpleName, loc qualifiedName]  M3.names;         // convenience mapping from logical names to end-user readable (GUI) names, and vice versa
rel[loc definition, loc comments]       M3.documentation; // comments and javadoc attached to declared things
rel[loc definition, Modifier modifier] M3.modifiers;     // modifiers associated with declared things

- module  lang::java::m3::Core:

rel[loc from, loc to] M3.extends;            // classes extending classes and interfaces extending interfaces
rel[loc from, loc to] M3.implements;         // classes implementing interfaces
rel[loc from, loc to] M3.methodInvocation;   // methods calling each other (including constructors)
rel[loc from, loc to] M3.fieldAccess;        // code using data (like fields)
rel[loc from, loc to] M3.typeDependency;     // using a type literal in some code (types of variables, annotations)
rel[loc from, loc to] M3.methodOverrides;    // which method override which other methods
rel[loc declaration, loc annotation] M3.annotations;

Tips
- encode (labeled) graphs as ternary relations: rel[Node,Label,Node]
- define a data type for node types and edge types (labels) 
- use the solve statement to implement your own (custom) transitive closure for reachability.

Questions:
- what methods are not covered at all?
- how do your results compare to the jpacman results in the paper? Has jpacman improved?
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)


*/

										 	
alias Graph = rel [loc from, str label, loc to]; /* Since it seems like enums don't exist in rascal, we are using
													* costant strings to label our edges.
													* "DT" = define type
													* "DM" = define method
													* "DC" = direct call
													* "VC" = virtual call */
													


M3 m3 = createM3FromEclipseProject(|project://jpacman-framework|);

bool isDT(loc l) {
	return isClass(l) || isInterface(l) || isEnum(l);
}

Graph recursiveConstructDT(M3 m3, loc package, loc target) {
	Graph result = {};
	loc nextPackage = package;
	
	if(isPackage(target)) 
		nextPackage = target;
	if (isDT(target))
		result += <package, "DT", target>;
	if (isPackage(target) || isCompilationUnit(target) || isDT(target))
		for(x <- m3.containment[target])
			result += recursiveConstructDT(m3, nextPackage, x);	
		 
	return result;
}

Graph constructDTEntries(M3 m3) {
	Graph result = {};

	for(n <- m3.declarations, isPackage(n.name))
		result += recursiveConstructDT(m3, n.name, n.name);
		
	return result;
}

Graph recursiveConstructDM(M3 m3, loc parent, loc target) {
	Graph result = {};
		
	if(isDT(target))
		for(x <- m3.containment[target])
			result += recursiveConstructDM(m3, target, x);
	
	if(isMethod(target))
		result += <parent, "DM", target>;
		
	return result; 
}

Graph constructDMEntries(M3 m3) {
	Graph result = {};
	
	for(n <- m3.declarations, isDT(n.name))
		result += recursiveConstructDM(m3, n.name, n.name);
		
	return result;
}

Graph constructDCEntries(M3 m3) {
	Graph result = {};
	
	for(c <- m3.methodInvocation, !startsWith(c.to.path, "/java") && !(contains(c.from.path, "$anonymous") || contains(c.to.path, "$anonymous"))) {
		result += <c.from, "DC", c.to>;
	}
	
	return result;
}

Graph constructVCEntries(M3 m3) {
	Graph result = {};
	
	for(c <- m3.methodInvocation, !isClass(c.from) && !startsWith(c.to.path, "/java") ) {
		for(vc <- m3.methodOverrides, vc.to == c.to && !startsWith(vc.from.path, "/java")) {
			result += <c.from, "VC", c.to>;
			result += <c.from, "VC", vc.from>;
		}
	}
	
	return result;
}

Graph constructGraph(M3 m3) = constructDTEntries(m3) + constructDMEntries(m3) + constructDCEntries(m3) + constructVCEntries(m3);

set[loc] identifyTestClasses(M3 m3) {
	set[loc] result = {};
	for(n <- m3.declarations, isDT(n.name) && contains(n.src.path, "/test/")) {
		result += n.name;
	}
	return result;
}

set[loc] slice(Graph g, set[loc] testClasses) {
	set[loc] result = {};
	rel[loc from, loc to] calls = {<x.from, x.to> | x <- g, x.label == "DC" || x.label == "VC"};
	rel[loc from, loc to] R = calls;
	set[loc] testMethods = getTestMethods(g, testClasses);
	
	solve(R) {
		R = R + (R o calls);
	}
	
	for(tc <- testClasses) {
		for (n <- g, n.label == "DM" && n.from == tc) {
			result += {r | r <- R[n.to] && !(r in testMethods)};
		}
	}
	
	return result;
}

set[loc] getTestMethods(Graph g, set[loc] testClasses) {
	set[loc] result = {};
	for (n <- g, n.label == "DM" && n.from in testClasses) {
		result += n.to;
	}
	return result;
} 

void main() {
	Graph g = constructGraph(m3);
	set[loc] testClasses = identifyTestClasses(m3);
	set[loc] coveredMethods = slice(g, testClasses);
	real coverage = size(coveredMethods) * 1.0 / size({n | n <- g, n.label=="DM" && !(n.from in testClasses)});
	println("Coverage is <coverage * 100>%");
	println("Coverage mentioned in the paper is 88.06%");
}

test bool testConstructDTEntries() {
	int DTCount = 0;
	Graph G = constructDTEntries(m3);
	
	for(n <- m3.declarations, isDT(n.name))
		DTCount += 1;
	
	println("Expected the graph to be size <DTCount>; actual value: <size(G)>");
	return size(G) == DTCount;
}

test bool testConstructDMEntries() {
	int methodsCount = 0;
	Graph G = constructDMEntries(m3);
	
	// We filter out anonymous functions.
	for(n <- m3.declarations, isMethod(n.name) && ! contains(n.name.path, "$anonymous"))
		methodsCount += 1;
		
	println("Expected the DM graph to be size <methodsCount>; actual size: <size(G)>");
	return size(G) == methodsCount;
}

test bool testConstructDCEntries() {
	M3 m3 = createM3FromFile(|project://sqat-analysis/src/sqat/series2/Dummy.java|);
	int DCcount = size(constructDCEntries(m3));
	
	println("Expected the DC graph to be size 2; actual size: <DCcount>");
	return DCcount == 2;
}

test bool testIdentifyTestClasses() {
	int testClassCount = size(identifyTestClasses(m3)); 
	
	println("Expected class count is 12; actual count: <testClassCount>");
	return testClassCount == 12;
}