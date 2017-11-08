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
import it.unimi.di.se.mdp.mdpDsl.Map

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class MdpDslGenerator extends AbstractGenerator {
	
	public final static String OBSERVABLE = 'observable'
	public final static String CONTROLLABLE = 'controllable'
	
	var observableMethods = new HashMap<String, MonitorCompiler>()

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		var model = resource.allContents.toIterable.filter(typeof(MDPModel)).findFirst[it !== null]
		//fsa.generateFile("prism/" + model.name + ".sm", resource.compilePrismModel)
		var stateMap = createStateMapping(resource.allContents.toIterable.filter(typeof(State)))
		fsa.generateFile("jmarkov/" + model.name + ".jmdp", resource.compileJMarkovInputFile(stateMap))
		parseMappings(resource.allContents.toIterable.filter(typeof(Map)))
		fsa.generateFile("it/unimi/di/se/monitor/EventHandler.aj", resource.compileEventHandler)
		
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
			«arc.src.name» «arc.act.name» «arc.dst.name» «arc.probability»
		«ENDFOR»
	'''
	
	def compileEventHandler(Resource resource) '''
		package it.unimi.di.se.monitor;
		
		import java.util.logging.Logger;
		
		import org.aspectj.lang.annotation.After;
		import org.aspectj.lang.annotation.AfterReturning;
		import org.aspectj.lang.annotation.Aspect;
		import org.aspectj.lang.annotation.Before;
		import org.aspectj.lang.annotation.Pointcut;
		
		
		@Aspect
		public class EventHandler {
		    
		    private Monitor monitor = null;
		    private static final Logger log = Logger.getLogger(EventHandler.class.getName());
		    static final String MODEL_PATH = "src/main/resources/«resource.URI.lastSegment»";
		    
		    @Pointcut("execution(public static void main(..))")
		    void mainMethod() {}
		    
		    @Before(value="mainMethod()")
		    public void initMonitor(){
		    		log.info("Monitor initialization...");
		    		monitor = new Monitor();
		    		monitor.launch();
			}
		        
		    @After(value="mainMethod()")
		    public void shutdownMonitor(){
		    		log.info("Shutting down Monitor...");
		    		monitor.addEvent(Event.StopEvent());
			}
			«FOR signature: observableMethods.keySet»
			«observableMethods.get(signature).compileAdvices(signature)»
			«ENDFOR»
		}
	'''
	
	def parseMappings(Iterable<Map> maps) {
		for(Map m: maps)
			m.parseMapping
	}
	
	def parseMapping(Map map) {
		if(map.type == OBSERVABLE){
			var MonitorCompiler compiler
			if(observableMethods.containsKey(map.signature))
				compiler = observableMethods.get(map.signature)
			else {
				compiler = new MonitorCompiler
				observableMethods.put(map.signature, compiler)
			}
			compiler.parse(map)
		}
	}
	
}
