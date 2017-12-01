module sqat::series1::A1_SLOC

import IO;
import ParseTree;
import String;
import util::FileSystem;

/* 

Count Source Lines of Code (SLOC) per file:
- ignore comments
- ignore empty lines

Tips
- use locations with the project scheme: e.g. |project:///jpacman/...|
- functions to crawl directories can be found in util::FileSystem
- use the functions in IO to read source files

Answer the following questions:
- what is the biggest file in JPacman?
- what is the total size of JPacman?
- is JPacman large according to SIG maintainability?
- what is the ratio between actual code and test code size?

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/

alias SLOC = map[loc file, int sloc];


list[str] removeComments(list[str] lines) {
	list[str] linesWithoutComments = [];
	
	bool insideComment = false;
	int commentLines = 0;
	
	for (line <- lines) {
		
		if (insideComment) {
			if (/^.*\*\/.*$/ := line) {
				insideComment = false;
			}
		}
		else {
			if (/^.*\/\*.*$/ := line) {
				insideComment = true;
			}
			if (!insideComment) linesWithoutComments += line;
		}
	}
	
	return linesWithoutComments;
}

list[str] removeLinesWithoutCode(list[str] lines) {
	list[str] linesWithCodeOnly = [];
	
	for (line <- lines) {
		if (/^(\s|\t)*\/\/.*$/ := line) continue;
		if (/^(\s|\t)*$/ := line) continue;
		
		linesWithCodeOnly += line;
	}
	
	return linesWithCodeOnly;
}

int getFileSLOC(loc file) {
	list[str] lines;
	lines = readFileLines(file);
	
	lines = removeLinesWithoutCode(removeComments(lines));

	return size(lines);
}

SLOC sloc(loc project) {
  SLOC result = ();
  fs = crawl(project);
  for (/file(location) := fs) { /* For each file in the designed directory */
  	if(location.extension == "java")
  		result[location] = getFileSLOC(location);
  }
    
  return result;
}


void main() {
	results = sloc(|project://jpacman-framework/src/main/|);
	for(result <- results) {
		print(result); print(": "); println(results[result]);
	}
}

  //(0 | println(location) | /file(location) := fs );


/*
int countDirs(FileSystem fs) {
	int count = 0;
	visit(fs) {
		case directory(_,_): count += 1;
	}
	return count;
}
*/