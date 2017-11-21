package it.unimi.di.se.mdp.generator

import java.util.ArrayList
import java.util.HashMap
import it.unimi.di.se.mdp.mdpDsl.Map
import it.unimi.di.se.mdp.mdpDsl.Arg

abstract class WhenCompiler {
	
	public final static String BEFORE = 'before'
	public final static String AFTER = 'after'
	
	protected static final String ARG_SEPARATOR = '#'
	
	var protected events = new HashMap<String, ArrayList<Map>> // src-state -> {args-condition, arc}
	var protected args = new ArrayList<String> // list of argType#argName
	
	def addEvent(Map map){
		var state = map.arc.src.name
		if(!events.containsKey(state)) {
			var mapList = new ArrayList<Map>()
			mapList.add(map)
			events.put(state, mapList)
		}
		else {
			var mapList = events.get(state)
			mapList.add(map)
		}
		if(map.arguments !== null)
			for(Arg arg: map.arguments) {
				var argEntry = createArgEntry(arg.type, arg.name)
				if(!args.contains(argEntry))
					args.add(argEntry)
			}
	}
	
	def methodName(String signature){
		var method = signature.qualifiedMethodName
		return method.substring(method.lastIndexOf(".")+1)
	}
	
	def qualifiedMethodName(String signature){
		return signature.substring(0, signature.indexOf("("));
	}
	
	def compileEvent(String signature) '''
		«IF !events.empty»
			«var i = 0»
			«FOR String state: events.keySet»
				«FOR Map m: events.get(state)»
					«IF i++ > 0»else «ENDIF»if(monitor.currentState.getName().equals("«state»") && «m.argsCondition»)
						monitor.addEvent(new Event("«m.arc.name»", System.currentTimeMillis()));
				«ENDFOR»
			«ENDFOR»
		«ENDIF»
	'''
	
	def compileConditions(HashMap<String, String> conditions, String message) '''
		«IF !conditions.empty»
			
			boolean condition = true;
			«FOR state: conditions.keySet»
				if(monitor.currentState.getName().equals("«state»"))
					condition &= «conditions.get(state)»;
			«ENDFOR»
			if(!condition)
				log.severe("«message»");
		«ENDIF»
	'''
	
	def extractArgName(String argEntry) {
		return argEntry.split(ARG_SEPARATOR).get(1)
	}
	
	def extractArgType(String argEntry) {
		return argEntry.split(ARG_SEPARATOR).get(0)
	}
	
	def createArgEntry(String argType, String argName) {
		return argType + ARG_SEPARATOR + argName
	}
	
	def abstract String compileAdvice(String signature)
}
