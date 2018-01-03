# MDP Compiler

This project contains a `MDP compiler` written in [Xtext/Xtend](https://www.eclipse.org/Xtext/).
Given as input the description of a SUT as a Markov Decision Process, the compiler 
automatically generates the monitor instrumentation and the input files for the [monitored-mdp-simulator](https://github.com/SELab-unimi/mdp-simulator-monitored).

## How do I get set up?

This is a `Xtext/Xtend` project containing an Eclipse plugin.
You can import it inside the Eclipse IDE by using `Gradle`.

### Simple exmaple

The following input shows a simple MDP example written by using the `mdpDsl` language:

```
model "simple-mdp"
actions
	w a b
states
	S0 {empty} initial
	S1 {}
	S2 {}
	S3 {full}
	S4 {}
	S5 {} Dir~(w, <S3, 0.8> <S0, 0.2>)
arcs
	a0 : (S0, a) -> S1, 0.1
	a1 : (S0, a) -> S5, 0.9
	a2 : (S0, b) -> S2, 1.0
	a3 : (S1, a) -> S3, 1.0
	a4 : (S1, b) -> S4, 1.0
	a5 : (S5, w) -> S3, 0.8
	a9 : (S5, w) -> S0, 0.2
	a6 : (S2, w) -> S2, 1.0
	a7 : (S4, w) -> S4, 1.0
	a8 : (S3, w) -> S3, 1.0
observe 
	a0 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S1\")"
	a1 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S5\")"
	a2 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S2\")"
	a3 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S3\")", precondition "state != null"
	a4 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S4\")"
	a5 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S3\")"
	a6 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S2\")"
	a7 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S4\")"
	a8 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S3\")"
	a9 -> after "private void it.unimi.di.se.simulator.MDPSimulator.doTransition(..)", args {state:"jmarkov.jmdp.IntegerState"}, argsCondition "state.label().equals(\"S0\")"
control
	S0 -> "private char it.unimi.di.se.simulator.MDPDriver.waitForAction(..)", args {actionList:"jmarkov.basic.Actions<jmarkov.jmdp.CharAction>" input:"java.io.InputStream"}
	S1 -> "private char it.unimi.di.se.simulator.MDPDriver.waitForAction(..)", args {actionList:"jmarkov.basic.Actions<jmarkov.jmdp.CharAction>" input:"java.io.InputStream"}
reset
	"public void it.unimi.di.se.simulator.MDPSimulator.resetSimulation(..)"
```

This example shows how to define *actions*, *states*, *arcs* (i.e., the MDP model) and how to connect them to 
the SUT (i.e., the [monitored-mdp-simulator](https://github.com/SELab-unimi/mdp-simulator-monitored)) 
by defining *observable*/*controllable* actions.

Observable actions allow to link arcs of the model to the execution of specific methods of the SUT.
Controllable actions allow to control the arguments of specific methods depending on the *uncertainty-based exploration policy*.

Given a `.mdp` file, the The `MDP Compiler` generates: 

*    the *Monitor instrumentation* (i.e., the `EventHandler.aj` file);
*    the [MDP simulator](https://github.com/SELab-unimi/mdp-simulator-monitored) input file (i.e., the `sut.jmdp` file);
*    the [Prism model checker](http://www.prismmodelchecker.org/) input file representing the SUT (i.e., the `sut.prism` file).

## License

See the [LICENSE](LICENSE.txt) file for license rights and limitations (GNU GPLv3).

## Who do I talk to?

* [Matteo Camilli](http://camilli.di.unimi.it): <matteo.camilli@unimi.it>