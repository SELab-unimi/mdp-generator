/*
 * generated by Xtext 2.13.0
 */
package it.unimi.di.se.mdp.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import it.unimi.di.se.mdp.mdpDsl.MDPModel
import java.util.HashMap
import it.unimi.di.se.mdp.mdpDsl.State
import it.unimi.di.se.mdp.mdpDsl.Arc
import it.unimi.di.se.mdp.mdpDsl.ObservableMap
import it.unimi.di.se.mdp.mdpDsl.ControllableMap
import java.util.ArrayList
import it.unimi.di.se.mdp.mdpDsl.ResetEvent
import it.unimi.di.se.mdp.mdpDsl.Arg
import java.util.List
import java.util.AbstractMap.SimpleEntry
import org.eclipse.emf.common.util.EList
import it.unimi.di.se.mdp.mdpDsl.AtomicProposition
import it.unimi.di.se.mdp.mdpDsl.Policy
import it.unimi.di.se.mdp.mdpDsl.Termination

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class MdpDslGenerator extends AbstractGenerator {
		
	var observableMethods = new HashMap<String, MonitorObserveCompiler>()
	var controllableActions = new HashMap<String, MonitorControlCompiler>
	var resetActions = new ArrayList<ResetEvent>

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		var model = resource.allContents.toIterable.filter(typeof(MDPModel)).findFirst[it !== null]
		fsa.generateFile("prism/" + model.name + ".prism", resource.compilePrismModel)
		var stateMap = createStateMapping(resource.allContents.toIterable.filter(typeof(State)))
		fsa.generateFile("jmarkov/" + model.name + ".jmdp", resource.compileJMarkovInputFile(stateMap))
		resetData
		parseObserveMappings(resource.allContents.toIterable.filter(typeof(ObservableMap)))
		parseControlMappings(resource.allContents.toIterable.filter(typeof(ControllableMap)))
		parseResetEvents(resource.allContents.toIterable.filter(typeof(ResetEvent)))
		fsa.generateFile("test-harness/EventHandler.aj", resource.compileEventHandler(model.sampleSize, model.policy, model.termination))	
	}
	
	def compilePrismModel(Resource resource) '''
		mdp
		
		module sutModel
		
			«compileStates(resource.allContents.toIterable.filter(typeof(State)).clone)»
			
			«compileTransitions(resource.allContents.toIterable.filter(typeof(Arc)), createActionMap(resource.allContents.toIterable.filter(typeof(Arc))), createStateMap(resource.allContents.toIterable.filter(typeof(State))))»	
			
		endmodule
	'''
	
	def compileStates(State[] states) '''
		s : [0..«states.size-1»] init «initialState(states)»;
		«FOR s: states»
			«FOR p: s.label»
				«p.name» : bool init «IF indexOf(s.name) == initialState(states)»true«ELSE»false«ENDIF»;
			«ENDFOR»
		«ENDFOR»
	'''
	
	def initialState(State[] states) {
		for(State s: states) {
			if(s.initial)
				return indexOf(s.name)
		}
		return 0
	}
	
	def indexOf(String stateName) {
		return Integer.parseInt(stateName.substring(1))
	}
	
	def compileTransitions(Iterable<Arc> arcs, HashMap<SimpleEntry<Integer, String>, ArrayList<Arc>> actionMap, HashMap<Integer, State> stateMap) '''
		«FOR SimpleEntry<Integer, String> entry: actionMap.keySet»
			[«entry.value»] s=«entry.key»«FOR p: stateMap.get(entry.key).label» & «p.name»=true«ENDFOR»«FOR Arc a: actionMap.get(entry) BEFORE ' -> ' SEPARATOR ' + ' AFTER ';'»«a.probability»:(s'=«indexOf(a.dst.name)»)«FOR p: setMinus(a.src.label, a.dst.label)» & («p.name»'=false)«ENDFOR»«FOR p: a.dst.label» & («p.name»'=true)«ENDFOR»«ENDFOR»
		«ENDFOR»
	'''
		
	def setMinus(EList<AtomicProposition> list1, EList<AtomicProposition> list2) {
		var result = new ArrayList<AtomicProposition>
		for(AtomicProposition p: list1) {
			if(!list2.contains(p))
				result.add(p)
		}
		return result
	}
	
	def createActionMap(Iterable<Arc> arcs) {
		var actionMap = new HashMap<SimpleEntry<Integer, String>, ArrayList<Arc>>
		for(Arc a: arcs) {
			var entry = new SimpleEntry<Integer, String>(indexOf(a.src.name), a.act.name)
			if(actionMap.containsKey(entry))
				actionMap.get(entry).add(a)
			else {
				var arcList = new ArrayList<Arc>
				arcList.add(a)
				actionMap.put(entry, arcList)
			}
		}
		return actionMap
	}
	
	def createStateMap(Iterable<State> states) {
		var map = new HashMap<Integer, State>
		for(State s: states)
			map.put(indexOf(s.name), s)
		return map
	}
	
	def HashMap<String, Integer> createStateMapping(Iterable<State> states) {
		var result = new HashMap<String, Integer>()
		var i = 1
		for(State s: states)
			result.put(s.name, i++)
		return result
	}
	
	def compileJMarkovInputFile(Resource resource, HashMap<String, Integer> stateMap) '''
		«FOR state: resource.allContents.toIterable.filter(typeof(State))» «state.name»«IF state.initial» i«ENDIF»«IF state.prior.size > 0» u«ENDIF»,«ENDFOR»
		«FOR arc: resource.allContents.toIterable.filter(typeof(Arc))»
			«arc.src.name» «arc.act.name» «arc.dst.name» «arc.probability»«IF arc.src.prior.size > 0 && arc.src.prior.get(0).act.name == arc.act.name» u«ENDIF»
		«ENDFOR»
	'''
	
	def compileEventHandler(Resource resource, int sampleSize, Policy policy, Termination termination) '''
		package it.unimi.di.se.monitor;
		
		import org.slf4j.Logger;
		import org.slf4j.LoggerFactory;
		
		import it.unimi.di.se.decision.DecisionMakerFactory;
		import it.unimi.di.se.decision.Policy;
		import it.unimi.di.se.monitor.Monitor.CheckPoint;
		import jmarkov.jmdp.StringAction;
		import jmarkov.jmdp.SimpleMDP;
		
		import java.io.BufferedReader;
		import java.io.ByteArrayInputStream;
		import java.io.FileNotFoundException;
		import java.io.FileReader;
		import java.util.Map;
		import java.util.HashMap;
		
		import org.aspectj.lang.ProceedingJoinPoint;
		import org.aspectj.lang.annotation.After;
		import org.aspectj.lang.annotation.AfterReturning;
		import org.aspectj.lang.annotation.Around;
		import org.aspectj.lang.annotation.Aspect;
		import org.aspectj.lang.annotation.Before;
		import org.aspectj.lang.annotation.Pointcut;
		
		
		@Aspect
		public class EventHandler {
		    
		    private static final Logger log = LoggerFactory.getLogger(EventHandler.class.getName());
		    static final String MODEL_PATH = "src/main/resources/«resource.URI.lastSegment»";
		    static private final String JMDP_MODEL_PATH = "src/main/resources/«resource.URI.lastSegment.split("\\.").get(0)».jmdp";
		    
		    static final int SAMPLE_SIZE = «IF sampleSize > 0»«sampleSize»«ELSE»2000«ENDIF»;
		    static final Monitor.Termination TERMINATION_CONDITION = Monitor.Termination.«IF termination.type == 'coverage'»COVERAGE«ELSEIF termination.type == 'convergence'»CONVERGENCE«ELSEIF termination.type == 'limit'»LIMIT«ENDIF»;
		    static final double COVERAGE = «IF termination.coverage !== null»«termination.coverage»«ELSE»0.0«ENDIF»;
		    static final double LIMIT = «termination.limit»;
		    public static final double DIST_WEIGHT = «IF policy.distWeight !== null»«policy.distWeight»«ELSE»0.0«ENDIF»;
		    public static final double PROF_WEIGHT = «IF policy.profWeight !== null»«policy.profWeight»«ELSE»0.0«ENDIF»;
		    static final String PROFILE_NAME = «IF policy.profileName !== null»"«policy.profileName.name»"«ELSE»null«ENDIF»;
		    
		    private Monitor monitor = null;
		    private SimpleMDP mdp = null;
		    
		    @Pointcut("execution(public static void main(..))")
		    void mainMethod() {}
		    
		    @Before(value="mainMethod()")
		    public void initMonitor() {
		    		log.debug("MDP Policy computation...");
		   		try {
		   			mdp = new SimpleMDP(new BufferedReader(new FileReader(JMDP_MODEL_PATH)));
		   		} catch (FileNotFoundException e) {
		   			e.printStackTrace();
		   		}
		       	log.debug("Monitor initialization...");
		       	monitor = new Monitor(mdp, Policy.«IF policy.type == 'random'»RANDOM«ELSEIF policy.type == 'history'»HISTORY«ELSEIF policy.type == 'uncertainty-flat'»UNCERTAINTY_FLAT«ELSEIF policy.type == 'uncertainty-hist'»UNCERTAINTY_HISTORY«ELSEIF policy.type == 'distance'»DISTANCE«ELSEIF policy.type == 'profile'»PROFILE«ELSEIF policy.type == 'combined'»COMBINED«ENDIF»);
		       	monitor.launch();
			}
		        
		    @After(value="mainMethod()")
		    public void shutdownMonitor(){
		    		log.debug("Shutting down Monitor...");
		    		monitor.addEvent(Event.stopEvent());
			}
			
			private String getActionFromPolicy() {			
				monitor.addEvent(Event.readStateEvent());
				String stateName = CheckPoint.getInstance().join(Thread.currentThread());
				
				StringAction action = monitor.getDecisionMaker().getAction(Integer.parseInt(stateName.substring(1)));
				log.debug("Selected action = " + action.actionLabel());	
				return String.valueOf(action.actionLabel());
			}
			
			«IF !resetActions.isEmpty»
				«FOR event: resetActions»
					«compileResetEvent(event)»
				«ENDFOR»
			«ENDIF»
			
			«FOR signature: observableMethods.keySet»
				«observableMethods.get(signature).compileAdvices(signature)»
			«ENDFOR»
			
			«FOR signature: controllableActions.keySet»
				«controllableActions.get(signature).compileAdvice(signature)»
			«ENDFOR»
		}
	'''
		
	def compileResetEvent(ResetEvent event) '''
		«var parametersType = new ArrayList<String>»
		«var parametersName = new ArrayList<String>»
		«IF event.arguments !== null && !event.arguments.isEmpty»
			«FOR Arg arg: event.arguments»
				«parametersType.add(arg.type)»
				«parametersName.add(arg.name)»
			«ENDFOR»
		«ENDIF»
		@Before(value="execution(«event.signature.compileSignature(parametersType)»)«parametersName.compileArgs»")
		public void «event.signature.methodName»ResetEvent(«adviceParameters(parametersName, parametersType)») {
			«IF event.argsCondition !== null && !event.argsCondition.isEmpty»
			if(«event.argsCondition») {
				log.debug("Reset initial state...");
				monitor.addEvent(Event.resetEvent());
			}
			«ELSE»
			log.debug("Reset initial state...");
			monitor.addEvent(Event.resetEvent());
			«ENDIF»
		}
	'''
	
	def parseResetEvents(Iterable<ResetEvent> events) {
		for(ResetEvent e: events)
			resetActions.add(e)
	}
	
	def parseObserveMappings(Iterable<ObservableMap> maps) {
		for(ObservableMap m: maps)
			m.parseObserveMapping
	}
	
	def parseObserveMapping(ObservableMap map) {
		var MonitorObserveCompiler compiler
		if(observableMethods.containsKey(map.signature))
			compiler = observableMethods.get(map.signature)
		else {
			compiler = new MonitorObserveCompiler
			observableMethods.put(map.signature, compiler)
		}
		compiler.parse(map)
	}
	
	def parseControlMappings(Iterable<ControllableMap> maps) {
		for(ControllableMap m: maps)
			m.parseControlMapping
	}
	
	def parseControlMapping(ControllableMap map) {
		var MonitorControlCompiler compiler
		if(controllableActions.containsKey(map.signature))
			compiler = controllableActions.get(map.signature)
		else {
			compiler = new MonitorControlCompiler
			controllableActions.put(map.signature, compiler)
		}
		compiler.parse(map)
	}
	
	def resetData() {
		observableMethods.clear
		controllableActions.clear
		resetActions.clear
	}
	
	def compileSignature(String signature, List<String> parametersType) 
	'''«signature.qualifiedMethodName»(«IF !parametersType.empty»«FOR i: 0..< parametersType.size»«IF i>0», «ENDIF»«parametersType.get(i)»«ENDFOR»«ENDIF»)'''
	
	def compileArgs(List<String> parametersName)
	'''«IF !parametersName.empty» && args(«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersName.get(i)»«ENDFOR»)«ENDIF»'''
	
	def adviceParameters(List<String> parametersName, List<String> parametersType)
	'''«IF !parametersName.empty && !parametersType.empty»«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersType.get(i)» «parametersName.get(i)»«ENDFOR»«ENDIF»'''
	
	def qualifiedMethodName(String signature){
		return signature.substring(0, signature.indexOf("("));
	}
	
	def methodName(String signature){
		var method = signature.qualifiedMethodName
		return method.substring(method.lastIndexOf(".")+1)
	}
	
}
