module testsgenerator::TestCases

// Project imports
import testsgenerator::Snippets;
import valuegenerator::SimpleValuesGenerator;
import valuegenerator::DynamicValuesGenerator;
// Dependency imports
import gen::GeneratorUtils;
// Rebel imports
import lang::Builder;
import lang::ExtendedSyntax;
// Rascal imports
import IO;
import util::Maybe;
import List;
import String;

public void generateTestCases(loc testDirectory, set[Built] specs) {
	for(Built built <- specs) {
		Specification spec = built.inlinedMod.spec;
		
		str testCases = generateTestCasesForSpec(spec);
		
		str packageName = getPackageName(built.inlinedMod);
		str fullTestFile = snippetTestTemplate(packageName, "<spec.name>", testCases);
		writeFile(testDirectory + "<spec.name>Spec.scala", fullTestFile);
	}
}

private str generateTestCasesForSpec(Specification spec) {
	str testCases = "";
	list[EventDef] events = getEventDefinitions(spec);
	for (EventDef event <- events) {
		str eventName = capitalize("<event.name>");
		list[Parameter] transitionParamsList = [p | Parameter p <- event.transitionParams];
        list[str] paramsStrList = ["<p.tipe>" | p <- transitionParamsList];
		str testCase;
		int tries = 100;
		if (isEmpty("<event.pre>") /*|| true*/) { // Force random for coverage report?
		  testCase = snippetTestCaseRandom(eventName, paramsStrList, tries);
        } else {
          //list[list[Expr]] testValues = genTestValues(eventName, tries); // Experiment 2 (using ValuesGenerator)
          list[list[Expr]] testValues = genValues(eventName, event.pre, transitionParamsList, tries); // Experiment 3 (using ValuesGeneratorDynamic)
		  testCase = snippetTestCaseConditional(eventName, testValues, paramsStrList, getSupportsOperationsPlusAndMinus("<event.name>"));
		}
		testCases += testCase;
	}
	return testCases;
}

private list[EventDef] getEventDefinitions(Specification spec) {
	return [ed | ed <- spec.events.events];
}

// Returns a boolean, whether we are allowed to modify the values randomly using Plus and Minus
public bool getSupportsOperationsPlusAndMinus(str eventName) {
    list[str] operationsUnsupportedEvents = ["division1", "division2", "divisionEquality1", "divisionEquality2", "divisionEquality3"]; // Min and Plus operations are meant here
    return !(eventName in operationsUnsupportedEvents);
}
