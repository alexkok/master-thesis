module valuegenerator::DynamicValuesGenerator

// Project imports
import valuegenerator::RandomValueGenerator;
// Dependency imports
// Rebel imports
import lang::ExtendedSyntax;
// Rascal imports
import IO;
import ParseTree;
import List;
import String;
import util::Math;

/*
 * For each precondition
 *  L==R :
 *       - if L=lit, calc R and result = L
 *       - if R=lit, calc L and result = R // Not a case for this, but flipping should work
 *  L<R  : 
 *       - if L=lit, calc R and result = [max=R-1]
 *       - if R=lit, calc L and result = [min=L+1]
 *  L<=R :
 *       - if L=lit, calc R and result = [max=R]
 *       - if R=lit, calc L and result = [min=L]
 */

// [varname, Maybe(value), randomProps]
map[str varName, RandomValueProps randomValueProps] paramGenData = ();
map[str varName, real val] calculatedParams = ();

// Compatibility function
public list[list[Expr]] genValues(str eventName, Preconditions? preconditions, Parameter* transitionParams, int amount, bool shouldPrint=false) {
    list[Parameter] transitionParamsList = [p | Parameter p <- transitionParams];
    return genValues(eventName, preconditions, transitionParamsList, amount, shouldPrint);
}

public list[list[Expr]] genValues(str eventName, Preconditions? preconditions, list[Parameter] transitionParams, int amount, bool shouldPrint=false) {
    //println("\> Generating values for event <eventName>");
    
    // Generate
    list[list[Expr]] valueList = [];
    
    for (int i <- [0..amount]) {
        calculatedParams = (); // Clear old data
        paramGenData = ("<p.name>" : <p.tipe, -999999.00, 999999.00, true> | p <- transitionParams);
        
        // Calculating
        for(/Statement s <- preconditions) {
            <lhs, rhs, operator> = extractStatementData(s.expr);
            handleConditionStatement(operator, lhs, rhs);
        }
        
        // Rewrite the variables put in the map with parenthesis such that these are being seen as vars again
        // (Not very neat, but fixes the issue for now)
        for (str varName <- paramGenData, paramGenData["(<varName>)"]?) {
            paramGenData["<p.name>"] = paramGenData["(<p.name>)"];
        }
        for (Parameter p <- transitionParams, calculatedParams["(<p.name>)"]?) {
            calculatedParams["<p.name>"] = calculatedParams["(<p.name>)"];
        }
        // Check whether all are determined, if not, determine those using the randomValueProps data
        for (Parameter p <- transitionParams, !calculatedParams["<p.name>"]?) {
            calculatedParams["<p.name>"] = calculateExpression(p.name);
        }
        
        // Add to list
        valueList += [[getExprForVar("<p.name>") | p <- transitionParams]];
    }
    if (shouldPrint) {
        for(list[Expr] varPair <- valueList) {
            println(["<e>" | e <- varPair]);
        }
    }
    return valueList;
}

private tuple[Expr, Expr, str] extractStatementData((Expr)`<Expr lhs> == <Expr rhs>`) = <lhs, rhs, "==">;
private tuple[Expr, Expr, str] extractStatementData((Expr)`<Expr lhs> != <Expr rhs>`) = <lhs, rhs, "!=">;
private tuple[Expr, Expr, str] extractStatementData((Expr)`<Expr lhs> \< <Expr rhs>`) = <lhs, rhs, "\<">;
private tuple[Expr, Expr, str] extractStatementData((Expr)`<Expr lhs> \> <Expr rhs>`) = <lhs, rhs, "\>">;
private tuple[Expr, Expr, str] extractStatementData((Expr)`<Expr lhs> \<= <Expr rhs>`) = <lhs, rhs, "\<=">;
private tuple[Expr, Expr, str] extractStatementData((Expr)`<Expr lhs> \>= <Expr rhs>`) = <lhs, rhs, "\>=">;
private tuple[Expr, Expr, str] extractStatementData(Expr e) {
     throw "extractStatementData() | Not implemented for <e>";
}

private void handleConditionStatement("==", Expr lhs, Expr rhs) {
    //println("  - Expression type: \'Equality\' (==)");
    // Unsupported things:
    // - preconditions: x == y; y == z*a // y in second case would be overwritten. Turning them around should work though. 
    // - (But we do not need to support this for now)
    // - A way to fix it would be to order the statements or to check the dependencys of expressions. But not required now.
    // - In case this happens, we throw an exception with an "unsupported" message.
    
    str lhsStr = "<lhs>";
    str rhsStr = "<rhs>";
    
    if (calculatedParams[lhsStr]? || calculatedParams[rhsStr]?) {
        // If both known, nothing to calculate. Report & return // Won't happen currently though
        // In case one of them is known and the other one is a var, its the same
        //                              and the other one is an expr > Unsupported
        if (calculatedParams[lhsStr]? && calculatedParams[rhsStr]?) {
            println("  - Already calculated \'<lhs>\' and \'<rhs>\', skipping");
        } else if (calculatedParams[lhsStr]?) {
            // Right is unknown
            if (isVariableName(rhs)) {
                //println("  - RightHandSide known, copying to LeftHandSide");
                calculatedParams[rhsStr] = calculatedParams[lhsStr]; // Copy 
            } else {
                throw "Unsupported | Cannot solve an expression equal to known value (1)";
            }
        } else {
            // Left is unknown
            if (isVariableName(lhs)) {
                //println("  - LeftHandSide known, copying to RightHandSide");
                calculatedParams[lhsStr] = calculatedParams[rhsStr]; // Copy 
            } else {
                throw "Unsupported | Cannot solve an expression equal to known value (2)";
            }
        }
    } else {
        // Else both unknown, check if contains expression.
        if (!isVariableName(lhs) || !isVariableName(rhs)) {
            if (!isVariableName(lhs) && !isVariableName(rhs)) {
                // If both expressions:
                if (startsWith(lhsStr, "round") && startsWith(rhsStr, "round")) {
                    //   If only our round method, remove it and continue without it
                    //println("  - Detected round functions on both sides, removing it and continuing");
                    handleConditionStatement("==", removeRoundFromExpr(lhs), removeRoundFromExpr(rhs));
                } else {
                    //   Else throw exception, unsupported!
                    throw "Unsupported | Cannot make two expressions equal to each other";
                }
            } else if (isVariableName(lhs)) {
                // Left is variable, calculate right and result is used as left value.
                //println("  - LeftHandSide is var, calculating expression on left. Result == LeftHandSide");
                real result = calculateExpression(rhs);
                calculatedParams[lhsStr] = result;   
            } else {
                // Right is variable, calculate left and result is used as right value.
                //println("  - RightHandSide is var, calculating expression on right. Result == RightHandSide");
                real result = calculateExpression(lhs);
                calculatedParams[rhsStr] = result;
            }
        } else {
            // Not, calc var and other is the same
            //println("  - Doesn\'t contain expression, calculating left and copying to right");
            calculatedParams[lhsStr] = calculateExpression(lhs);
            calculatedParams[rhsStr] = calculatedParams[lhsStr];
        }
    }
}

private void handleConditionStatement("!=", Expr lhs, Expr rhs) { 
    //println("  - Expression type: \'Not equality\' (!=)");
    if ("<rhs>" == "0") {
        paramGenData["<lhs>"].allowZero = false;
    } else {
        throw "Not supporting unequality (!=) operation on: <lhs>  and  <rhs>";
    }
}

private void handleConditionStatement("\<", Expr lhs, Expr rhs) {
    //println("  - Expression type: \'Less Than\' (\<)");
    handleStatementsUsingSmaller(lhs, rhs, false);
}

private void handleConditionStatement("\<=", Expr lhs, Expr rhs) {
    //println("  - Expression type: \'Less or Equal Than\' (\<=)");
    handleStatementsUsingSmaller(lhs, rhs, true);
}

private void handleStatementsUsingSmaller(Expr lhs, Expr rhs, bool allowEqual) {
    // Unsupported things:
    // - Doesn't support expressions, only variables. Throwing an exception when this might happen.
    // - Doesn't fully support min/max race conditions when using integers, as it now does an increase or decrease with 0.01 if needed. With integers this should be 1.
    
    str lhsStr = "<lhs>";
    str rhsStr = "<rhs>";
    
    if (calculatedParams[lhsStr]? || calculatedParams[rhsStr]?) {
        // If both known, nothing to calculate. Report & return // Won't happen currently though
        // In case one of them is known and the other one is a var, update value props 'min' or 'max'
        //                              and the other one is an expr > Unsupported
        if (calculatedParams[lhsStr]? && calculatedParams[rhsStr]?) {
            println("  - Already calculated \'<lhs>\' and \'<rhs>\', skipping");
        } else if (calculatedParams[rhsStr]?) {
            // Right is known
            // Left is unknown
            if (isVariableName(rhs)) {
                //println("  - RightHandSide known, LeftHandSide max = RightHandSide");
                paramGenData[lhsStr].max = calculatedParams[rhsStr] - ((allowEqual) ? 0 : 0.01); 
            } else {
                throw "Unsupported | Cannot solve an expression less than (or equal) a known value (1)";
            }
        } else {
            // Left is known
            // Right is unknown
            if (isVariableName(lhs)) {
                //println("  - LeftHandSide known, RightHandSide min = LeftHandSide");
                paramGenData[rhsStr].min = calculatedParams[lhsStr] + ((allowEqual) ? 0 : 0.01);
                // Increase max if needed
                increaseMaxIfNeeded(rhsStr);
            } else {
                throw "Unsupported | Cannot solve an expression less than (or equal) a known value (2)";
            }
        }
    } else {
        // Else both unknown, check if contains expression.
        if (!isVariableName(lhs) || !isVariableName(rhs)) {
            // check if rhs is literal zero (0)
            if (rhsStr == "0") {
                // Tactic: Right is known
                //println("  - Both expressions. Detected literal 0. Thus: RightHandSide known, LeftHandSide max = RightHandSide (0)");
                paramGenData[lhsStr].max = 0 /* <-- the value 0 */ - ((allowEqual) ? 0 : 0.01);
            } else {
                // else throw exception, unsupported!
                throw "Unsupported | Cannot solve expressions when using Less Than (\<) Or Equal (\<=). <lhs>  |  <rhs>";
            }
            // Could be extended later, such that max would be the calculated value. But not needed currently
        } else {
            // Not, calc var and other is the same
            //println("  - Doesn\'t contain expression, calculating left. RightHandSide min = LeftHandSide");
            calculatedParams[lhsStr] = calculateExpression(lhs);
            paramGenData[rhsStr].min = calculatedParams[lhsStr] + ((allowEqual) ? 0 : 0.01);
            // Increase max if needed
            increaseMaxIfNeeded(rhsStr);
        }
    }
}

private void handleConditionStatement("\>", Expr lhs, Expr rhs) {
    //println("  - Expression type: \'Greater Than\' (\>)");
    handleStatementsUsingGreater(lhs, rhs, false);
}

private void handleConditionStatement("\>=", Expr lhs, Expr rhs) {
    //println("  - Expression type: \'Greater or Equal Than\' (\>=)");
    handleStatementsUsingGreater(lhs, rhs, true);
}

private void handleStatementsUsingGreater(Expr lhs, Expr rhs, bool allowEqual) {
    // * Note, this one is kinda similar as the one from smaller, but it swaps the max and min assignments. Might merge this later on
    // Unsupported things:
    // - Doesn't support expressions, only variables. Throwing an exception when this might happen.
    // - Doesn't fully support min/max race conditions when using integers, as it now does an increase or decrease with 0.01 if needed. With integers this should be 1.
    
    str lhsStr = "<lhs>";
    str rhsStr = "<rhs>";
    
    if (calculatedParams[lhsStr]? || calculatedParams[rhsStr]?) {
        // If both known, nothing to calculate. Report & return // Won't happen currently though
        // In case one of them is known and the other one is a var, update value props 'min' or 'max'
        //                              and the other one is an expr > Unsupported
        if (calculatedParams[lhsStr]? && calculatedParams[rhsStr]?) {
            println("  - Already calculated \'<lhs>\' and \'<rhs>\', skipping");
        } else if (calculatedParams[rhsStr]?) {
            // Right is unknown
            if (isVariableName(rhs)) {
                //println("  - RightHandSide known, LeftHandSide min = RightHandSide");
                paramGenData[lhsStr].min = calculatedParams[rhsStr] + ((allowEqual) ? 0 : 0.01); 
            } else {
                throw "Unsupported | Cannot solve an expression greater than (or equal) a known value (1)";
            }
        } else {
            // Left is unknown
            if (isVariableName(lhs)) {
                //println("  - LeftHandSide known, RightHandSide max = LeftHandSide");
                paramGenData[rhsStr].max = calculatedParams[lhsStr] - ((allowEqual) ? 0 : 0.01);
                decreaseMinIfNeeded(rhsStr);
            } else {
                throw "Unsupported | Cannot solve an expression greater than (or equal) a known value (2)";
            }
        }
    } else {
        // Else both unknown, check if contains expression.
        if (!isVariableName(lhs) || !isVariableName(rhs)) {
            // check if rhs is literal zero (0)
            if (rhsStr == "0") {
                // Tactic: Right is known
                //println("  - Both expressions. Detected literal 0. Thus: RightHandSide known, LeftHandSide min = RightHandSide (0)");
                paramGenData[lhsStr].min = 0 /* <-- the value 0 */ + ((allowEqual) ? 0 : 0.01);
            } else {
                // else throw exception, unsupported!
                throw "Unsupported | Cannot solve expressions when using Greater Than (\>) Or Equal (\>=). <lhs>  |  <rhs>";
            }
            // Could be extended later, such that max would be the calculated value. But not needed currently
        } else {
            // Not, calc var and other is the same
            //println("  - Doesn\'t contain expression, calculating left. RightHandSide max = LeftHandSide");
            calculatedParams[lhsStr] = calculateExpression(lhs);
            paramGenData[rhsStr].max = calculatedParams[lhsStr] - ((allowEqual) ? 0 : 0.01); // Parenthesis are needed here, Rascal bug?
            decreaseMinIfNeeded(rhsStr);
        }
    }
}

private void handleConditionStatement(str operator, Expr lhs, Expr rhs) {
    throw "Currently not supporting precondition expression for <operator>";
}

// Utility
private bool isVariableName((Expr)`<VarName _>`) = true;
private bool isVariableName((Expr)`(<VarName _>)`) = true;
private bool isVariableName(Expr _) = false;

// Increase max if needed
private void increaseMaxIfNeeded(str varName) {
    while (paramGenData[varName].min >= paramGenData[varName].max) {
        paramGenData[varName].max += 0.01;
    }
}
// Decrease min if needed
private void decreaseMinIfNeeded(str varName) {
    while (paramGenData[varName].max <= paramGenData[varName].min) {
        paramGenData[varName].min -= 0.01;
    }
}

private Expr removeRoundFromExpr((Expr)`round(<Expr e>)`) = e;
private Expr removeRoundFromExpr((Expr)`round(<Expr e>)`) {
    throw "Couldn\'t remove \'round\' from expression: <e>";
}

private Expr getExprForVar(str varName) {
    real val = calculatedParams[varName];
    Type tipe = paramGenData[varName].tipe;
    //println("  - Creating expr of type: <tipe> with value <val>");
    
    list[str] splitted = split(".", "<val>");
    assert (size(splitted) == 2) : "Expecting only 2 values after splitting. Values: <splitted>";
    if (size(splitted[1]) == 1) {
        val = toReal("<val>0");
        //println("  -  Detected 1 decimal, adding a trailing 0. Resulting value: <val>");
    }
    if (size(splitted[1]) > 3) {
        // Max 3 decimals
        val = toReal("<splitted[0]>.<substring(splitted[1], 0, 3)>"); //precision(val, size(splitted[0]) + 2);
        //println("  -  Detected more than 3 decimals, rounding it. Resulting value: <val>");
    }
    return createExpr(tipe, val);
}

private Expr createExpr((Type)`Money`, real val) = convertToMoney("EUR", val); // TODO: Also support USD?
private Expr createExpr((Type)`Integer`, real val) = parse(#Expr, "<toInt(val)>"); // Might wanna double check if we dont have a decimal value?
private Expr createExpr(Type tipe, real val) {
    //println("   - Fallback: trying to create Expr with type: <tipe> and value: <val>   | createExpr()");
    return convertToExpr(val);
}

// Calculate expressions
private real calculateExpression((Expr)`<VarName varName>`) {
    return calculateExpression(varName);
}
private real calculateExpression(VarName varName) {
    str varNameStr = "<varName>";
    if (varNameStr in calculatedParams) {
        return calculatedParams[varNameStr];
    } else {
        calculated = genValueFromProps(paramGenData[varNameStr]);
        calculatedParams[varNameStr] = calculated;
        //println("  - Generated value for <varNameStr>: <calculated>");
        return calculated;
    }
}
private real calculateExpression((Expr)`<Expr lhs> * <Expr rhs>`) {
    assert (isVariableName(lhs) && isVariableName(rhs)) : "Unsupported | Nested expressions are unsupported (1)";
    //println("  - Calculating expression, props for lhs and rhs will !allowZero");
    paramGenData["<lhs>"].allowZero = false;
    paramGenData["<rhs>"].allowZero = false;
    real left = calculateExpression(lhs);
    real right = calculateExpression(rhs);
    return left * right;
}
private real calculateExpression((Expr)`(<Expr e>)`) = calculateExpression(e); // Escape parenthesis
private real calculateExpression(Expr e) {
    throw "calculateExpression() | Not implemented for expression: <e>";
}

// Gen values
private real genValueFromProps(RandomValueProps props) {
    //println("  - Generating value for type: <props.tipe> min=<props.min> max=<props.max> allowZero=<props.allowZero>");
    return genValueForType(props.tipe, props.min, props.max, props.allowZero);
}

private real genValueForType((Type)`Money`, real min, real max, bool allowZero) = genRandomDouble(min, max, allowZero);
private real genValueForType((Type)`Integer`, real min, real max, bool allowZero) = genRandomInteger(min, max, allowZero);
private real genValueForType(Type tipe, real min, real max, bool allowZero) {
    throw "Not implemented | genValueForType() not implemented for type: <tipe>";
}

// Converting
private Expr convertToExpr(real amount) {
    str tostring = "<amount>";
    return parse(#Expr, "<substring(tostring, 0, size(tostring)-1)>");
}

private Expr convertToMoney(str currency, real amount) {
    str parseValue;
    if (amount < 0) {
        parseValue = "- <currency> <abs(amount)>";
    } else {
        parseValue = "<currency> <amount>";
    }
    return parse(#Expr, parseValue);
}








