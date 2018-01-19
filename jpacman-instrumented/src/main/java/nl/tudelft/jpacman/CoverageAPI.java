/* Authors: Jacopo Scannella, Rita Dubovska */
package nl.tudelft.jpacman;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;

public final class CoverageAPI {
	private static final String logFile="coverage-log.csv";
	private static Boolean firstLog = true;
	
	private static void log(String message) {
		try {
			if(firstLog)
				Files.write(Paths.get(logFile), message.getBytes());
			else
				Files.write(Paths.get(logFile), message.getBytes(),StandardOpenOption.CREATE, StandardOpenOption.APPEND);
			firstLog = false;
		} catch (Exception e) {
			System.err.println(String.format("ERROR: can't open %s with WRITE privilege.", logFile));
			System.exit(1);
		}
	}
	public static void hit(String clas, String meth) {
		log(String.format("%s,%s\n", clas, meth));
	}
	public static void hit(String clas, String meth, int line) {
		log(String.format("%s,%s,%d\n", clas, meth, line));
	}
}