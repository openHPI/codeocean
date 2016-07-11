run:
	javac -encoding utf8 CellularAutomaton.java MyRule54CA.java Main.java
	java Main
	exit

test:

	javac -encoding utf8-Xlint:unchecked -encoding utf8 -cp ".:./mutants.jar:.:/usr/java/lib/hamcrest-core-1.3.jar:/usr/java/lib/junit-4.11.jar:/usr/local/lib/antlr-4.5-complete.jar:/usr/java/lib/antlr-java8.jar:$CLASSPATH" CellularAutomaton.java MySpecificTest.java TestSpecificTests.java Rule54CA.java TestSpecificTestsRunner.java AntlrMain.java Java8Rules.java TestFailedException.java MyRule54CA.java TestSpecificRuns.java

	#java -cp ".:/usr/java/lib/hamcrest-core-1.3.jar:/usr/java/lib/junit-4.11.jar:$CLASSPATH" org.junit.runner.JUnitCore TestSpecificRuns

	java -cp ".:./mutants.jar:.:/usr/java/lib/hamcrest-core-1.3.jar:/usr/java/lib/junit-4.11.jar:/usr/local/lib/antlr-4.5-complete.jar:/usr/java/lib/antlr-java8.jar:$CLASSPATH" TestSpecificTestsRunner

	exit

theirtest:
	javac -Xlint:unchecked -encoding utf8 -cp ".:./lib/hamcrest-core-1.3.jar:./lib/junit-4.11.jar:$CLASSPATH" CellularAutomaton.java MyTestRunner.java MySpecificTest.java MyRule54CA.java

	java -cp ".:./lib/hamcrest-core-1.3.jar:./lib/junit-4.11.jar:$CLASSPATH" MyTestRunner

	exit

clean:

	rm -rf ./*.class
