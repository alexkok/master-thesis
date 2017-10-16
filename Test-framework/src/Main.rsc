module Main

// Project imports
extend Examples; // Simply add the example methods to this file
import Examples; // Allow us to use the functions of Examples in the compiler-based version of Rascal
import specgenerator::SpecGenerator;
import testsgenerator::Skeleton;
import testsgenerator::TestCases;
// Dependency imports
import gen::GeneratorUtils;
import gen::tests::GeneratorTest;
import gen::scala::ScalaGenerator;
import gen::javadatomic::JavaDatomicGenerator;
// Rebel imports
import lang::Builder;
// Rascal imports
import IO;
import util::Resources;
import String;
import util::ShellExec;
import util::Maybe;
import Set;

@doc{
	This method simply calls the `help()` method.
}
public void main() {
	help();
}

@doc{
	A method that can be called which shows how we can run this program.
	Also listing the example methods in one overview.
}
public void help() {
	println("
	'** Test framework **
	'* - Run the following method:
	'* - testSpecifications(bool fixPrecisionIssue = false, bool run = false)
	'**
	");
}
private set[Built] buildSpecifications(set[loc] locations) {
	set[Maybe[Built]] loadedMods = loadModules(locations);
	set[Built] buildedMods = {b | just(Built b) <- loadedMods};
	
	int modCount = size(buildedMods);
	println("Built <modCount> module<modCount>1?"s":"">");
	
	return buildedMods;
}

@doc{
    This method combines the required actions.
    Resulting in a generated test suit based on the given specifications.
    Optionally run the test suit immediately, by using the `run` parameter.
}
public void testSpecifications(bool fixPrecisionIssue = false, bool run = false) {
	loc targetLocation = |project://TestGenerator/specifications/gen|;
	// Clear old content
	remove(targetLocation);
	// Prepare output
	generateIfNotExists(targetLocation);
	// Generate specs
	set[loc] specLocations = generateSpecifications(targetLocation);
	set[Built] builtSpecs = buildSpecifications(specLocations); 
	
	// Generate Scala program (Depends on other project)
	loc outputPath = |project://TestGenerator/gen/test_specifications|;
	generateIfNotExists(outputPath);
	generateAndSave(specLocations, outputPath);
	// Add our test skeleton files
	loc realProjectLocation = outputPath + "/target/code/scala";
	loc testFilesDirectory = initializeTestSuit(realProjectLocation, outputPath.file, fixPrecisionIssue);
	// Generate tests
	generateTestCases(testFilesDirectory, builtSpecs);
	// Show that we are done
	showFinished(realProjectLocation);
	// Run our test suit
	if (run) {
		runTestSuit(realProjectLocation);
	}
}

private void runTestSuit(loc projectLocation) {
	// Run tests (sbt test)
	tuple[PID pid, str result] testingPid = runTests(projectLocation);
	killProcess(testingPid.pid);
	println("\> Done testing");
	if (contains(testingPid.result, "[success]")) {
		println("\> ** Tests successful! **");
	} else {
		println("\> ** Some tests failed! **");
	}
}

private void generateIfNotExists(loc path) {
	if (!exists(path)) {
		mkDirectory(path);
	}
}

private void showFinished(loc path) {
	println("\> ** Generated test suite. **");
	println("\> Project can be found at <path>");
}

private tuple[PID pid, str result] runTests(loc projectLocation) {
	println("\> Running \'sbt test\' at <projectLocation>");
	// Results
    // - "Passed:" means a success
    // - "Failed:" means a failure
    // - "Total time:" means a compile error. Note that Total time is also in the next line of "Passed:" and "Failed:".
	return startProcess("sbt.bat", ["test"], projectLocation, ["Total time:"]);
}

private tuple[PID pid, str result] startProcess(str program, list[str] args, loc projectLocation, list[str] stopChecks) {
	println("\> Starting process with: <program>. Args: <args>");
	PID pid = createProcess(program, args=args, workingDir=location(projectLocation));
	
	str lastString = "";
	while(!any(str stopCheck <- stopChecks, contains(lastString, stopCheck))) {
	    str newString = readFrom(pid);
	    if (!isEmpty(newString)) {	    
	        newString = substring(newString, 0, size(newString) - 2); // sbt does add a "\n" by itself, we remove it again
    	    if (newString != lastString 
    	       ,   !contains(newString, "passivation") // Don't print lines with `passivation` to avoid much (unnecessary) logging
    	       ,   !contains(newString, "Passivate") // Also ignore 'Passivate' messages
    	       ,   !contains(newString, "passivating") // Also ignore 'passivating' messages
    	       ,   !contains(newString, "Persisted") // Also ignore 'Persisted and in to state` messages 
    	       ,   !contains(newString, "default-dispatcher") // Ignore 'default-dispatcher` messages, a println tells us in short what happens 
    	       ) { 
    		    if (contains(newString, "Resolving")) {
    		        // In case of resolving, just replace existing scentence, to avoid much (unnecessary) logging
    			    print("\r<newString>");
    		    } else {
    		        println(newString);
    			}
    		}
    		lastString = newString;
        }
	}
	return <pid, lastString>;
}