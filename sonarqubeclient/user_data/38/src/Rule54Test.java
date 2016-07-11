import static org.junit.Assert.*;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

public class Rule54Test {

	private static Rule54CA edgeSingleWrapAlive;
	private static Rule54CA edgeSingleWrapDead;
	private static Rule54CA edgeSingleNowrapAlive;
	private static Rule54CA edgeSingleNowrapDead;
	
	private static Rule54CA edgeDoubleWrapAlive;
	private static Rule54CA edgeDoubleWrapDead;
	private static Rule54CA edgeDoubleNowrapAlive;
	private static Rule54CA edgeDoubleNowrapDead;
	private static Rule54CA edgeDoubleWrapFirstAlive;
	private static Rule54CA edgeDoubleWrapFirstDead;
	private static Rule54CA edgeDoubleNowrapFirstAlive;
	private static Rule54CA edgeDoubleNowrapFirstDead;
	
	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
		edgeSingleWrapAlive = new Rule54CA("1", true);
		edgeSingleWrapDead = new Rule54CA("0", true);
		edgeSingleNowrapAlive = new Rule54CA("1", false);
		edgeSingleNowrapDead = new Rule54CA("0", false);
		
		edgeDoubleWrapAlive = new Rule54CA("11", true);
		edgeDoubleWrapDead = new Rule54CA("00", true);
		edgeDoubleNowrapAlive = new Rule54CA("11", false);
		edgeDoubleNowrapDead = new Rule54CA("00", false);
		
		edgeDoubleWrapFirstAlive = new Rule54CA("10", true);
		edgeDoubleWrapFirstDead = new Rule54CA("01", true);
		edgeDoubleNowrapFirstAlive = new Rule54CA("10", false);
		edgeDoubleNowrapFirstDead = new Rule54CA("01", false);
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
	public void test54RandomComplete(){
		assertEquals("11111111",(new Rule54CA("10101010", false).iterate(1).display()));
		assertEquals("10101010",(new Rule54CA("10101010", false).iterate(0).display()));
		assertEquals("0101010101010101",(new Rule54CA("0101010101010101", false).iterate(0).display()));
	}
	
	@Test
	public void testDisplay(){
		assertEquals("10101010", new Rule54CA("10101010", false).display());
	}
}
