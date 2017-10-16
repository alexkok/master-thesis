module testsgenerator::Skeleton

// Project imports
// Dependency imports
// Rebel imports
// Rascal imports
import IO;
import String;

// Constants
private str lineEnding = "\n";
private str projectNameDeclarationStart = "name          :=";
// Files
private str pluginsFileName = "project\\plugins.sbt";
private str buildFileName = "build.sbt";
private str sourceDirectoryName = "src";
private str testDirectoryName = "test";
private str resourcesDirectoryName = "resources";
private str applicationConfigurationFileName = "application.conf";

// Dependencies
private str addTestDependencyStatement = "libraryDependencies += ";
private list[str] testDependencies = [
		addTestDependencyStatement + "\"org.scalactic\" %% \"scalactic\" % \"3.0.1\"",
		addTestDependencyStatement + "\"org.scalatest\" %% \"scalatest\" % \"3.0.1\" % \"test\"",
		addTestDependencyStatement + "\"org.iq80.leveldb\" % \"leveldb\" % \"0.7\" % \"test\""		
	];

public loc initializeTestSuit(loc path, str projectName, bool shouldFixPrecisionIssue) {
	println("\> Initializing test suit at location: <path>");
	updateBuildFile(path, projectName, shouldFixPrecisionIssue);
	updatePluginsFile(path);
	loc testDir = createTestDirectory(path);
	addResources(path);
	addUtilFiles(testDir);
	return testDir;
}

@doc{
	Updating the generated build file. 
	- Adding the test dependecies that we need for our tests
}
private void updateBuildFile(loc path, str projectName, bool shouldFixPrecisionIssue) {
	loc buildFile = path + buildFileName;
	bool addedTestDependencies = false;
	bool updatedName = false;
	bool addedOptions = false;
	bool fixedPrecisionIssue = false;
	
	str updatedFileContent = "";
	if (exists(buildFile)) {
		for (str line <- readFileLines(buildFile)) {
			if (startsWith(line, projectNameDeclarationStart)) {
				line = projectNameDeclarationStart + "\"" + projectName + "\"";
				updatedName = true;
				// Show durations of each individual test
				updatedFileContent += "testOptions in Test += Tests.Argument(\"-oD\")" + lineEnding;
				// Prevent logBuffering, we don't need it anyway. // Not fixing the issue with having a running process left after we ran (and killed) the testsuit.
				updatedFileContent += "logBuffered in Global := false" + lineEnding;
				addedOptions = true;
			}
            if (shouldFixPrecisionIssue) {
                if (contains(line, "0.7.0-SNAPSHOT")) {
                    line = "libraryDependencies += \"com.ing.rebel\" %% \"rebel-lib\" % \"0.7.1-SNAPSHOT\"";
                    fixedPrecisionIssue = true;
                }
            }
			updatedFileContent += line + lineEnding;
			if (startsWith(line, addTestDependencyStatement) && !addedTestDependencies) {
				for (str dependency <- testDependencies) {
					updatedFileContent += dependency + lineEnding;
				}
				addedTestDependencies = true;
			}
		}
	}
	assert addedTestDependencies : "Dependencies have not been added. Did the syntax of the buildfile (<buildFileName>) change?";
	assert updatedName : "Expected name to be updated in buildfile. Did the syntax of the buildfile (<buildFileName>) change?";
	assert addedOptions : "Expected additional options at buildfile. Did the syntax of the buildfile (<buildFileName>) change?";
	assert (!shouldFixPrecisionIssue || fixedPrecisionIssue) : "Expected fixed precision issue in buildfile. Did the syntax of the buildfile (<buildFileName>) change?";
	
	writeFile(buildFile, updatedFileContent);
	println("\> Added the dependencies to the build file: <buildFile>");
}

private void updatePluginsFile(loc path) {
    loc pluginFile = path + pluginsFileName;
    str fileContent = readFile(pluginFile);
    fileContent += "addSbtPlugin(\"org.scoverage\" % \"sbt-scoverage\" % \"1.3.5\")\n";
    writeFile(pluginFile, fileContent);
}

private loc createTestDirectory(loc path) {
	loc testDirectory = path + sourceDirectoryName + testDirectoryName;
	assert !exists(testDirectory) : "The test directory shouldn\'t exist yet...";
	mkDirectory(testDirectory);
	
	loc scalaTestDirectory = testDirectory + "scala";
	mkDirectory(scalaTestDirectory);
	println("\> Created the test directories in: <testDirectory>");
	return scalaTestDirectory;
}

private void addResources(loc path) {
	loc resourcesDirectory = path + sourceDirectoryName + testDirectoryName + resourcesDirectoryName;
	mkDirectory(resourcesDirectory);
	
	loc applicationConfigFile = resourcesDirectory + applicationConfigurationFileName; 
	writeFile(applicationConfigFile, akkaApplicationConfig);
	println("\> Generated application config file (<applicationConfigurationFileName>)");
}

private void addUtilFiles(loc path) {
    writeFile(path + "CassandraLifecycle.scala", cassandraLifeCycleClass);
    
    // We might need a reference.conf file too. In case this doesn't work as expected or in case we want some extra properties
    // https://stackoverflow.com/questions/40692372/akka-persistence-and-mongodb-persistence-failure-when-replaying-events-for-pers/40693580#40693580
}


// Templates
private str akkaApplicationConfig = "akka {
  loggers = [\"akka.testkit.TestEventListener\"]
  
  actor {
    provider = akka.cluster.ClusterActorRefProvider
  }

  remote {
    netty.tcp {
      hostname = localhost
      port = 0
    }
  }

  test.timefactor = 3
  
  // Fuzzing in akka
  akka.stream.materializer.debug.fuzzing-mode = on
}
";

private str cassandraLifeCycleClass = "/*
 * Copyright (C) 2016 Typesafe Inc. \<http://www.typesafe.com\>
 */
import java.io.File
import java.util.concurrent.TimeUnit

import akka.actor.{ActorSystem, Props}
import akka.persistence.PersistentActor
import akka.persistence.cassandra.testkit.CassandraLauncher
import akka.testkit.TestProbe
import org.scalatest._

import scala.concurrent.duration._

object CassandraLifecycle {

  def awaitPersistenceInit(system: ActorSystem): Unit = {
    system.log.info(\"starting awaitPersistenceInit\")
    val probe = TestProbe()(system)
    val t0 = System.nanoTime()
    var n = 0
    probe.within(45.seconds) {
      probe.awaitAssert {
        n += 1
        system.actorOf(Props[AwaitPersistenceInit], \"persistenceInit\" + n).tell(\"hello\", probe.ref)
        probe.expectMsg(5.seconds, \"hello\")
        system.log.info(\"awaitPersistenceInit took {} ms {}\", TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0), system.name)
      }
    }

  }

  class AwaitPersistenceInit extends PersistentActor {
    def persistenceId: String = \"persistenceInit\"

    def receiveRecover: Receive = {
      case _ =\>
    }

    def receiveCommand: Receive = {
      case msg =\>
        persist(msg) { _ =\>
          sender() ! msg
          context.stop(self)
        }
    }
  }
}

trait CassandraStarter {
  def system: ActorSystem

  def systemName: String = system.name

  def cassandraConfigResource: String = CassandraLauncher.DefaultTestConfigResource

  val cassandraPort: Int = CassandraLauncher.randomPort

  def startCassandra(): Unit = {
    system.log.info(s\"Starting Cassandra on localhost:$cassandraPort\")
    val cassandraDirectory = new File(s\"target/cassandra/$systemName\")
    CassandraLauncher.start(
      cassandraDirectory,
      configResource = cassandraConfigResource,
      clean = true,
      port = 9042
    )
    system.log.info(s\"Started Cassandra on localhost:$cassandraPort\")
    awaitPersistenceInit()
  }

  def awaitPersistenceInit(): Unit = {
    CassandraLifecycle.awaitPersistenceInit(system)
  }
}

trait CassandraLifecycle extends CassandraStarter with BeforeAndAfterAll {
  this: Suite =\>

  override def beforeAll(): Unit = {
    startCassandra()
    super.beforeAll()
  }

}";