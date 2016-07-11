import java.util.HashMap;

import antlrstuff.Java8BaseListener;
import antlrstuff.Java8Parser;

public class Java8Rules extends Java8BaseListener {

	private static boolean isInMethodNameScope = false;
	private static boolean isTest = false;
	private static int countAssertions = 0;
		
	private static HashMap<String, Integer> rules = new HashMap<String, Integer>();
	private static String methodName;
	
	public static HashMap<String, Integer> getRules() {
		return rules;
	}
	
	@Override 
	public void enterMethodDeclaration(Java8Parser.MethodDeclarationContext ctx) { 
		isInMethodNameScope = true;
		methodName = ctx.methodHeader().methodDeclarator().getText();
	}
	
	@Override 
	public void enterMarkerAnnotation(Java8Parser.MarkerAnnotationContext ctx) { 
		isTest = "Test".equals(ctx.typeName().getText());
	}
		
	@Override 
	public void enterMethodInvocation(Java8Parser.MethodInvocationContext ctx) { 
		if (ctx.methodName() != null) {
			if (ctx.methodName().getText().contains("assert")) countAssertions++;
		} 
	}
	
	@Override 
	public void exitMethodBody(Java8Parser.MethodBodyContext ctx) { 	
		if(isInMethodNameScope && isTest){
			rules.put(methodName, countAssertions);
		} 
		//reset
		isInMethodNameScope = false;
		countAssertions = 0;
		isTest = false;
	}
}