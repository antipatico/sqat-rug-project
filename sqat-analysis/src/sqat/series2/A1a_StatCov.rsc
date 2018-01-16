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

/*
Graph recursiveConstructDT(loc package) {
	Graph result = {};
	for(loc cu <- m3.containment[package]) {
		if(isPackage(cu))
			result += recursiveConstructDT(cu);
		else if (isCompilationUnit(cu)) {
			for(n <- m3.containment[cu]) {
				if(isClass(n) || isInterface(n))
					result += <package, "DT", n>;
				else if(isPackage(n))
					result += recursiveConstructDT(cu);
			}
		}
	}
	return result;
}
*/

Graph recursiveConstructDT(M3 m3, loc package, loc target) {
	Graph result = {};
	if(isPackage(target)) 
		for(x <- m3.containment[target])
			result += recursiveConstructDT(m3, target, x);
	if (isClass(target) || isInterface(target))
		result += <package, "DT", target>;
	if (isCompilationUnit(target) || isClass(target) || isInterface(target))
		for(x <- m3.containment[target])
			result += recursiveConstructDT(m3, package, x);
		 
	return result;
}

Graph constructDTEntries(M3 m3) {
	Graph result = {};

	for(n <- m3.declarations, isPackage(n.name)) {
		result += recursiveConstructDT(m3, n.name, n.name);
	}
	/*
	// The next piece of code is used to handle classes and interfaces declared inside classes.
	for(r <- m3.containment, isClass(r.from) && (isClass(r.to) || isInterface(r.to))) {
		for (r2 <- result, r2.to == r.from && r2.label == "DT")
			result += <r2.from, "DT", r.to>;
	}
	*/
	
	return result;
}

Graph constructDMEntries(M3 m3) {
	Graph result = {};
	
	for(n <- m3.declarations, isClass(n.name) || isInterface(n.name))
		for(meth <- m3.containment[n.name], isMethod(meth))
			result += <n.name, "DM", meth>;
	
	
	return result;
}

Graph constructGraph() {
	Graph result = constructDTEntries(m3) + constructDMEntries(m3);
	return result;
}

void main() {
	Graph g = constructGraph();
	text(g);
}

test bool testConstructDTEntries() {
	int classesAndInterfaceCount = 0;
	Graph G = constructDTEntries(m3);
	
	for(n <- m3.declarations, isClass(n.name) || isInterface(n.name))
		classesAndInterfaceCount += 1;
	
	println("Expected the graph to be size <classesAndInterfaceCount>; actual value: <size(G)>");
	return size(G) == classesAndInterfaceCount;
}

test bool testConstructDMEntries() {
	//set[loc] debug = {};
	int methodsCount = 0;
	Graph G = constructDMEntries(m3);
	
	for(n <- m3.declarations, isMethod(n.name)) {
		//debug += n.name;
		methodsCount += 1;
	}
	
	//for(r <- G) {
	//	debug += r.to;
	//}
	
	println("Expected the DM graph to be size <methodsCount>; actual size: <size(G)>");
	//text(debug);
	return size(G) == methodsCount;
}