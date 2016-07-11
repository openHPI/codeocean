import org.junit.runner.JUnitCore;
import org.junit.runner.Result;
import org.junit.runner.notification.Failure;

public class MyTestRunner {
	
	public static void main(String[] args) throws NoSuchMethodException, SecurityException, ClassNotFoundException{

		//Nothing here is needed to be changed
		System.out.println("***************************");
		System.out.println("Running your tests on your implementation: ");
		//Rule54TestGood.ClassToTest = (Class<CellularAutomaton>) Class.forName("hpi.cellular.specific.Rule54CA");
		//runTests(Rule54TestGood.class);
		MySpecificTest.ClassToTest = (Class<CellularAutomaton>) Class.forName("MyRule54CA");
		runTests(MySpecificTest.class);
		System.out.println("***************************\n");
	}

	private static void runTests(Class test){
	    Result result = JUnitCore.runClasses(test);
	    for (Failure failure : result.getFailures()){
	        System.out.println(failure.toString());
	    }
	}
}
