public class Main {
	
	public static void main(String[] args){
		
		System.out.println("Testing...");
		MyRule54CA myRule54 = new MyRule54CA("10011100");
		System.out.println("Initial State is: " + myRule54.display());
		System.out.println("The next 20 iterations are as follows:");
		for (int i = 0; i <= 20; i++) {
			System.out.println(myRule54.iterate(1).display());			
		}
		System.out.println("Current State after another iteration: "+myRule54.iterate(1).display());		
	}

}