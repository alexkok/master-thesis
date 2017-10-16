module valuegenerator::SimpleValuesGenerator

// Project imports
// Dependency imports
// Rebel imports
import lang::CommonSyntax;
// Rascal imports
import List;
import ParseTree;
import String;
import util::Math;
import IO;

public list[list[Expr]] genTestValues(str eventName, int amount) {
    list[list[Expr]] valueList = [];
    for (int i <- [0..amount]) {
        valueList += [genTestValueForEvent(eventName)];
    }
    return valueList;
}

private real genRandomInteger(int min = -999, int max = 999) {
    return toReal(getOneFrom([min..max]));
}

private real genRandomDouble(real min = -999.00, real max = 999.00) {
    real selectedValue = getOneFrom([min..max]);
    real selectedDenom = toReal("0.<getOneFrom([10..100])>");
    return toReal("<selectedValue+selectedDenom>");
}

private Expr genRandomMoney(str currency = genRandomCurrency(), real min2 = -999.00, real max2 = 9999.00) {
    val = genRandomDouble(min = min2, max = max2);
    return convertToMoney(currency, val);
}

private str genRandomCurrency() {
    return getOneFrom(["EUR", "USD"]); // TODO: Only EUR and USD supported currently
}

private Expr converToExpr(real amount) {
    str tostring = "<amount>";
    return parse(#Expr, "<substring(tostring, 0, size(tostring)-1)>");
}

private Expr convertToMoney(str currency, real amount) {
    str parseValue;
    // TODO: Only EUR for now
    if (amount < 0) {
        parseValue = "- <currency> <abs(amount)>";
    } else {
        parseValue = "<currency> <amount>";
    }
    return parse(#Expr, parseValue);
}

// Event specifics
// Generating
private list[Expr] genTestValueForEvent("Symmetric") {
    Expr moneyValue = genRandomMoney();
    return [moneyValue, moneyValue];
}

private list[Expr] genTestValueForEvent("TransitiveEquality") {
    Expr moneyValue = genRandomMoney();
    return [moneyValue, moneyValue, moneyValue];
}

private list[Expr] genTestValueForEvent("TransitiveInequalityLT") {
    real moneyAmountX = genRandomDouble();
    real moneyAmountY = genRandomDouble(min = moneyAmountX);
    // Force Y to be > X
    while (moneyAmountX >= moneyAmountY) {
        println("Oops! (X \>= Y): <moneyAmountX> \>= <moneyAmountY> | Generating new random value");
        moneyAmountY = genRandomDouble(min = moneyAmountX);
    }
    real moneyAmountZ = genRandomDouble(min = moneyAmountY);
    // Force Z to be > y
    while (moneyAmountY >= moneyAmountZ) {
        println("Oops! (Y \>= Z): <moneyAmountY> \>= <moneyAmountZ> | Generating new random value");
        moneyAmountZ = genRandomDouble(min = moneyAmountY);
    }
    str currency = genRandomCurrency();
    return [convertToMoney(currency, moneyAmountX), convertToMoney(currency, moneyAmountY), convertToMoney(currency, moneyAmountZ)];
}

private list[Expr] genTestValueForEvent("TransitiveInequalityGT") {
    real moneyAmountX = genRandomDouble();
    real moneyAmountY = genRandomDouble(max = moneyAmountX);
    // Force Y to be < X
    while (moneyAmountX < moneyAmountY) {
        println("Oops! (X \< Y): <moneyAmountX> \< <moneyAmountY> | Generating new random value");
        moneyAmountY = genRandomDouble(max = moneyAmountX);
    }
    real moneyAmountZ = genRandomDouble(max = moneyAmountY);
    // Force Z to be < Y
    while (moneyAmountY < moneyAmountZ) {
        println("Oops! (Y \< Z): <moneyAmountY> \< <moneyAmountZ> | Generating new random value");
        moneyAmountZ = genRandomDouble(max = moneyAmountY);
    }
    str currency = genRandomCurrency();
    return [convertToMoney(currency, moneyAmountX), convertToMoney(currency, moneyAmountY), convertToMoney(currency, moneyAmountZ)];
}

private list[Expr] genTestValueForEvent("TransitiveInequalityLET") {
    real moneyAmountX = genRandomDouble();
    real moneyAmountY = genRandomDouble(min = moneyAmountX);
    // Force Y to be >= X
    while (moneyAmountX > moneyAmountY) {
        println("Oops! (X \> Y): <moneyAmountX> \> <moneyAmountY> | Generating new random value");
        moneyAmountY = genRandomDouble(min = moneyAmountX);
    }
    real moneyAmountZ = genRandomDouble(min = moneyAmountY);
    // Force Z to be >= y
    while (moneyAmountY > moneyAmountZ) {
        println("Oops! (Y \> Z): <moneyAmountY> \> <moneyAmountZ> | Generating new random value");
        moneyAmountZ = genRandomDouble(min = moneyAmountY);
    }
    str currency = genRandomCurrency();
    return [convertToMoney(currency, moneyAmountX), convertToMoney(currency, moneyAmountY), convertToMoney(currency, moneyAmountZ)];
}

private list[Expr] genTestValueForEvent("TransitiveInequalityGET") {
    real moneyAmountX = genRandomDouble();
    real moneyAmountY = genRandomDouble(max = moneyAmountX);
    // Force Y to be <= X
    while (moneyAmountX < moneyAmountY) {
        println("Oops! (X \< Y): <moneyAmountX> \< <moneyAmountY> | Generating new random value");
        moneyAmountY = genRandomDouble(max = moneyAmountX);
    }
    real moneyAmountZ = genRandomDouble(max = moneyAmountY);
    // Force Z to be <= Y
    while (moneyAmountY < moneyAmountZ) {
        println("Oops! (Y \< Z): <moneyAmountY> \< <moneyAmountZ> | Generating new random value");
        moneyAmountZ = genRandomDouble(max = moneyAmountY);
    }
    str currency = genRandomCurrency();
    return [convertToMoney(currency, moneyAmountX), convertToMoney(currency, moneyAmountY), convertToMoney(currency, moneyAmountZ)];
}

private list[Expr] genTestValueForEvent("Additive") {
    str cur = genRandomCurrency();
    Expr moneyValueXY = genRandomMoney(currency = cur);
    Expr moneyValueZ = genRandomMoney(currency = cur);
    return [moneyValueXY, moneyValueXY, moneyValueZ];
}

private list[Expr] genTestValueForEvent("Additive4params") {
    str cur = genRandomCurrency();
    Expr moneyValueXY = genRandomMoney(currency = cur);
    Expr moneyValueZA = genRandomMoney(currency = cur);
    return [moneyValueXY, moneyValueXY, moneyValueZA, moneyValueZA];
}

private list[Expr] genTestValueForEvent("AntisymmetryLET") {
    Expr moneyValue = genRandomMoney();
    return [moneyValue, moneyValue];
}

private list[Expr] genTestValueForEvent("AntisymmetryGET") {
    Expr moneyValue = genRandomMoney();
    return [moneyValue, moneyValue];
}

private list[Expr] genTestValueForEvent("Division1") {
    real moneyAmountX = genRandomDouble();
    real intAmountY = genRandomInteger();
    real moneyAmountZ = moneyAmountX * intAmountY;
    str currency = genRandomCurrency();
    return [convertToMoney(currency, moneyAmountX), converToExpr(intAmountY), convertToMoney(currency, moneyAmountZ)];
}

private list[Expr] genTestValueForEvent("Division2") {
    real moneyAmountZ = genRandomDouble();
    real intAmountY = genRandomInteger();
    real moneyAmountX = moneyAmountZ * intAmountY;
    str currency = genRandomCurrency();
    return [convertToMoney(currency, moneyAmountX), converToExpr(intAmountY), convertToMoney(currency, moneyAmountZ)];
}

// Fallback: throw exception
private default list[Expr] genTestValueForEvent(str eventName) {
    throw "genTestValueForEvent not implemented for event <eventName>";
}