public class Rule54CA extends CellularAutomaton {

	private boolean wrap=false;
	private String currentState;
	
	public Rule54CA(String state, boolean wrapAround) {

			currentState=state;
			setWrap(wrapAround);
	}

	public Rule54CA(String state) {
		currentState=state;
		setWrap(false);
	}

	@Override
	public Rule54CA iterate(int numberOfIterations) {
		
		while(numberOfIterations-->0)
		{
			String newState="";
			String currentCheck;
			final int len = currentState.length();
		    for (int i = 0; i < len; i++) {
		    	if (i == 0 && i == len-1) {
	    			currentCheck = (wrap? currentState.charAt(len-1):"0") + currentState.substring(i, i+1) + (wrap? currentState.charAt(0):"0");
		    	} else if (i == 0) {
		    			currentCheck = (wrap? currentState.charAt(len-1):"0") + currentState.substring(i, i+2);	
		    	} else if (i == len-1) {
		    		currentCheck = currentState.substring(i-1, i+1) + (wrap? currentState.charAt(0):"0") ;
		    	}
		    	else {
		    		currentCheck = currentState.substring(i-1, i+2);
		    	}
		    	newState += applyRules(currentCheck);
		    }
			currentState = newState;
		}
		return this;
	}
	
	char applyRules(String currentCheck ){
		if(currentCheck.equals("000") || currentCheck.equals("011") ||
				currentCheck.equals("110") || currentCheck.equals("111")){
			return '0';
		} else {
			return '1';
		}
	}

	@Override
	public String display() {
		return currentState;		
	}

	public boolean isWrap() {
		return wrap;
	}

	public void setWrap(boolean wrap) {
		this.wrap = wrap;
	}
}
