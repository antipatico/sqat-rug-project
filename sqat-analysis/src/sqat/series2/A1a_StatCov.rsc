module sqat::series2::A1a_StatCov

import IO;
import String;
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

alias Node = tuple[loc name, bool isTest]; /* A node could either be a Package, a Class, a Method or a
										 	* Interface. You can check what it actually is by running
										 	* E.G. isPackage(mynode.name); */
										 	
alias Graph = rel [Node from, str label, Node to]; /* Since it seems like enums don't exist in rascal, we are using
													* costant strings to label our edges.
													* "DT" = define type
													* "DM" = define method
													* "DC" = direct call
													* "VC" = virtual call */

M3 m3 = createM3FromEclipseProject(|project://jpacman-framework|);

set[Node] getNodesFromM3(M3 m3) {
	set[Node] result = {};
	for(entity <- m3.declarations) {
		loc n = entity.name;
		bool isTest = !isPackage(n) && contains(entity.src.path, "/test/");
		if(isMethod(n) || isClass(n) || isPackage(n) || isInterface(n))
			result += <n, isTest>;
	}
	return result;
}

Graph constructGraph(M3 m3, set[Node] nodes) {
	Graph result = {};
	for(Node n <- nodes, isPackage(n.name)) {
		for(loc cu <- m3.containment[n.name], isCompilationUnit(cu))
			println(m3.containment[cu]);
	}
	return result;
}

void main() {
	set[Node] nodes = getNodesFromM3(m3);
	Graph g = constructGraph(m3, nodes);
	//text(m3.containment);
}
