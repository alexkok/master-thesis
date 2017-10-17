# Test Framework
The source of the test framework.
- The test framework is written in Rascal. Thus, it requires Eclipse and the related Rascal configurations.
- The test framework uses Rebel and the Scala/Akka generator as dependencies. These must be opened in the Eclipse workspace too in order to run the test framework.
- Furthermore, the test framework requires the Scala Build Tool (SBT) to run the generated system and to run the test framework.

We used the test framework with the following versions. Using newer versions might or might not break its functionality.

| Name                 | Version                       | Source                                 | Notes                           |
| -------------------- | ----------------------------- | -------------------------------------- | ------------------------------- |
| Rascal               | 0.8.4.201707040848 (Unstable) | https://github.com/usethesource/rascal | Unstable, stable is not updated |
| Rebel                | 1.0.0                         | https://github.com/cwi-swat/rebel      | Git commit hash: 6dc2ed9        |
| ing-rebel-generators | 1.0.0                         | _Closed source_                        | Git commit hash: 47121bc        |

**NOTE:** Please note that the test framework depends on the Scala/Akka generator that is written by ING. This generator is currently closed source, but this might change in the future. As a result, it is not possible to run the test framework without this generator.

# Experiments
To run the experiments, we assume that the project is configured and opened in Eclipse.
In our thesis we ran three experiments. For the latter two experiments a fixed version (1.4) of the Squants library is used.

## Starting up any experiment
1. Open the `src\Main.rsc` file.
2. Start the console. -- (Right mouse click in the file, then `Start Console`)
3. Import the Main module. -- (Either write `import Main;` in the console OR use right mouse click in the file, then `Import Current Module in Console`)
4. The method that we will use in each experiment is `testSpecifications(bool fixPrecisionIssue = false, bool run = false)`.

**NOTE:** Note that running the test suite is optional and configured by this parameter. The test suite can always be run by `sbt test` in the directory of the generated system. -- The logs of this result are colored and therefore provide more overview. In the Rascal console colors are not supported, thus resulting in that each log statement is shown in black.

**NOTE:** The 1.4 version of Squants was not released yet. Thus in order to use this fix, the following steps were taken:
1. Checkout the Squants source.
2. Build it locally.
3. Publish the library locally (as 1.4-SNAPSHOT).
4. Update the RebelLib to use this version.
5. Update the RebelLib version to 1.7.1-SNAPSHOT.
6. _This version of the RebelLib will be used in experiments two and three (where the parameter `fixPrecisionIssue` will be set to `true`._

## Running the experiments

### Experiment 1
The first experiment consists of using only random input values for each test.
1. Open the `src\specgenerator\SpecGenerator.rsc` file.
2. In the method `generateSpecifications(loc targetLocation)`, ensure that the line `return generateForInitialCase(targetLocation);` is enabled. And ensure that the other lines in this method are commented out.
3. In the console, run `testSpecifications(fixPrecisionIssue=false, run=true)`.

### Experiment 2 
In the second experiment, we use the initial version of the value generator.
1. Open the `src\specgenerator\SpecGenerator.rsc` file.
2. In the method `generateSpecifications(loc targetLocation)`, ensure that the line `return generateForSecondCase(targetLocation);` is enabled. And ensure that the other lines in this method are commented out.
3. Check `src\testsgenerator\TestCases.rsc`: Uncomment line 42 and comment line 43. It will now use the `SimpleValueGenerator` that resides in `src\valuegenerator\`.
4. In the console, run `testSpecifications(fixPrecisionIssue=true, run=true)`.

### Experiment 3
In the third experiment, we use our dynamic value generator that generates values based on the precondition statements.
1. Open the `src\specgenerator\SpecGenerator.rsc` file.
2. In the method `generateSpecifications(loc targetLocation)`, ensure that the line `return generateForThirdCase(targetLocation);` is enabled. And ensure that the other lines in this method are commented out.
3. Check `src\testsgenerator\TestCases.rsc`: Comment line 42 and uncomment line 43. It will now use the `DynamicValueGenerator` that resides in `src\valuegenerator\`.
4. In the console, run `testSpecifications(fixPrecisionIssue=true, run=true)`.
