# HYPpOTesT Modeler

This project contains a `MDP Modeler` Eclipse IDE plug-in, written in [Xtext/Xtend](https://www.eclipse.org/Xtext/).
Given as input the description of the System Under Test (SUT) as a Markov Decision Process (MDP), the `Modeler` automatically generates the *test harness* (`AspectJ` instrumentation) and the input files for the [mbt-module](https://github.com/SELab-unimi/mdp-module) (`web-app` branch).

## How do I get set up?

This is a `Xtext/Xtend` project containing an Eclipse plugin.
You can import it inside the Eclipse IDE by using `Gradle`.

## The DSL

The `DSL` is a simple Domain Specific Language used to describe:
- the *model* (i.e., a MDP) of the SUT;
- the *binding* between the model and the SUT;
- some optional configuration *settings* for the [mbt-module](https://github.com/SELab-unimi/mdp-module).

The source file containing this information has `.mdp` extension.
The *model* declaration contains the following statements:

```
model "UStore"
actions
	a -> CLICK("open-login" "5" "s-user")
	b -> TEXT("s-user" "rosario")
	c -> TEXT("s-password" "ssss")
	d -> SUBMIT("s-password" "5" "Rosario")
	...
states
	S0  {} initial
	S1  {}
	S2  {fail}
	S3  {}
	S4  {} Dir~(d, <S2, 20.0> <S5, 80.0>)
	S5  {logged}
	...
arcs
	a0  : (S0, a) -> S1, 1.0
	a1  : (S1, b) -> S3, 1.0
	a2  : (S3, c) -> S4, 1.0
	a3  : (S4, d) -> S5, 0.5
	a4  : (S4, d) -> S2, 0.5
	a5  : (S2, w) -> S2, 1.0
	...
```

The `"UStore"` represents the specification of the [U-Store exemplar](https://github.com/SELab-unimi/ustore-exemplar) service-based web application.
The *actions* section contains a set of valid inputs for the web-app under test.
A wide range of inputs typically seen in web applications are supported by our DSL, such as click on different UI elements, filling in text fields, submit forms, navigating back and forth, and more.
The *states* section contains states declaration.
Each line is composed of: the state identifier (i.e., `Si`, with `i` in `N>=0`); the set of atomic propositions that hold in the state (i.e., `{«p1», «p2», ...}`); the *Prior* distribution associated with the uncertain parameters of the MDP (i.e., `Dir~(«a», <«Si», «p»> ...)`, with `a` available action, `Si` a reachable state, `p>0` the *concentration parameter*).
Intuitively, the *arcs* section declares the transitions of the MDP model as a set of lines containing `«arcID» : («Si», «a») -> «Sj», «p»`, where `p` is the probability of observing `Sj` from `Si` when choosing the action `a`.

After the model definition, the file must contain the *binding* declaration, composed of two main sections: the *observe* and the *control* that feed the *Observer* and the *Controller* components, respectively, during the **conformance game**.

```
observe
a0  -> "public it.unimi.di.se.simulator.WebAppAction it.unimi.di.se.simulator.MBTDriver.doAction(..)",
	args {state:"jmarkov.jmdp.IntegerState" action:"char"},
	precondition "state.label().equals(\"S0\") && action=='a'",
	postcondition "result.success()" returnType "it.unimi.di.se.simulator.WebAppAction"
	...
```

The *observe* section contains a set of lines that map transitions of the model to method executions of the SUT.
In particular, each line follows this schema:
`«arcID» -> «method signature», args {«name»: «type»}, precondition «bool expression», postcondition «bool expression» returnType «type»`. The *precondition* expression can refer to the input arguments and the *postcondition* expression can refer to the variable `result` which contains the returning value of the method execution (i.e., a `WebAppAction` object).

```
control
	S0 	-> "private char it.unimi.di.se.simulator.MBTDriver.waitForAction(..)",
	args {actionList:"jmarkov.basic.Actions<jmarkov.jmdp.CharAction>" input:"java.io.InputStream"}
	...
```

The *control* section contains a set of lines mapping MDP states to methods that should be controlled during the conformance game.
Each line follows this schema: `«stateID» -> «method signature», args {«arg name»: «arg type»}`.

Finally, the the *sample size* and the *exploration policy* can be defined by using:

```
sampleSize 2000
explorationPolicy uncertainty
```

Available policies are: `uncertainty`, `random` and `history`.

The complete example (i.e., the U-Store) is available in the [resources](/resources/) directory.

Given the `.mdp` file, the The `Modeler` generates:

*    the *test harness* (i.e., the `EventHandler.aj` file);
*    the [mbt-module](https://github.com/SELab-unimi/mbt-module) input file (i.e., the `.jmdp` file);
*    the [Prism model checker](http://www.prismmodelchecker.org/) input file representing the SUT (i.e., the `.prism` file).

## License

See the [LICENSE](LICENSE.txt) file for license rights and limitations (GNU GPLv3).

## Who do I talk to?

* [Matteo Camilli](http://camilli.di.unimi.it): <matteo.camilli@unimi.it>
