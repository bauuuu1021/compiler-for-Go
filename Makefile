CC = gcc -g
YFLAG = -d
FNAME = compiler_hw3
PARSER = myparser
JAVABYTE = Computer
OBJECT = lex.yy.c y.tab.c y.tab.h ${JAVABYTE}.j ${EXE}.class
FILE = input/basic_declaration.go
EXE = main

all: ${FNAME}.y ${FNAME}.l
	@lex ${FNAME}.l
	@yacc ${YFLAG} ${FNAME}.y
	@${CC} -c y.tab.c lex.yy.c
	@${CC} -o ${PARSER} y.tab.o lex.yy.o

test:
	@./${PARSER} < ${FILE}
	@echo -e "\n\033[1;33mmain.class output\033[0m"
	@java -jar jasmin.jar ${JAVABYTE}.j
	@java ${EXE} 

clean:
	rm -f *.o ${PARSER} ${OBJECT} 
