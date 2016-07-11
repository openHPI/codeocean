import static org.junit.Assert.*;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.junit.AfterClass;
import org.junit.Test;

import org.junit.runner.JUnitCore;
import org.junit.runner.Result;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized.Parameter;
import org.junit.runners.Parameterized.Parameters;
import org.junit.runners.model.InitializationError;
import org.junit.runners.Parameterized;

@RunWith(Parameterized.class)
public class TestSpecificTests {

	
	static final int NUMBER_OF_MUTANTS = 12;
	static int mutantIndex = 1;
	static int caughtCoals =0;
	private Result testResult;
	static ArrayList<Result> allResults = new ArrayList<Result>();
	
	static int goldInverseScore;
	
	@SuppressWarnings("unchecked")
	@Parameters
    public static Collection<Object[]> data() {
    	
    	Collection<Object[]> testRule54CAClasses = new ArrayList<>();
    	int i=0;
    	while(i <= NUMBER_OF_MUTANTS){
    		
    		if (i==0){
    			testRule54CAClasses.add(new Object[] {"Rule54CA", true});
    		} else if (i==7){

		} else {
    			testRule54CAClasses.add(new Object[] {("Mu" + i + "Rule54CA"), false});
    		}
    		i++;
    	}
    	
    	return testRule54CAClasses;
    }
    		

    @Parameter // first data value (0) is default
    public String TestClasseName;
    
    @Parameter(value = 1)
    public boolean gold;
    
   
    	@SuppressWarnings("unchecked")
	@Test
	public void mutationTesting () throws ClassNotFoundException{
			MySpecificTest.ClassToTest = (Class<CellularAutomaton>) Class.forName(TestClasseName);
			testResult = JUnitCore.runClasses(MySpecificTest.class);

			if(gold){
			    	if(testResult.getRunCount()!=0){
					goldInverseScore=testResult.getFailureCount()/testResult.getRunCount();
				}
				else {
					goldInverseScore=1;
				}
				assertTrue("At least 60% of your test cases must pass against our correct implementation sample!",  goldInverseScore < 0.4);
			} else {
				if (!testResult.wasSuccessful() && !(testResult.getFailures().get(0).getException().getMessage().equals("No runnable methods")) ) {
					caughtCoals = caughtCoals+1;
				}
				if (mutantIndex==NUMBER_OF_MUTANTS-1){
					assertTrue("You did not catch enough incorrect test samples. You caught " + caughtCoals + " of our " + NUMBER_OF_MUTANTS + " samples", (caughtCoals*1.0/NUMBER_OF_MUTANTS > 0.9));
				}
				mutantIndex++;
			}
			allResults.add(testResult);
	}
	
	@AfterClass
	public static void sendResults(){
		TestSpecificTestsRunner.allTestResults.add(allResults);
	}
}