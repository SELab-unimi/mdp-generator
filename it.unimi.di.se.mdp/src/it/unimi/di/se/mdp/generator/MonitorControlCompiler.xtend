package it.unimi.di.se.mdp.generator

import java.util.ArrayList
import it.unimi.di.se.mdp.mdpDsl.ControllableMap
import it.unimi.di.se.mdp.mdpDsl.Arg

class MonitorControlCompiler {
	
	// states
	var private states = new ArrayList<String>
	
	// arg type and name are paired by position: {<parametersType[0], parametersName[0]>, ..., <parametersType[n], parametersName[n]>}
	var private parametersName = new ArrayList<String>
	var private parametersType = new ArrayList<String>
	
	def parse(ControllableMap map) {
		if(map.arguments !== null && !map.arguments.isEmpty)
			for(Arg a: map.arguments)
				addParameter(a.name, a.type)
		if(!states.contains(map.state.name))
			states.add(map.state.name)
	}
	
	def addParameter(String name, String type) {
		if(!parametersName.contains(name) && !parametersType.contains(type)){
			parametersName.add(name)
			parametersType.add(type)	
		}
	}
	
	def compileAdvice(String signature) '''
		@Around(value="execution(«signature.compileSignature»)«compileArgs»")
		public Object «signature.methodName»Control(ProceedingJoinPoint thisJoinPoint«adviceParameters») throws Throwable {
			Object[] args = thisJoinPoint.getArgs();
			for(int i=0; i<args.length; i++)
				if(args[i] instanceof java.io.InputStream) {
					args[i] = new ByteArrayInputStream(getActionFromPolicy().getBytes());
					break;
				}
			
			return thisJoinPoint.proceed(args);
		}
	'''
	
	def compileSignature(String signature) 
	'''«IF !parametersType.empty»«signature.qualifiedMethodName»(«FOR i: 0..< parametersType.size»«IF i>0», «ENDIF»«parametersType.get(i)»«ENDFOR»)«ENDIF»'''
	
	def compileArgs()
	'''«IF !parametersName.empty» && args(«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersName.get(i)»«ENDFOR»)«ENDIF»'''
	
	def adviceParameters()
	'''«IF !parametersName.empty && !parametersType.empty»«FOR i: 0..< parametersName.size», «parametersType.get(i)» «parametersName.get(i)»«ENDFOR»«ENDIF»'''
	
	def qualifiedMethodName(String signature){
		return signature.substring(0, signature.indexOf("("));
	}
	
	def methodName(String signature){
		var method = signature.qualifiedMethodName
		return method.substring(method.lastIndexOf(".")+1)
	}
	
}