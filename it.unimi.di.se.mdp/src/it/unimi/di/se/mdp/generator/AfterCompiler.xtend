package it.unimi.di.se.mdp.generator

import it.unimi.di.se.mdp.generator.WhenCompiler
import java.util.HashMap

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
			public void «signature.methodName»AfterAdvice(«IF !args.isEmpty»«var i = 1»«FOR String argEntry: args»«argEntry.extractArgType» «argEntry.extractArgName»«IF i++ < args.size», «ENDIF»«ENDFOR»«ENDIF»«IF !returnType.empty»«returnType» result«ENDIF») {
				«signature.compileEvent»
				«postconditions.compileConditions(POSTCONDITION_MSG)»
			}
		«ENDIF»
	'''
	
	def compilePostconditions() '''
		«IF !postconditions.empty»
			boolean condition = true;
			«FOR state: postconditions.keySet»
				if(monitor.currentState.getName().equals("«state»"))
					condition &= «postconditions.get(state)»;
			«ENDFOR»
			if(!condition)
				log.severe("*** POSTCONDITION VIOLATION ***");
		«ENDIF»
	'''
	
}
