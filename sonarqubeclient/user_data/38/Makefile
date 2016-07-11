
sonar:
	javac -encoding utf8 -d bin -cp ".:./lib/*:$CLASSPATH" src/*.java
	java -javaagent:./lib/org.jacoco.agent-0.7.6.201602180812-runtime.jar=includes=MyRule54CA,excludes=MySpecificTest,output=file,destfile=./reports/jacoco.exec -cp ".:./bin:./lib/*:$CLASSPATH" MyTestRunner
	/opt/sonar-scanner-2.6.1/bin/sonar-scanner -Dsonar.projectKey=PTest111 -Dsonar.projectName=PTest111 -Dsonar.projectVersion=1.2 -Dsonar.sources=./src/ -Dsonar.language=java -Dsonar.sourceEncoding=UTF-8 -Dsonar.jacoco.reportPath=./reports/jacoco.exec -Dsonar.java.binaries=./bin/ -Dsonar.java.test.binaries=./bin/ -Dsonar.java.test.libraries=./lib/*.jar -Dsonar.java.libraries=./lib/*.jar -Dsonar.inclusions=**/MyRule54CA.java,**/MySpecificTest.java -Dsonar.coverage.exclusions=**/MySpecificTest.java

clean:
	rm -rf ./bin/*.class ./reports/*
	touch ./reports/jacoco.exec
