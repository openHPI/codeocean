import static org.junit.Assert.*;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

import org.junit.BeforeClass;
import org.junit.Test;

public class MySpecificTest {

	// diese beiden Zeilen bitte nicht anfassen, da wir sie fuer die Vergabe der Punkte verwenden. 
	static Class<CellularAutomaton> ClassToTest;
	private static Constructor<CellularAutomaton> cons;
	
	// hier koennt ihr Referenzen auf benoetigte Automaten wie beispielhaft gezeigt deklarieren, 
	// weiter unten sollen diese Automaten dann von euch instanziiert werden.
	private static CellularAutomaton exampleInstance;
	
	private static CellularAutomaton ex0;               
    private static CellularAutomaton ex1;              
    private static CellularAutomaton ex00;              
    private static CellularAutomaton ex01;              
    private static CellularAutomaton ex10;              
    private static CellularAutomaton ex11;              
    private static CellularAutomaton ex010;             
    private static CellularAutomaton ex100;             
    private static CellularAutomaton ex101;             
    private static CellularAutomaton ex110;             
    private static CellularAutomaton ex0100;            
    private static CellularAutomaton ex1010;            
    private static CellularAutomaton ex1000;            
    private static CellularAutomaton ex1100;            
    private static CellularAutomaton ex10101010;        
    private static CellularAutomaton ex0101010101010101;
	
	@BeforeClass
	public static void setUpBeforeClass() throws NoSuchMethodException, SecurityException, InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException {
		
		// Auch diese Zeile bitte nicht anfassen, hiermit erzeugen wir die benoetigten Automaten
		cons = ClassToTest.getConstructor(String.class);
		
		ex0                = cons.newInstance("0");
		ex1                = cons.newInstance("1");
		ex00               = cons.newInstance("00");
		ex01               = cons.newInstance("01");
		ex10               = cons.newInstance("10");
		ex11               = cons.newInstance("11");
		ex010              = cons.newInstance("010");
		ex100              = cons.newInstance("100");
		ex101              = cons.newInstance("101");
		ex110              = cons.newInstance("110");
		ex0100             = cons.newInstance("0100");
		ex1010             = cons.newInstance("1010");
	    ex1000             = cons.newInstance("1000");
	    ex1100             = cons.newInstance("1100");
	    ex10101010         = cons.newInstance("10101010");
	    ex0101010101010101 = cons.newInstance("0101010101010101");
	}

	// Es soll vor allem die iterate Methode von MyRule54CA getestet werden, 
	// der Konstruktor und die display Methoden muessen fuer die Vergabe der Punkte nicht ueberprueft werden. 
	
	@Test
	public void test01(){
	 	assertEquals("1",ex1.iterate(1).display());
	}
	
	@Test
	public void test02(){
	 	assertEquals("1",ex1.iterate(100).display());
	}
	
	@Test
	public void test03(){
	 	assertEquals("0",ex0.iterate(1).display());
	}

	@Test
	public void test04(){
	 	assertEquals("0",ex0.iterate(100).display());
	}

	@Test
	public void test05(){
	 	assertEquals("1110",ex0100.iterate(1).display());
	}

	@Test
	public void test06(){
	 	assertEquals("1111",ex1010.iterate(1).display());
	}
	
	@Test
	public void test07(){
	 	assertEquals("1100",ex1000.iterate(1).display());
	}

	@Test
	public void test08(){
	 	assertEquals("0010",ex1100.iterate(1).display());
	}
	
	@Test
	public void test09(){
	 	assertEquals("11111111",ex10101010.iterate(1).display());
	}
	
	@Test
	public void test10(){
	 	assertEquals("10101010",ex10101010.iterate(0).display());
	}	
	
	@Test
	public void test11(){
	 	assertEquals("0101010101010101",ex0101010101010101.iterate(0).display());
	}
	
	@Test
	public void test12(){
	 	assertEquals("00",ex11.iterate(1).display());
	}

	@Test
	public void test13(){
	 	assertEquals("00",ex00.iterate(100).display());
	}

	@Test
	public void test14(){
	 	assertEquals("00",ex00.iterate(1).display());
	}
	
	@Test
	public void test15(){
	 	assertEquals("11",ex10.iterate(1).display());
	}	
	
	@Test
	public void test16(){
	 	assertEquals("00",ex11.iterate(100).display());
	}	
	
	@Test
	public void test17(){
	 	assertEquals("111",ex010.iterate(1).display());
	}		
	
	@Test
	public void test18(){
	 	assertEquals("111",ex101.iterate(1).display());
	}		
	
	@Test
	public void test19(){
	 	assertEquals("110",ex100.iterate(1).display());
	}		
	
	@Test
	public void test20(){
	 	assertEquals("001",ex110.iterate(1).display());
	}		

}