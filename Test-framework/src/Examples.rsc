module Examples

// Project imports
import Main;
// Dependency imports
// Rebel imports
// Rascal imports
import String;
import List;
import IO;

@doc{
	A simple method to print each method in this file.
	It can also be done by parsing the Rascal file and retrieve the methods. 
	For now, it just reads each line and checks if there is a `public void generateXxx` method on that line. 
	If so: it prints the name of that method.
}
public void printGenerationExampleMethods() {
	loc thisFileLocation = |project://TestGenerator/src/Examples.rsc|;
	str methodModifiers = "public void";
	str generationMethodStart = "generate";
	
	// TODO: Maybe possible inside forloop?
	list[str] methodLines = ([] | it + ml | ml <- readFileLines(thisFileLocation), startsWith(ml, methodModifiers + " " + generationMethodStart));
	
	println("Methods to generate its corresponding specifications:");
	for (str methodLine <- methodLines) {
		str method = substring(methodLine, size(methodModifiers), size(methodLine)-2); // Removing modifiers and " {" (ending)
		println("\t- <method>");
	}
}

public void generateSimpleAccount() {
	generateTestSuit(
	{	|project://TestGenerator/specifications/simple_account/Account.ebl|
	}, 	|project://TestGenerator/gen/simple_account|);
}

public void generateSimpleTransaction() {
	generateTestSuit(
	{	|project://TestGenerator/specifications/simple_transaction/Account.ebl|
	,	|project://TestGenerator/specifications/simple_transaction/Transaction.ebl|
	}, 	|project://TestGenerator/gen/simple_transaction|);
}

public void generateMoneySpec() {
	generateTestSuit(
	{	|project://TestGenerator/specifications/specs_money/MoneySpec.ebl|
	}, 	|project://TestGenerator/gen/specs_money|);
}