package it.unimi.di.se.mdp.generator

import it.unimi.di.se.mdp.mdpDsl.ObservableMap
import java.util.HashMap
import java.util.ArrayList

class AfterCompiler extends ObservableActionCompiler {
	
	var returnType = ''
	var postconditions = new HashMap<String, ArrayList<ObservableMap>> // srcState -> {argsCondition, arc, postCondition}
	
	private final static String POSTCONDITION_MSG = "*** PRE-/POST- CONDITION VIOLATION ***"
	
	def addPostcondition(String state, ObservableMap mapping){
		var conditions = new ArrayList<ObservableMap>
		if(!postconditions.containsKey(state)) {
			conditions.add(mapping)
			postconditions.put(state, conditions)
		}
		else {
			conditions = postconditions.get(state)
			conditions.add(mapping)
		}
		if(mapping.postcondition.returnType !== null && !mapping.postcondition.returnType.isEmpty)	
			returnType = mapping.postcondition.returnType
	}
	
	override compileAdvice(String signature) '''
		«IF !events.empty || !postconditions.empty»
			
			@AfterReturning(value="execution(«signature.compileSignature»)«compileArgs»"«IF !returnType.empty», returning="result"«ENDIF»)
			public void «signature.methodName»AfterAdvice(«adviceParameters»«IF !returnType.empty»«IF !parametersName.empty», «ENDIF»«returnType» result«ENDIF») {
				
				long timeStamp = System.currentTimeMillis();
				monitor.addEvent(Event.readStateEvent());
				String currentMonitorState = CheckPoint.getInstance().join(Thread.currentThread());
				
				«signature.compileEvents»
				«compilePostconditions(POSTCONDITION_MSG)»
				
				monitor.addEvent(Event.readStateEvent());
				CheckPoint.getInstance().join(Thread.currentThread());
			}
		«ENDIF»
	'''
	
	def compilePostconditions(String message) '''
«««		«IF !postconditions.keySet.isEmpty»
«««			
«««			boolean condition = true;
«««			«var i = 0»
«««			«FOR String state: postconditions.keySet»
«««				«IF state.hasPostCondition»
«««					«IF i++ > 0»else «ENDIF»if(monitor.currentState.getName().equals("«state»")) {
«««					«var j = 0»
«««					«FOR ObservableMap m: postconditions.get(state)»
«««						«IF m.postcondition !== null»
«««							«IF j++ > 0»    else if«ELSE»	if«ENDIF»(«m.argsCondition»)
«««									condition &= «m.postcondition.expression»;
«««						«ENDIF»
«««					«ENDFOR»
«««					}
«««				«ENDIF»
«««			«ENDFOR»
«««			if(!condition)
«««				log.error("«message»");
«««		«ENDIF»
		else
			log.error("«message»");
	'''
	
	def hasPostCondition(String state) {
		for(ObservableMap m: postconditions.get(state))
			if(m.postcondition !== null)
				return true
		return false
	}
	
}
