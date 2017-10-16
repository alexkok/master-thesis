module testsgenerator::Snippets

// Project imports
// Dependency imports
import gen::scala::ScalaTypeMapping;
import gen::scala::ScalaGenerator;
// Rebel imports
import lang::CommonSyntax;
// Rascal imports
import List;
import String;
import ParseTree;

public str snippetTestCaseRandom(str eventName, list[str] params, int tries) {
    // For better overview
    //return "\"work with <eventName>\" in {
    //          generateRandomParamList(<convertParamsToList(params)>, <tries>).foreach {
    //            data: List[Any] =\> {
    //              checkAction(<eventName>(
    //                <for (i <- [0..size(params)]) {>
    //                  // Iterate over params. Use getMappedType for the casting again
    //                  data(<i>).asInstanceOf[<getMappedTypeForParam(params[i])>]
    //                  // Add a comma if needed
    //                  <if (i != size(params)-1) {>,<}>
    //                <}>
    //                )
    //              )
    //            }
    //          }
    //        }";
    
    // Smaller
    return 
    "\"work with <eventName>\" in {
       generateRandomParamList(<convertParamsToList(params)>, <tries>).foreach {
         data: List[Any] =\> {
           checkAction( <eventName>(<
               for (i <- [0..size(params)]) {
                         // Iterate over params. Use getMappedType for the casting again
                         >data(<i>).asInstanceOf[<getMappedTypeForParam(params[i])>]<
                         // Add a comma if needed
                         if (i != size(params)-1) {
                         >, <}><
             }>) )
         }
       }
     }
    ";
}

public str snippetTestCaseConditional(str eventName, list[list[Expr]] testValues, list[str] params, bool supportsAddAndSubtract) {
    str intercalatedString = "";
    for (list[Expr] valueRow <- testValues) {
        list[str] synthesized = [synthesize(e, ()) | Expr e <- valueRow];
        intercalatedString += "(<intercalate(", ", synthesized)>)";
        intercalatedString += ",";
    }
    intercalatedString = substring(intercalatedString, 0, size(intercalatedString)-1); // Remove last comma
    return
    "\"work with <eventName>\" in {
      Seq(<intercalatedString>)
      .foreach {
        data:  (<intercalate(", ", [getMappedTypeForParam(p) | str p <- params])>) =\> {
          val randomOperation = genRandomOperation(genRandomOperator(\"Money\", <supportsAddAndSubtract>), generateRandomMoney(data._1.currency), generateRandomInteger(true), generateRandomInteger(false), generateRandomPercentage(true), generateRandomPercentage(false), Random.nextInt(10))

          checkAction(<eventName>(
              <for (i <- [0..size(params)]){
                  ><if (params[i] != "Integer") { 
                      >randomOperation(data._<i+1>)<
                  } else {>
                      data._<i+1><
                  }
                  ><if (i != size(params)-1) {
                      >,< 
                  }>
              <}
            >)
          )
        }
      }
    }
    ";
}

private str convertParamsToList(list[str] params) {
	str paramsConcatonated = intercalate(", ", ["\"<p>\"" | p <- params]);
	return "List(<paramsConcatonated>)";
}

private str getMappedTypeForParam(str param) {
	return getMappedType(parse(#Type, param));
}

public str snippetTestTemplate(str packageName, str specName, str testCases) {
	return "import akka.actor.{ActorRef, ActorSystem, Props}
import akka.testkit.{ImplicitSender, TestKitBase}
import com.ing.corebank.rebel.<packageName>.<specName>._
import com.ing.corebank.rebel.<packageName>.actor.<specName>Actor
import com.ing.rebel._
import com.ing.rebel.Rebel._
import org.scalatest.{Matchers, WordSpecLike}
import squants.market._

import scala.util.Random

/**
  * Generated at 2017-06-07 09:38:51.105+0000.
  */
class <specName>Spec extends TestKitBase
  with ImplicitSender with WordSpecLike with Matchers with CassandraLifecycle {

  implicit lazy val system: ActorSystem = ActorSystem()

  def randomId: String = \"<specName>_\" + java.util.UUID.randomUUID.toString

  var actorProps<specName>: Props = <specName>Actor.props(self)

  def expectMsgCommandFailed: Success = expectMsgPF() {
    case CommandFailed(_) =\> ()
  }

  def getActorRef(): ActorRef = {
    val actorRef = system.actorOf(actorProps<specName>, randomId)
    actorRef ! TellState
    expectMsg(CurrentState(Init, Uninitialised))

    actorRef
  }

  def generateRandomMoney(currency: Currency): Money = {
    val random = new Random

    val denom = random.nextInt(100)
    val strDenom = if (denom \< 10) \"0\" + denom else denom
//    val fullAmount = BigDecimal(random.nextInt(1) + \".\" + strDenom) // Limit the amount of possibilities, for debugging purposes
    val fullAmount = BigDecimal(random.nextInt() + \".\" + strDenom)
    currency(fullAmount)
  }

  def generateRandomInteger(allowZero: Boolean): Int = {
    val random = new Random
    var result = random.nextInt()
    if (allowZero) {
      result
    } else {
      while (result == 0) {
        result = random.nextInt()
      }
      result
    }
  }

  def generateRandomPercentage(allowZero: Boolean): Double = {
    val random = new Random
    var result = random.nextInt(101)
    if (allowZero) {
      result.percent
    } else {
      while (result == 0) {
        result = random.nextInt(101)
      }
      result
    }
  }

  def checkAction(command: RebelCommand): Unit = {
    // Get an actor
    val actor = getActorRef()

    // Do the command
    actor ! command
    expectMsg(CommandSuccess(command))

    // Validate
    actor ! TellState
    // The result should be true. If it\'s false, it means that there is an error in the implementation of the generated product
    expectMsg(remainingOrDefault, s\"With command: ${command.toString}\", CurrentState(Result, Initialised(Data(None, Some(true)))))
  }

  // **
  // ** START | Random specific **
  // ** 
  
  def generateRandomParamList(params: List[String], amount: Int): List[List[Any]] = {
    var randomData: List[List[Any]] = Nil
    for (i \<- 1 to amount) {
      var paramPair: List[Any] = Nil
      // Example: x: Money, y: Integer, z: Percentage
      params.foreach(
        param =\> {
          paramPair ::= generateRandomValue(param)
        }
      )
      randomData ::= paramPair.reverse // Reverse so that our params are in the right order again
    }
    randomData
  }

  def generateRandomValue(param: String): Any = {
    // Only EUR as currency when using completely random values.
    // Some events are currency specific, generator doesn\'t fully support \"Currency\" of Rebel yet.
    param match {
      case \"Money\" =\> generateRandomMoney(EUR)
      case \"Integer\" =\> generateRandomInteger(true)
      case \"Percentage\" =\> generateRandomPercentage(true)
      case _ =\> throw new AssertionError(s\"No generator found for type: $param\")
    }
  }
  
  // **
  // ** END | Random specific **
  // **
  
  // **
  // ** START | Conditional specific **  
  // **
  
  object Operations extends Enumeration {
    val Minus, Plus, Multiply, Divide = Value
  }

  def genRandomOperation(operator: Operations.Value, rightMoney: Money, rightInt: Int, rightIntNonZero: Int, rightPercentage: Double, rightPercentageNonZero: Double, switchNumber: Int) = (param: Money) =\> {
    operator match {
      case Operations.Minus =\>
        param - rightMoney
      case Operations.Plus =\>
        param + rightMoney
      case Operations.Multiply =\>
        if (switchNumber \< 5) {
          param * Math.abs(rightInt) // Absolute value, as with negatives we can easily break the conditions
        } else {
          param * rightPercentage
        }
      case Operations.Divide =\>
        if (switchNumber \< 5) {
          param / Math.abs(rightIntNonZero) // Absolute value, as with negatives we can easily break the conditions
        } else {
          param / rightPercentageNonZero
        }
      case _ =\> throw new UnsupportedOperationException(s\"genRandomOperation not supported with operator: $operator\")
    }
  }: Money

  def genRandomOperator(forType: String, supportsPlusAndMinus: Boolean): Operations.Value = {
    forType match {
      case \"Money\" =\>
        var operations: Seq[Operations.Value] = Seq()
        if (supportsPlusAndMinus) {
          operations = Seq(Operations.Minus, Operations.Plus, Operations.Multiply, Operations.Divide)
        } else {
          operations = Seq(Operations.Multiply, Operations.Divide)
        }
        operations(Random.nextInt(operations.size))
      case _ =\>
        throw new UnsupportedOperationException(s\"genRandomOperator not supported for type: $forType\")
    }
  }
  
  // **
  // ** END | Conditional specific **
  // **
  
  \"<specName>\" should {
    <testCases>
  }
}
";
}