THE_CLASSPATH=
PROGRAM_NAME=Test.java
cd JInterface/src
for i in `ls ../lib/*.jar`
  do
  THE_CLASSPATH=${THE_CLASSPATH}:${i}
done

javac -classpath ".:${THE_CLASSPATH}" $PROGRAM_NAME

if [ $? -eq 0 ]
then
  echo "compile worked!"
  java -classpath ".:${THE_CLASSPATH}" Test &
fi

cd ../../
chmod 777 launchErlang.sh
killall epmd
./launchErlang.sh alpha bravo charlie delta echo foxtrott golf hotel india juliette kilo lima mike november oscar papa quebec romeo

