/* Authors: Jacopo Scannella, Rita Dubovska */
package nl.rug;

import java.io.*;
import java.util.HashSet;
import java.util.Set;

public final class CoverageAPI {
	private static final String logPath="coverage-log.csv";
	private static Set<String> covered = new HashSet<String>();
	
	private static void log(String message) {
		if(covered.contains(message)) {
			return;
		}

		covered.add(message);
		try {
			File logFile = new File(logPath);
			BufferedWriter bw;
			
			if(!logFile.exists()) {
				logFile.createNewFile();
			}
			
			bw = new BufferedWriter(new FileWriter(logFile, true));
			bw.write(message);
			bw.flush();
			bw.close();
		} catch (Exception e) {
			System.err.println(String.format("ERROR: can't open %s with WRITE privilege.", logPath));
			e.printStackTrace();
			System.exit(1);
		}
	}
	
	public static void hit(String location) {
		log(String.format("%s\n", location));
	}
	
	public static void hit(String clas, String meth, int line) {
		log(String.format("%s,%s,%d\n", clas, meth, line));
	}
}