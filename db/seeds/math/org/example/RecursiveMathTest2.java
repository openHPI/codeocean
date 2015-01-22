package org.example;

import java.lang.Math.*;
import org.example.RecursiveMath;
import org.junit.*;

public class RecursiveMathTest2 {

    @Test
    public void exponentZero() {
        org.junit.Assert.assertEquals("Incorrect result for exponent 0.", 1, RecursiveMath.power(42, 0), 0);
    }

    @Test
    public void negativeExponent() {
        org.junit.Assert.assertEquals("Incorrect result for exponent -1.", Math.pow(2, -1), RecursiveMath.power(2, -1), 0);
    }

    @Test
    public void positiveExponent() {
        org.junit.Assert.assertEquals("Incorrect result for exponent 4.", Math.pow(2, 4), RecursiveMath.power(2, 4), 0);
    }
}
