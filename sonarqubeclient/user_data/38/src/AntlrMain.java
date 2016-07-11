import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeWalker;
import org.junit.BeforeClass;
import org.junit.Test;

import antlrstuff.Java8Lexer;
import antlrstuff.Java8Listener;
import antlrstuff.Java8Parser;

//Teaching Team tests the participants' implementation and the participants' tests
public class AntlrMain {

	Java8Listener jbl = new Java8Rules();
	private static ArrayList<String> failedTests;
	private static ANTLRInputStream input;
	private static Java8Lexer lexer;
	private static CommonTokenStream tokens;
	private static Java8Parser parser;
	private static ParseTree tree;
	private static ParseTreeWalker walker;

	@BeforeClass
	public static void setupClass() {

		String[] files = {"MySpecificTest.java"};

		for (String file : files) {
			try {
				failedTests = new ArrayList<String>();
				input = new ANTLRInputStream(new FileInputStream(file));
				lexer = new Java8Lexer(input);
				tokens = new CommonTokenStream(lexer);
				parser = new Java8Parser(tokens);
				tree = parser.compilationUnit();
				walker = new ParseTreeWalker();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	@Test
	public void testTheirMethodsContainAssertions() throws TestFailedException {
		walker.walk(jbl, tree);
		
		
		for (String key : Java8Rules.getRules().keySet()) {
			try {
				assertTrue("Method: " + key + " contains no assertions", Java8Rules.getRules().get(key) > 0);
			} catch (AssertionError e) {
				failedTests.add(e.getMessage());
			}
		}
			//throw new TestFailedException(failedTests);
		assertTrue("There were tests with no assertions: "+ failedTests.toString(), failedTests.isEmpty());
	}
}
