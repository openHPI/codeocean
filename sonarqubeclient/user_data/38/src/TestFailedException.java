import java.util.ArrayList;

public class TestFailedException extends Exception {
	String message = "";
	
	public TestFailedException(ArrayList<String> failedTests) {
		message = "Failures: " + failedTests.size() + "\n";
		for (String s : failedTests) {
			message += s + "\n";
		}
	}
	
	public String getMessage() {
		return message;
	}
	
}