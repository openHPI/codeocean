import java.util.ArrayList;

import org.junit.runner.JUnitCore;
import org.junit.runner.Result;
import org.junit.runner.notification.Failure;

public class TestSpecificTestsRunner {
	static ArrayList<ArrayList<Result>>  allTestResults = new ArrayList<ArrayList<Result>>();
	static int total=3;
	static int fails=0;
	public static void main(String[] args) throws NoSuchMethodException, SecurityException, ClassNotFoundException{
		//Nothing here is needed to be changed
		System.out.println("Tests run: 3");
		
		System.out.println("\nNo. 1: Testing your CA implementation... \n");
		runTests(TestSpecificRuns.class); //doesn't set allTestResults
		
		//System.out.println("\nNo. 2: Preliminary Tests on your tests... \n");
		//runTests(AntlrMain.class); //doesn't set allTestResults
		
		System.out.println("\nNo. 2 & 3: Testing your tests on Gold & Coals... \n");
		runTests(TestSpecificTests.class); //sets allTestResults

        System.out.println("\nTotal Failures: "+ fails+"\n");
        
		//all those collecting test results will set them in allTestResults
		/*
		for (ArrayList<Result> testResult : allTestResults) {
			System.out.println("\nMore information on errors in your testing: \n");
			for (Result theResult : testResult) {
			    for (Failure failure : theResult.getFailures()){
			        System.out.println(failure.toString());
			    }
			}
		}
		*/
	}

	private static void runTests(Class test){
	    Result result = JUnitCore.runClasses(test);
	    int i = result.getFailureCount();

        if(i>0) {
        	if(test.getName().equals("TestSpecificTests")){
        		fails=fails+i;
        	}
        	else {
        		fails++;
        	}
            for (Failure failure : result.getFailures()){
                System.out.println("        FailCase: " +failure.toString());
            }
        } else {
		System.out.println("        Passes");
	}
	}
}