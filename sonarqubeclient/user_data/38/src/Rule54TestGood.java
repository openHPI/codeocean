import static org.junit.Assert.assertEquals;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

import org.junit.BeforeClass;
import org.junit.Test;

public class Rule54TestGood {
	
	static Class<CellularAutomaton> ClassToTest;
	private static Constructor<CellularAutomaton> cons;
	
	private static CellularAutomaton edgeSingleWrapAlive;
	private static CellularAutomaton edgeSingleWrapDead;
	private static CellularAutomaton edgeSingleNowrapAlive;
	private static CellularAutomaton edgeSingleNowrapDead;
	
	private static CellularAutomaton edgeDoubleWrapAlive;
	private static CellularAutomaton edgeDoubleWrapDead;
	private static CellularAutomaton edgeDoubleNowrapAlive;
	private static CellularAutomaton edgeDoubleNowrapDead;
	private static CellularAutomaton edgeDoubleWrapFirstAlive;
	private static CellularAutomaton edgeDoubleWrapFirstDead;
	private static CellularAutomaton edgeDoubleNowrapFirstAlive;
	private static CellularAutomaton edgeDoubleNowrapFirstDead;
	
	@BeforeClass
	public static void setUpBeforeClass() throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException {
		cons = ClassToTest.getConstructor(String.class, boolean.class);
		
		edgeSingleWrapAlive = cons.newInstance("1", true);
		edgeSingleWrapDead = cons.newInstance("0", true);
		edgeSingleNowrapAlive = cons.newInstance("1", false);
		edgeSingleNowrapDead = cons.newInstance("0", false);
		
		edgeDoubleWrapAlive = cons.newInstance("11", true);
		edgeDoubleWrapDead = cons.newInstance("00", true);
		edgeDoubleNowrapAlive = cons.newInstance("11", false);
		edgeDoubleNowrapDead = cons.newInstance("00", false);
		
		edgeDoubleWrapFirstAlive = cons.newInstance("10", true);
		edgeDoubleWrapFirstDead = cons.newInstance("01", true);
		edgeDoubleNowrapFirstAlive = cons.newInstance("10", false);
		edgeDoubleNowrapFirstDead = cons.newInstance("01", false);
	}

	@Test
	public void test54SingleEdgeComplete() {

		assertEquals("0",(edgeSingleWrapAlive.iterate(1).display()));
		assertEquals("0",(edgeSingleWrapAlive.iterate(100).display()));
		
		assertEquals("0",(edgeSingleWrapDead.iterate(1).display()));
		assertEquals("0",(edgeSingleWrapDead.iterate(100).display()));
		
		assertEquals("1",(edgeSingleNowrapAlive.iterate(1).display()));
		assertEquals("1",(edgeSingleNowrapAlive.iterate(100).display()));
		
		assertEquals("0",(edgeSingleNowrapDead.iterate(1).display()));
		assertEquals("0",(edgeSingleNowrapDead.iterate(100).display()));
	}
	
	@Test
	public void test54DoubleEdgeComplete() {
		
		assertEquals("00",(edgeDoubleWrapAlive.iterate(1).display()));
		assertEquals("00",(edgeDoubleWrapAlive.iterate(100).display()));
		
		assertEquals("00",(edgeDoubleWrapDead.iterate(1).display()));
		assertEquals("00",(edgeDoubleWrapDead.iterate(100).display()));
		
		assertEquals("00",(edgeDoubleNowrapAlive.iterate(1).display()));
		assertEquals("00",(edgeDoubleNowrapAlive.iterate(100).display()));
		
		assertEquals("00",(edgeDoubleNowrapDead.iterate(1).display()));
		assertEquals("00",(edgeDoubleNowrapDead.iterate(100).display()));
		
		assertEquals("11",(edgeDoubleWrapFirstAlive.iterate(1).display()));
		assertEquals("00",(edgeDoubleWrapFirstAlive.iterate(100).display()));
		
		assertEquals("11",(edgeDoubleWrapFirstDead.iterate(1).display()));
		assertEquals("00",(edgeDoubleWrapFirstDead.iterate(100).display()));
		
		assertEquals("11",(edgeDoubleNowrapFirstAlive.iterate(1).display()));
		assertEquals("00",(edgeDoubleNowrapFirstAlive.iterate(100).display()));
		
		assertEquals("11",(edgeDoubleNowrapFirstDead.iterate(1).display()));
		assertEquals("00",(edgeDoubleNowrapFirstDead.iterate(100).display()));
	}
	
	@Test
	public void test54RandomComplete() throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException{
		assertEquals("11111111",(cons.newInstance("10101010", false).iterate(1).display()));
		assertEquals("10101010",(cons.newInstance("10101010", false).iterate(0).display()));
		assertEquals("0101010101010101",(cons.newInstance("0101010101010101", false).iterate(0).display()));
	}
	
	@Test
	public void testDisplay() throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException{
		assertEquals("10101010", cons.newInstance("10101010", false).display());
	}
}
