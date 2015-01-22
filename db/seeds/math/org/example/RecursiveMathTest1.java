package org.example;

import java.lang.Math.*;
import org.example.RecursiveMath;
import org.junit.*;

public class RecursiveMathTest1 {

    @Test
    public void methodIsDefined() {
        boolean methodIsDefined = false;
        try {
             RecursiveMath.power(1, 1);
             methodIsDefined = true;
        } catch (NoSuchMethodError error) {
            //
        }
        org.junit.Assert.assertTrue("RecursiveMath does not define 'power'.", methodIsDefined);
    }

    @Test
    public void methodReturnsDouble() {
        Object result = RecursiveMath.power(1, 1);
        org.junit.Assert.assertTrue("Your method has the wrong return type.", result instanceof Double);
    }
}
