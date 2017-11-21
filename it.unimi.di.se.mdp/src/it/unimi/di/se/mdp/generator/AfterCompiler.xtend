package it.unimi.di.se.mdp.generator

import it.unimi.di.se.mdp.generator.WhenCompiler
import java.util.HashMap
import it.unimi.di.se.mdp.mdpDsl.Map

class AfterCompiler extends WhenCompiler {
	
	var postconditions = new HashMap<String, String> // source state -> expression
	var returnType = ''
	
	private final static String POSTCONDITION_MSG = "*** POSTCONDITION VIOLATION ***"
	
	def addPostcondition(String state, String expression, String type){
		postconditions.put(state, expression)
		returnType = type
	}
	
	override compileAdvice(String signature) '''
		«IF !events.empty || !postconditions.empty»
			
			@AfterReturning(value="execution(«signature»)«IF !args.isEmpty» && args(«var i = 1»«FOR String argEntry: args»«argEntry.extractArgName»«IF i++ < args.size», «ENDIF»«ENDFOR»)"«ENDIF»«IF !returnType.empty», returning="result"«ENDIF»)
			public void «signature.methodName»AfterAdvice(«IF !args.isEmpty»«var i = 1»«FOR String argEntry: args»«argEntry.extractArgType» «argEntry.extractArgName»«IF i++ < args.size», «ENDIF»«ENDFOR»«ENDIF»«IF !returnType.empty»«IF args.size > 0», «ENDIF»«returnType» result«ENDIF») {
				«signature.compileEvent»
				«compilePostconditions»
			}
		«ENDIF»
	'''
	
	def compilePostconditions() '''
		«IF postConditionExists»
			
			boolean condition = true;
			«var i = 0»
			«FOR String state: events.keySet»
				«IF state.hasPostCondition»
					«IF i++ > 0»else «ENDIF»if(monitor.currentState.getName().equals("«state»")) {
					«var j = 0»
					«FOR Map m: events.get(state)»
						«IF m.postcondition !== null»
							«IF j++ > 0»    else if«ELSE»	if«ENDIF»(«m.argsCondition»)
									condition &= «m.postcondition.expression»;
						«ENDIF»
					«ENDFOR»
					}
				«ENDIF»
			«ENDFOR»
			if(!condition)
				log.severe("*** POSTCONDITION VIOLATION ***");
		«ENDIF»
	'''
	
}
