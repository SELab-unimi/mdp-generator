package it.unimi.di.se.mdp.generator

import it.unimi.di.se.mdp.generator.WhenCompiler
import it.unimi.di.se.mdp.mdpDsl.Map
import java.util.HashMap
import java.util.ArrayList

class AfterCompiler extends WhenCompiler {
	
	var returnType = ''
	var postconditions = new HashMap<String, ArrayList<Map>> // srcState -> {argsCondition, arc, postCondition}
	
	private final static String POSTCONDITION_MSG = "*** POSTCONDITION VIOLATION ***"
	
	def addPostcondition(String state, Map mapping){
		var conditions = new ArrayList<Map>
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
				«signature.compileEvents»
				«compilePostconditions(POSTCONDITION_MSG)»
			}
		«ENDIF»
	'''
	
	def compilePostconditions(String message) '''
		«IF !postconditions.keySet.isEmpty»
			
			boolean condition = true;
			«var i = 0»
			«FOR String state: postconditions.keySet»
				«IF state.hasPostCondition»
					«IF i++ > 0»else «ENDIF»if(monitor.currentState.getName().equals("«state»")) {
					«var j = 0»
					«FOR Map m: postconditions.get(state)»
						«IF m.postcondition !== null»
							«IF j++ > 0»    else if«ELSE»	if«ENDIF»(«m.argsCondition»)
									condition &= «m.postcondition.expression»;
						«ENDIF»
					«ENDFOR»
					}
				«ENDIF»
			«ENDFOR»
			if(!condition)
				log.severe("«message»");
		«ENDIF»
	'''
	
	def hasPostCondition(String state) {
		for(Map m: postconditions.get(state))
			if(m.postcondition !== null)
				return true
		return false
	}
	
}
