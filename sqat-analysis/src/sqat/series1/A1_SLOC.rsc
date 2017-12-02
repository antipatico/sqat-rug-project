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


list[str] removeMultiLineComments(list[str] lines) {
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

/*
list[str] removeLinesWithoutCode(list[str] lines) {
	list[str] linesWithCodeOnly = [];
	
	for (line <- lines) {
		if (/^(\s|\t)*\/\/.*$/ := line) continue;
		if (/^(\s|\t)*$/ := line) continue;
		
		linesWithCodeOnly += line;
	}
	
	return linesWithCodeOnly;
}*/

int getFileSLOC(loc file) {
	list[str] lines = [];
	int sloc = 0;
	lines = removeMultiLineComments(readFileLines(file));

	for (line <- lines) {
		if (/^(\s|\t)*\/\/.*$/ := line) continue;
		if (/^(\s|\t)*$/ := line) continue;
		sloc+=1;
	}
	return sloc;
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

/*
Answer the following questions:
- what is the biggest file in JPacman?
- what is the total size of JPacman?
- is JPacman large according to SIG maintainability?
++
- what is the ratio between actual code and test code size?
*/

void main() {
	loc rootFolder = |project://jpacman-framework/src/|;
	loc mainFolder = rootFolder + "main/";
	loc testFolder = rootFolder + "test/";
	SLOC mainSLOC = sloc(mainFolder);
	SLOC testSLOC = sloc(testFolder);
	SLOC totalSLOC = mainSLOC + testSLOC;
	
	tuple[loc file, int sloc] maxSLOC = <|file://none|,-1>;
	int totalSize, mainSize, testSize;
	totalSize = mainSize = testSize = 0;
	
	for(result <- totalSLOC) {
		int currentSLOC = totalSLOC[result];
		
		if(maxSLOC.sloc < currentSLOC) {
			maxSLOC.sloc = currentSLOC;
			maxSLOC.file = result;	
		}
		
		if(result in testSLOC) {
			mainSize += currentSLOC;
		} else {
			testSize += currentSLOC;
		}
		//print(result); print(": "); println(currentSLOC);
	}
	totalSize = testSize + mainSize;
	print("Biggest file: "); print(maxSLOC.file); print(": "); println(maxSLOC.sloc);
	print("Total size: "); println(totalSize);
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