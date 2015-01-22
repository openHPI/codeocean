run:
	javac org/example/RecursiveMath.java
	java org/example/RecursiveMath

test:
	javac -cp .:/usr/java/lib/hamcrest-core-1.3.jar:/usr/java/lib/junit-4.11.jar org/example/${FILENAME}
	java -cp .:/usr/java/lib/hamcrest-core-1.3.jar:/usr/java/lib/junit-4.11.jar org.junit.runner.JUnitCore org.example.${CLASS_NAME}
