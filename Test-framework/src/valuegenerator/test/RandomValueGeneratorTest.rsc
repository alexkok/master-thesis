module valuegenerator::\test::RandomValueGeneratorTest

// Project imports
import valuegenerator::RandomValueGenerator;
// Dependency imports
// Rebel imports
import lang::ExtendedSyntax;
// Rascal imports
import IO;
import ParseTree;
import String;
import List;
import util::Math;

private int TEST_TRIES = 1000;

public test bool testIntegerGenerator_excludeMax() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomInteger(0.0, 1.0);
        assert(result == 0) : "Max is excluding with Integer, so result should be 0. Was: <result>";
    }
    return true;
}

public test bool testIntegerGenerator_returnOnEqual() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomInteger(1.0, 1.0);
        assert(result == 1) : "Equal values thrown in, expecting same value. Result was <result>";
    }
    return true;
}

public test bool testIntegerGenerator_returnOnEqualIgnoreDecimal() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomInteger(0.0, 0.5);
        assert(result == 0) : "Equal values thrown in, expecting same value. Result was <result>";
    }
    return true;
}

public test bool testIntegerGenerator_returnNonZero() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomInteger(0.0, 2.0, false);
        assert(result != 0) : "Not allowing a zero value. Result was <result>";
    }
    return true;
}

public test bool testDoubleGenerator_returnNonZero() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.0, 1.0, false);
        assert(result != 0.0) : "Equal values thrown in, expecting same value. Result was <result>";
    }
    return true;
}

public test bool testDoubleGenerator_returnDecimal() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.01, 1.0, false);
        assert(result >= 0.01) : "Expecting \>= 0.01. Result was <result>";
        assert(result <= 1.0) : "Expecting \<= 1. Result was <result>";
    }
    return true;
}

public test bool testDoubleGenerator_returnOnEqual() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(1.0, 1.0);
        assert(result == 1) : "Equal values thrown in, expecting same value. Result was <result>";
    }
    return true;
}

public test bool testDoubleGenerator_allowEqualIntegerPart() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(1.0, 1.01);
        assert(result == 1.0 || result == 1.01) : "Expecting value 1.0 or 1.01";
    }
    return true;
}

public test bool testDoubleGenerator_includeMaxWhole() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.0, 1.0);
        assert(result >= 0) : "Result was: <result>"; 
        assert(result <= 1) : "Result was: <result>";
    }
    return true;
}

public test bool testDoubleGenerator_includeMaxOneDecimal() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.0, 0.1);
        assert(result >= 0) : "Result was: <result>";
        assert(result <= 0.1) : "Result was: <result>";
    }
    return true;
}

public test bool testDoubleGenerator_includeMaxTwoDecimal() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.0, 0.99);
        assert(result >= 0) : "Result was: <result>";
        assert(result <= 0.99) : "Result was: <result>";
    }
    return true;
}

public test bool testDoubleGenerator_smallerOrEqual() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.0, 0.99);
        real result2 = genRandomDouble(result, 1.00);
        
        assert(result <= result2) : "Result was: <result>, <result2>";
    }
    return true;
}

public test bool testDoubleGenerator_twoDecimalWithTenOff() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.10, 2.00);
        
        assert(result >= 0.10) : "Result was: <result>";
        assert(result <= 2.00) : "Result was: <result>";
    }
    return true;
}

public test bool testDoubleGenerator_minCorner() {    
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.99, 2.00);
        
        assert(result >= 0.99) : "Result was: <result>";
        assert(result <= 2.00) : "Result was: <result>";
    }
    return true;
}

public test bool testDoubleGenerator_secondDecimalPrecision() {   
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(0.00, 0.05);
        
        assert(result >= 0.00) : "Result was: <result>";
        assert(result <= 0.05) : "Result was: <result>";
    }
    return true;
}

public test bool testDoubleGenerator_negativeCorner() {
    for (int i <- [0..TEST_TRIES]) {
        real result = genRandomDouble(-0.01, 0.00);
        
        assert(result >= -0.01) : "Result was: <result>";
        assert(result <= 0.00) : "Result was: <result>";
    }
    return true;
}