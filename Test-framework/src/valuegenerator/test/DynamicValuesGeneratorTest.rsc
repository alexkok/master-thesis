module valuegenerator::\test::DynamicValuesGeneratorTest

// Project imports
import valuegenerator::DynamicValuesGenerator;
// Dependency imports
// Rebel imports
import lang::ExtendedSyntax;
// Rascal imports
import IO;
import ParseTree;
import String;
import List;
import util::Math;

private int TEST_TRIES = 100; // Done with 1000, but that takes a while

public test bool testPreconditionContainingParenthesis() {
    str eventString = "event someEvent(x: Money, y: Money) {
        preconditions {
            (x) == (y);
        }
        postconditions {
           new this.result == True;
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 2) : "Expecting 2 params";
        assert(valueTuple[0] == valueTuple[1]) : "Values should be equal to each other";
    }
    return true; // When assertions pass, return true
}

public test bool testPreconditionContainingFunction() {
    str eventString = "event someEvent(x: Money, y: Money) {
        preconditions {
            round(x) == round(y);
        }
        postconditions {
           new this.result == True;
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 2) : "Expecting 2 params";
        assert(valueTuple[0] == valueTuple[1]) : "Values should be equal to each other";
    }
    return true; // When assertions pass, return true
}

public test bool testPreconditionExpressionNoZero() {
    str eventString = "event someEvent(x: Money, y: Money, z: Money) {
        preconditions {
            x*y == z;
        }
        postconditions {
           new this.result == True;
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 3) : "Expecting 3 params";
        assert(convertToReal(valueTuple[0]) != 0.0) : "Value cannot be zero, as precondition uses it in expression";
        assert(convertToReal(valueTuple[1]) != 0.0) : "Value cannot be zero, as precondition uses it in expression";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForTransitiveEquality() {
    str eventString = "event transitiveEquality(x: Money, y: Money, z: Money) {
        preconditions {
            x == y;
            y == z;
        }
        postconditions {
           new this.result == ( (x == y && y == z) ? x == z : False );
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 3) : "TransitiveEquality uses 3 params";
        assert(valueTuple[0] == valueTuple[1] && valueTuple[1] == valueTuple[2]) : "Values should be equal to each other";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForAdditive4params() {
    str eventString = "event additive4params(x: Money, y: Money, z: Money, a: Money) {
        preconditions {
            x == y;
            z == a;
        }
        postconditions {
            new this.result == ( (x == y && z == a) ? x+z == y+a : False );
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 4) : "Additive4params uses 4 params";
        assert(valueTuple[0] == valueTuple[1]) : "X should be equal to Y";
        assert(valueTuple[2] == valueTuple[3]) : "Z should be equal to A";    
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForDivision1() {
    str eventString = "event division1(x: Money, y: Integer, z: Money) {
        preconditions {
            x*y == z;
        }
        postconditions {
            new this.result == ( (x*y == z) ? (x == z/y) : False ); // Check if braces are necessary
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 3) : "Division1 uses 3 params";
        assert(convertToReal(valueTuple[0])*convertToReal(valueTuple[1]) == convertToReal(valueTuple[2])) : "Precondition should hold";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForDivision2() {
    str eventString = "event division2(x: Money, y: Integer, z: Money) {
        preconditions {
            x == z*y;
        }
        postconditions {
            new this.result == ( (x == z*y) ? (x/y == z) : False ); // Check if braces are necessary
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 3) : "Division2 uses 3 params";
        assert(convertToReal(valueTuple[0]) == convertToReal(valueTuple[1])*convertToReal(valueTuple[2])) : "Precondition should hold";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForTransitiveInequalityLT() {
    str eventString = "event transitiveInequalityLT(x: Money, y: Money, z: Money) {
        preconditions {
            x \< y;
            y \< z;
        }
        postconditions {
           new this.result == ( (x \< y && y \< z) ? x \< z : False );
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 3) : "TransitiveInequalityLT uses 3 params";
        assert(convertToReal(valueTuple[0]) < convertToReal(valueTuple[1]) && convertToReal(valueTuple[1]) < convertToReal(valueTuple[2])) : "Values should be LT each other. Values: <valueTuple[0]> <valueTuple[1]> <valueTuple[2]>";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForTransitiveInequalityLET() {
    str eventString = "event transitiveInequalityLET(x: Money, y: Money, z: Money) {
        preconditions {
            x \<= y;
            y \<= z;
        }
        postconditions {
           new this.result == ( (x \<= y && y \<= z) ? x \<= z : False );
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 3) : "TransitiveInequalityLET uses 3 params";
        assert(convertToReal(valueTuple[0]) <= convertToReal(valueTuple[1]) && convertToReal(valueTuple[1]) <= convertToReal(valueTuple[2])) : "Values should be LET each other. Values: <valueTuple[0]> <valueTuple[1]> <valueTuple[2]>";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForTransitiveInequalityGT() {
    str eventString = "event transitiveInequalityGT(x: Money, y: Money, z: Money) {
        preconditions {
           x \> y;
           y \> z;
        }
        postconditions {
           new this.result == ( (x \> y && y \> z) ? x \> z : False );
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 3) : "TransitiveInequalityGT uses 3 params";
        assert(convertToReal(valueTuple[0]) > convertToReal(valueTuple[1]) && convertToReal(valueTuple[1]) > convertToReal(valueTuple[2])) : "Values should be GT each other. Values: <valueTuple[0]> <valueTuple[1]> <valueTuple[2]>";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForTransitiveInequalityGET() {
    str eventString = "event transitiveInequalityGET(x: Money, y: Money, z: Money) {
        preconditions {
            x \>= y;
            y \>= z;
        }
        postconditions {
           new this.result == ( (x \>= y && y \>= z) ? x \>= z : False );
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 3) : "TransitiveInequalityGET uses 3 params";
        assert(convertToReal(valueTuple[0]) >= convertToReal(valueTuple[1]) && convertToReal(valueTuple[1]) >= convertToReal(valueTuple[2])) : "Values should be GET each other. Values: <valueTuple[0]> <valueTuple[1]> <valueTuple[2]>";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForAntisymmetryLET() {
    str eventString = "event antisymmetryLET(x: Money, y: Money) {
        preconditions {
            x \<= y;
            y \<= x;
        }
        postconditions {
            new this.result == ( (x \<= y && y \<= x) ? x == y : False );
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 2) : "AntisymmetryLET uses 2 params";
        assert(convertToReal(valueTuple[0]) == convertToReal(valueTuple[1])) : "Values should be LET each other. Values: <valueTuple[0]> <valueTuple[1]>";
    }
    return true; // When assertions pass, return true
}

public test bool testValuesForAntisymmetryGET() {
    str eventString = "event antisymmetryGET(x: Money, y: Money) {
        preconditions {
            x \>= y;
            y \>= x;
        }
        postconditions {
            new this.result == ( (x \>= y && y \>= x) ? x == y : False );
        }
    }";
    
    list[list[Expr]] generatedValues = generateValuesFromEventString(eventString, TEST_TRIES);
    for (list[Expr] valueTuple <- generatedValues) {
        assert(size(valueTuple) == 2) : "AntisymmetryGET uses 2 params";
        assert(convertToReal(valueTuple[0]) == convertToReal(valueTuple[1])) : "Values should be GET each other. Values: <valueTuple[0]> <valueTuple[1]>";
    }
    return true; // When assertions pass, return true
}

// Utility
private list[list[Expr]] generateValuesFromEventString(str eventString, int amount) {    
    EventDef eventDef = parse(#EventDef, eventString);
    list[Parameter] paramsStar = [p | Parameter p <- eventDef.transitionParams]; // Workaround
    
    generatedValues = genValues("<eventDef.name>", eventDef.pre, paramsStar, amount, shouldPrint=true);
    assert(size(generatedValues) == amount) : "Size should be equal to requested amount";
    return generatedValues;
}

// Convert type back to value, to use for calculations again
private real convertToReal((Expr)`<Money m>`) = toReal("<m.amount>");
private real convertToReal((Expr)`-<Money m>`) = toReal("-<m.amount>");
private real convertToReal((Expr)`<Int i>`) = toReal("<i>");
private real convertToReal((Expr)`-<Int i>`) = toReal("-<i>");
private real convertToReal(Expr e) {
    throw "Not implemented | convertToReal() not implemented for expression: <e>";
}
