import static org.junit.Assert.*;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

public class TestSpecificRuns {

	private static MyRule54CA edgeSingleWrapAlive;
	private static MyRule54CA edgeSingleWrapDead;
	private static MyRule54CA edgeSingleNowrapAlive;
	private static MyRule54CA edgeSingleNowrapDead;
	
	private static MyRule54CA edgeDoubleWrapAlive;
	private static MyRule54CA edgeDoubleWrapDead;
	private static MyRule54CA edgeDoubleNowrapAlive;
	private static MyRule54CA edgeDoubleNowrapDead;
	private static MyRule54CA edgeDoubleWrapFirstAlive;
	private static MyRule54CA edgeDoubleWrapFirstDead;
	private static MyRule54CA edgeDoubleNowrapFirstAlive;
	private static MyRule54CA edgeDoubleNowrapFirstDead;
	
	private static CellularAutomaton triple1;
	private static CellularAutomaton triple2;
	private static CellularAutomaton triple3;
	private static CellularAutomaton triple4;

	private static CellularAutomaton quad1;
	private static CellularAutomaton quad2;
	private static CellularAutomaton quad3;
	private static CellularAutomaton quad4;

	private static CellularAutomaton moreTests1;
	private static CellularAutomaton moreTests2;
	private static CellularAutomaton moreTests3;

	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
		edgeSingleNowrapAlive = new MyRule54CA("1");
		edgeSingleNowrapDead = new MyRule54CA("0");
		

		edgeDoubleNowrapAlive = new MyRule54CA("11");
		edgeDoubleNowrapDead = new MyRule54CA("00");
		

		edgeDoubleNowrapFirstAlive = new MyRule54CA("10");
		edgeDoubleNowrapFirstDead = new MyRule54CA("01");

		triple1 = new MyRule54CA("010");
		triple2 = new MyRule54CA("101");
		triple3 = new MyRule54CA("100");
		triple4 = new MyRule54CA("110");

		quad1 = new MyRule54CA("0100");
		quad2 = new MyRule54CA("1010");
		quad3 = new MyRule54CA("1000");
		quad4 = new MyRule54CA("1100");

		moreTests1 = new MyRule54CA("10101010");
		moreTests2 = new MyRule54CA("10101010");
		moreTests3 = new MyRule54CA("0101010101010101");
	}

	@Test
	public void test54SingleEdgeComplete() {
		
		assertEquals("1",(edgeSingleNowrapAlive.iterate(1).display()));
		assertEquals("1",(edgeSingleNowrapAlive.iterate(100).display()));
		
		assertEquals("0",(edgeSingleNowrapDead.iterate(1).display()));
		assertEquals("0",(edgeSingleNowrapDead.iterate(100).display()));
	}
	
	@Test
	public void test54DoubleEdgeComplete() {
		
		
		assertEquals("00",(edgeDoubleNowrapAlive.iterate(1).display()));
		assertEquals("00",(edgeDoubleNowrapAlive.iterate(100).display()));
		
		assertEquals("00",(edgeDoubleNowrapDead.iterate(1).display()));
		assertEquals("00",(edgeDoubleNowrapDead.iterate(100).display()));
	
		
		assertEquals("11",(edgeDoubleNowrapFirstAlive.iterate(1).display()));
		assertEquals("00",(edgeDoubleNowrapFirstAlive.iterate(100).display()));
		
		assertEquals("11",(edgeDoubleNowrapFirstDead.iterate(1).display()));
		assertEquals("00",(edgeDoubleNowrapFirstDead.iterate(100).display()));
	}
	
		@Test
	public void test54TripleRandom() {
		
		// Some tests for 3 celled CA (but not exhaustive)
		assertEquals("111",(triple1.iterate(1).display()));
		assertEquals("111",(triple2.iterate(1).display()));
		assertEquals("110",(triple3.iterate(1).display()));
		assertEquals("001",(triple4.iterate(1).display()));
	}
	
	@Test
	public void test54QuadRandom() {

		// Some tests for 4 celled CA (but not exhaustive)
		assertEquals("1110",(quad1.iterate(1).display()));
		assertEquals("1111",(quad2.iterate(1).display()));
		assertEquals("1100",(quad3.iterate(1).display()));
		assertEquals("0010",(quad4.iterate(1).display()));
	}

	@Test
	public void test54RandomComplete(){
		assertEquals("11111111",(moreTests1.iterate(1).display()));
		assertEquals("10101010",(moreTests2.iterate(0).display()));
		assertEquals("0101010101010101",(moreTests3.iterate(0).display()));
	}
}