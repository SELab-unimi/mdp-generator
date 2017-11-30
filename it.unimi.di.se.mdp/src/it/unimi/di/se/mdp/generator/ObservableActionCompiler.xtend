package it.unimi.di.se.mdp.generator

import java.util.ArrayList
import java.util.HashMap
import it.unimi.di.se.mdp.mdpDsl.ObservableMap

abstract class ObservableActionCompiler {
	
	public final static String BEFORE = 'before'
	public final static String AFTER = 'after'	
	protected static final String ARG_SEPARATOR = '#'
	
	// events grouped by src state: srcState -> {argsCondition, arc, preCondition, postCondition}
	var protected events = new HashMap<String, ArrayList<ObservableMap>>
	// arg type and name are paired by position: {<parametersType[0], parametersName[0]>, ..., <parametersType[n], parametersName[n]>}
	var protected parametersName = new ArrayList<String>
	var protected parametersType = new ArrayList<String>
	
	def addEvent(ObservableMap map){
		var state = map.arc.src.name
		if(!events.containsKey(state)) {
			var mapList = new ArrayList<ObservableMap>
			mapList.add(map)
			events.put(state, mapList)
		}
		else {
			var mapList = events.get(state)
			mapList.add(map)
		}
	}
	
	def addParameter(String name, String type){
		if(!parametersName.contains(name) && !parametersType.contains(type)){
			parametersName.add(name)
			parametersType.add(type)	
		}
	}
	
	def methodName(String signature){
		var method = signature.qualifiedMethodName
		return method.substring(method.lastIndexOf(".")+1)
	}
	
	def qualifiedMethodName(String signature){
		return signature.substring(0, signature.indexOf("("));
	}
	
	def compileEvents(String signature) '''
		«IF !events.empty»
		
		«var i = 0»
		«FOR String state: events.keySet»
			«FOR ObservableMap m: events.get(state)»
				«IF i++ > 0»else «ENDIF»if(monitor.currentState.getName().equals("«state»") && «m.argsCondition»)
					monitor.addEvent(new Event("«m.arc.name»", System.currentTimeMillis()));
			«ENDFOR»
		«ENDFOR»
		«ENDIF»
	'''
	
	def compileSignature(String signature) 
	'''«IF !parametersType.empty»«signature.qualifiedMethodName»(«FOR i: 0..< parametersType.size»«IF i>0», «ENDIF»«parametersType.get(i)»«ENDFOR»)«ENDIF»'''
	
	def compileArgs()
	'''«IF !parametersName.empty» && args(«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersName.get(i)»«ENDFOR»)«ENDIF»'''
	
	def adviceParameters()
	'''«IF !parametersName.empty && !parametersType.empty»«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersType.get(i)» «parametersName.get(i)»«ENDFOR»«ENDIF»'''
	
	
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
