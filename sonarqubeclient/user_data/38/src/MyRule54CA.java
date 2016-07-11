public class MyRule54CA extends CellularAutomaton {

	private static String s52 = "01101100"; 

	// currentState is the field modified after every iteration of the evolution of the CA
	private String currentState;

	// This is the constructor used in the Main class and is to be used for your tests (Do not modify it)
	public MyRule54CA(String state) {
		currentState=state;
	}

	@Override
	public CellularAutomaton iterate(int numberOfIterations) {
		// Replace the contents of this method with your implementation code 
		// Here the code is to iterate over numberOfIterations passed as parameter to it 
		// Then modify the currentState field here to reflect the state the CA reaches after the given number of iterations
		// Just remember this problem is rich with corner cases, 
		// and your automaton could be single celled, double celled 
		// or could have any number of cells.
        
		if (currentState != null && currentState.length() > 1 && numberOfIterations > 0)		
		  for (int i=0; i<numberOfIterations; ++i)
			 iterate();
		
        return this;

	}

	private void iterate() {
		int l = currentState.length();
		String r = "";
		int x;
		
		for (int i = 0; i<l; ++i){
			x = 0;
			if ((i>0) && currentState.charAt(i-1) != '0')   x+=4; 
			if (currentState.charAt(i) != '0')              x+=2;
			if ((i<l-1) && currentState.charAt(i+1) != '0') x+=1;
			
			r+= s52.charAt(x);			
		}
		currentState = r;
		
	}

	// Do not modify the display function below
	@Override
	public String display() {
		return currentState;
	}
}
