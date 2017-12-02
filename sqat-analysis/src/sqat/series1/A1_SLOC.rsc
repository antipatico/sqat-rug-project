module sqat::series1::A1_SLOC

import IO;
import String;
import util::FileSystem;
import util::Math;
import List;

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

test bool testRemoveMultiLineComments() {
	return size(removeMultiLineComments(readFileLines(|project://sqat-analysis/tests/testFile.java|))) == 13;
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



test bool testRemoveLinesWithoutCode() {
	int s = size(removeLinesWithoutCode(readFileLines(|project://sqat-analysis/tests/testFile.java|)));
	println(s);
	return s == 17;
}

int getFileSLOC(loc file) {
	list[str] lines = [];
	int sloc = 0;
	lines = removeLinesWithoutCode(removeMultiLineComments(readFileLines(file)));
	/*
	for (line <- lines) {
		if (/^(\s|\t)*\/\/.*$/ := line) continue;
		if (/^(\s|\t)*$/ := line) continue;
		sloc+=1;
	}
	return sloc;*/
	
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
	loc rootFolder = |project://jpacman-framework/src/|;
	loc mainFolder = rootFolder + "main/";
	loc testFolder = rootFolder + "test/";
	
	SLOC mainSLOC = sloc(mainFolder);
	SLOC testSLOC = sloc(testFolder);
	SLOC totalSLOC = mainSLOC + testSLOC;
	
	int mainSize = calculateLineCountFromSLOC(mainSLOC);
	int testSize = calculateLineCountFromSLOC(testSLOC);
	int totalSize = mainSize + testSize;
	
	real ratio = toReal(mainSize) / testSize;
	tuple[loc file, int size] biggestFile = findBiggestFile(totalSLOC);
	
	println("Total main size: <mainSize>"); 
	println("Total test size: <testSize>");
	println("Total project size: <totalSize>");
	println("Main to test ratio: <ratio>");
	println("Biggest file: <biggestFile.file> Size: <biggestFile.size>");
}

int calculateLineCountFromSLOC(SLOC sloc) {
	int totalLineCount = 0;

	for (s <- sloc) {
		totalLineCount += sloc[s];
	}

	return totalLineCount;
}

tuple[loc, int] findBiggestFile(SLOC sloc) {
	tuple[loc file, int sloc] result = <|file://none|,-1>;
	
	for (s <- sloc, sloc[s] > result.sloc) {
		result.sloc = sloc[s];
		result.file = s;
	}
	
	return result;
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