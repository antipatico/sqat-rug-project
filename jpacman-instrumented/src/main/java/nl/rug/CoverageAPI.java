/* Authors: Jacopo Scannella, Rita Dubovska */
package nl.rug;

import java.io.*;
import java.util.HashSet;
import java.util.Set;

public final class CoverageAPI {
	private static final String methodLogPath="method-coverage-log.csv";
	private static final String lineLogPath="line-coverage-log.csv";
	private static Set<String> covered = new HashSet<String>();
	
	private static void log(String message, String path) {
		if(covered.contains(message)) {
			return;
		}

		covered.add(message);
		try {
			File logFile = new File(path);
			BufferedWriter bw;
			
			if(!logFile.exists()) {
				logFile.createNewFile();
			}
			
			bw = new BufferedWriter(new FileWriter(logFile, true));
			bw.write(message);
			bw.flush();
			bw.close();
		} catch (Exception e) {
			System.err.println(String.format("ERROR: can't open log fiel with WRITE privilege."));
			e.printStackTrace();
			System.exit(1);
		}
	}
	
	public static void hit(String location) {
		log(String.format("%s\n", location), methodLogPath);
	}
	
	public static void hit(String location, int line) {
		log(String.format("%s,%d\n", location, line), lineLogPath);
	}
}