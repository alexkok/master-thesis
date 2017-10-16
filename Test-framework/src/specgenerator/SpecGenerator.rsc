module specgenerator::SpecGenerator

// Project imports
// Dependency imports
// Rebel imports
import lang::Builder;
import lang::ExtendedSyntax;
// Rascal imports
import IO;
import Set;
import util::Maybe;
import String;

private list[tuple[Type litType, str sample, Maybe[str] zeroValue]] types = [
	// sample: used for determining valid operators and actions
	// zeroValue: used for operator event definitions which lead to the zero value (that is: 0 for ints, EUR 0.00 for Money, etc.). 
	<(Type)`Money`, "EUR 50.00", just("EUR 0.00")>,
	<(Type)`Integer`, "1", just("0")>,
	<(Type)`Percentage`, "1%", just("0%")>,
	<(Type)`String`, "text", nothing()>,
	<(Type)`IBAN`, "NL95INGB0753988428", nothing()>,
	<(Type)`Boolean`, "true", nothing()>,
	<(Type)`Currency`, "EUR", nothing()>
	// Term?
	// Date?
	// Time?
	// DateTime?
	// Period?
	// Frequency?
];

public set[loc] generateSpecifications(loc targetLocation) {
    //return generateForOnePropCase(targetLocation);
	//return generateForInitialCase(targetLocation);
    //return generateForSecondCase(targetLocation);
    return generateForThirdCase(targetLocation);
}

private set[loc] generateForOnePropCase(loc targetLocation) {
    loc targetSpecLocation = targetLocation + "specs_money";
    loc thisSpecLocation = |project://TestGenerator/src/specgenerator/samples/0_oneprop|; 
    
    copyFiles(thisSpecLocation, targetSpecLocation);
    return getSpecFiles(targetSpecLocation);
}

private set[loc] generateForInitialCase(loc targetLocation) {
    loc targetSpecLocation = targetLocation + "specs_money";
    loc thisSpecLocation = |project://TestGenerator/src/specgenerator/samples/1_initial|; 
    
    copyFiles(thisSpecLocation, targetSpecLocation);
    return getSpecFiles(targetSpecLocation);
}

private set[loc] generateForSecondCase(loc targetLocation) {
    loc targetSpecLocation = targetLocation + "specs_money";
    loc thisSpecLocation = |project://TestGenerator/src/specgenerator/samples/2_second|;
    
    copyFiles(thisSpecLocation, targetSpecLocation);
    return getSpecFiles(targetSpecLocation);
}

private set[loc] generateForThirdCase(loc targetLocation) {
    loc targetSpecLocation = targetLocation + "specs_money";
    loc thisSpecLocation = |project://TestGenerator/src/specgenerator/samples/3_third|;
    
    copyFiles(thisSpecLocation, targetSpecLocation);
    return getSpecFiles(targetSpecLocation);
}

private void copyFiles(loc from, loc to) {
	for (loc file <- from.ls) {
		writeFile(to + file.file, readFile(file));
	} 
}

private set[loc] getSpecFiles(loc dir) {
	return {l | loc l <- dir.ls, !endsWith(l.file, "Library.ebl")};
}