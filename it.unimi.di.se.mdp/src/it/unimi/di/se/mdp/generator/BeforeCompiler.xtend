package it.unimi.di.se.mdp.generator

import java.util.ArrayList
import java.util.HashMap
import it.unimi.di.se.mdp.mdpDsl.ObservableMap

class BeforeCompiler extends ObservableActionCompiler {
	
	var preconditions = new HashMap<String, ArrayList<ObservableMap>> // srcState -> {argsCondition, arc, preCondition}
	
	private final static String PRECONDITION_MSG = "*** PRECONDITION VIOLATION ***"
	
	def addPrecondition(String state, ObservableMap mapping){
		var conditions = new ArrayList<ObservableMap>
		if(!preconditions.containsKey(state)) {
			conditions.add(mapping)
			preconditions.put(state, conditions)
		}
		else {
			conditions = preconditions.get(state)
			conditions.add(mapping)
		}
	}
	
	override compileAdvice(String signature) '''
		«IF !events.empty || !preconditions.empty»
			
			@Before(value="execution(«signature.compileSignature»)«compileArgs»")
			public void «signature.methodName»BeforeAdvice(«adviceParameters») {
				
				long timeStamp = System.currentTimeMillis();
				monitor.addEvent(Event.readStateEvent());
				String currentMonitorState = CheckPoint.getInstance().join(Thread.currentThread());		
				log.info("Transition : " + currentMonitorState + "-->" + state.label());
				
				«compilePreConditions(PRECONDITION_MSG)»
				«signature.compileEvents»
			}
		«ENDIF»
	'''
	
	def compilePreConditions(String message) '''
		«IF !preconditions.keySet.isEmpty»
					
			boolean condition = true;
			«var i = 0»
			«FOR String state: preconditions.keySet»
				«IF state.hasPreCondition»
					«IF i++ > 0»else «ENDIF»if(currentMonitorState.equals("«state»")) {
					«var j = 0»
					«FOR ObservableMap m: preconditions.get(state)»
						«IF m.precondition !== null»
							«IF j++ > 0»    else if«ELSE»	if«ENDIF»(«m.argsCondition»)
									condition &= «m.precondition.expression»;
						«ENDIF»
					«ENDFOR»
					}
				«ENDIF»
			«ENDFOR»
			if(!condition)
				log.error("«message»");
		«ENDIF»
	'''
	
	def hasPreCondition(String state) {
		for(ObservableMap m: preconditions.get(state))
			if(m.precondition !== null)
				return true
		return false
	}	
}
