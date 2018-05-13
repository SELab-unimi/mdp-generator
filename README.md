# MDP Compiler

This project contains a `MDP compiler` written in [Xtext/Xtend](https://www.eclipse.org/Xtext/).
Given as input the description of the System Under Test (SUT) as a Markov Decision Process (MDP), the *compiler*
automatically generates the monitor instrumentation and the input files for the [monitored-mdp-simulator](https://github.com/SELab-unimi/mdp-simulator-monitored).

## How do I get set up?

This is a `Xtext/Xtend` project containing an Eclipse plugin.
You can import it inside the Eclipse IDE by using `Gradle`.

## The mdpDsl language

The `mdpDsl` is a simple Domain Specific Language (DSL) used to describe:
- the *model* (i.e., a MDP) of the SUT;
- the *binding* between the model and the SUT;
- some optional configuration *settings* for the [online MBT](https://github.com/SELab-unimi/mdp-simulator-monitored) module.

The source file containing this information has `.mdp` extension.
The *model* declaration contains the following statements:

```
model "tas-model"
actions
	w s b v a c
states
	S0  {} initial
	S1  {stop}
	S2  {alarm} Dir~(a, <S3, 300.0> <S4, 200.0>)
	S3  {full}
	S4  {}
	S5  {}
	S6  {}
	S7  {fast}
	S8  {slow}
	S9  {}
	S10 {success}
arcs
	a0  : (S0, s) -> S1, 1.0
	a1  : (S1, w) -> S1, 1.0
	a2  : (S0, b) -> S2, 1.0
	a3  : (S2, a) -> S3, 0.5
	a4  : (S2, a) -> S4, 0.5
	a5  : (S4, w) -> S2, 1.0
	a6  : (S3, w) -> S10, 1.0
	a7  : (S0, v) -> S5, 1.0
	a8  : (S5, b) -> S2, 1.0
	a9  : (S5, c) -> S6, 1.0
	a10 : (S6, w) -> S7, 0.5
	a11 : (S6, w) -> S8, 0.3
	a12 : (S6, w) -> S9, 0.2
	a13 : (S7, w) -> S10, 1.0
	a14 : (S8, w) -> S10, 1.0
	a15 : (S9, w) -> S5, 1.0
	a16 : (S10, w) -> S10, 1.0
```

The `"tas-model"` represents the name of the model.
The *actions* keyword must be followed by a set of whitespace separated characters representing the available actions.
The *states* keyword must be followed by a set of lines containing states declaration.
Each line is composed of: the state identifier (i.e., `Si`, with `i` in `N>=0`); the set of atomic propositions that hold in the state (i.e., `{«p1», «p2», ...}`); the *Prior* distribution associated with the uncertain parameters of the MDP (i.e., `Dir~(«a», <«Si», «p»> ...)`, with `a` available action, `Si` a reachable state, `p>0` the *concentration parameter*).
Intuitively, the *arcs* section declares the transitions of the MDP model as a set of lines containing `«arcID» : («Si», «a») -> «Sj», «p»`, where `p` is the probability of observing `Sj` from `Si` when choosing the action `a`.

After the model definition, the file must contain the *binding* declaration, composed of two main sections: the *observe* and the *control* that feed the *Observer* and the *Controller* components, respectively, during the conformance game.

```
observe
	a0  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S0\") && action=='s'", postcondition "result.label().equals(\"S1\")" returnType "jmarkov.jmdp.IntegerState"
	a1  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S1\") && action=='w'", postcondition "result.label().equals(\"S1\")" returnType "jmarkov.jmdp.IntegerState"
	a2  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S0\") && action=='b'", postcondition "result.label().equals(\"S2\")" returnType "jmarkov.jmdp.IntegerState"
	a3  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S2\") && action=='a'", postcondition "result.label().equals(\"S3\")" returnType "jmarkov.jmdp.IntegerState"
	a4  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S2\") && action=='a'", postcondition "result.label().equals(\"S4\")" returnType "jmarkov.jmdp.IntegerState"
	a5  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S4\") && action=='w'", postcondition "result.label().equals(\"S2\")" returnType "jmarkov.jmdp.IntegerState"
	a6  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S3\") && action=='w'", postcondition "result.label().equals(\"S10\")" returnType "jmarkov.jmdp.IntegerState"
	a7  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S0\") && action=='v'", postcondition "result.label().equals(\"S5\")" returnType "jmarkov.jmdp.IntegerState"
	a8  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S5\") && action=='b'", postcondition "result.label().equals(\"S2\")" returnType "jmarkov.jmdp.IntegerState"
	a9  -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S5\") && action=='c'", postcondition "result.label().equals(\"S6\")" returnType "jmarkov.jmdp.IntegerState"
	a10 -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S6\") && action=='w'", postcondition "result.label().equals(\"S7\")" returnType "jmarkov.jmdp.IntegerState"
	a11 -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S6\") && action=='w'", postcondition "result.label().equals(\"S8\")" returnType "jmarkov.jmdp.IntegerState"
	a12 -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S6\") && action=='w'", postcondition "result.label().equals(\"S9\")" returnType "jmarkov.jmdp.IntegerState"
	a13 -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S7\") && action=='w'", postcondition "result.label().equals(\"S10\")" returnType "jmarkov.jmdp.IntegerState"
	a14 -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S8\") && action=='w'", postcondition "result.label().equals(\"S10\")" returnType "jmarkov.jmdp.IntegerState"
	a15 -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S9\") && action=='w'", postcondition "result.label().equals(\"S5\")" returnType "jmarkov.jmdp.IntegerState"
	a16 -> "public jmarkov.jmdp.IntegerState it.unimi.di.se.simulator.MDPSimulator.doAction(..)", args {state:"jmarkov.jmdp.IntegerState" action:"char"}, precondition "state.label().equals(\"S10\") && action=='w'", postcondition "result.label().equals(\"S10\")" returnType "jmarkov.jmdp.IntegerState"
```

The *observe* section contains a set of lines that map transitions of the model to method executions of the SUT.
In particular, each line follows this schema:
`«arcID» -> «method signature», args {«name»: «type»}, precondition «bool expression», postcondition «bool expression» returnType «type»`. The *precondition* expression can refer to the input arguments and the *postcondition* expression can refer to the variable `result` which contains the returning value of the method execution.

```
control
	S0 -> "private char it.unimi.di.se.simulator.MDPDriver.waitForAction(..)", args {actionList:"jmarkov.basic.Actions<jmarkov.jmdp.CharAction>" input:"java.io.InputStream"}
	S2 -> "private char it.unimi.di.se.simulator.MDPDriver.waitForAction(..)", args {actionList:"jmarkov.basic.Actions<jmarkov.jmdp.CharAction>" input:"java.io.InputStream"}
	S5 -> "private char it.unimi.di.se.simulator.MDPDriver.waitForAction(..)", args {actionList:"jmarkov.basic.Actions<jmarkov.jmdp.CharAction>" input:"java.io.InputStream"}
reset
	"public void it.unimi.di.se.simulator.MDPSimulator.resetSimulation(..)"
```

The *control* section contains a set of lines mapping MDP states to methods that should be controlled during the conformance game.
Each line follows this schema: `«stateID» -> «method signature», args {«arg name»: «arg type»}`.
The online MBT module assumes the presence of a `java.io.InputStream` argument, where the action chosen by the *Controller* is injected upon method call.

Finally, the the *sample size* and the *exploration policy* can be defined by using:

```
sampleSize 2000
explorationPolicy uncertainty
```

Available policies are: `uncertainty`, `random` and `history`.

The complete example (i.e., the TAS) is available in the [resources](/resources/) directory.

Given the `.mdp` file, the The `MDP Compiler` generates:

*    the *Monitor instrumentation* (i.e., the `EventHandler.aj` file);
*    the [MDP simulator](https://github.com/SELab-unimi/mdp-simulator-monitored) input file (i.e., the `.jmdp` file);
*    the [Prism model checker](http://www.prismmodelchecker.org/) input file representing the SUT (i.e., the `.prism` file).

## License

See the [LICENSE](LICENSE.txt) file for license rights and limitations (GNU GPLv3).

## Who do I talk to?

* [Matteo Camilli](http://camilli.di.unimi.it): <matteo.camilli@unimi.it>
