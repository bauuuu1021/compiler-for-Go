# Compiler for μGo

## Environment setup
* Lexical Analyzer (Flex) and Syntax Analyzer (Bison)
    ```
    sudo apt-get install flex bison
    ```
* JVM
    ```
    $sudo add-apt-repository ppa:webupd8team/java
    $sudo apt-get update
    $sudo apt-get install default-jre
    $sudo apt-get install oracle-java8-installer
    ```
## Execute
* compile
    ```
    make
    ```
* run benchmark
    * to run specified file <file_name>
        ```
        make FILE="<file_name>" test
        ```
    * or run default benchmark : input/basic_declaration.go
        ```
        make test
        ```

## Feature
* Basic features 
    * [x] Handle variable declarations using local variables. (20pt)
    * [x] Handle arithmetic operations for integers and float32. (30pt)
    * [x] Handle the print and println function. (10pt)
    * [x] Handle the if...else if...else statement. (40pt)
* Advanced features (30pt)
    * [x] Handle the for statement. (10pt)
    * [x] Handle the scoping for JVM. (10pt)
    * [ ] Handle user defined function. (10pt)

## Notice
* varables and constant convert into float during arithmetic operation, ie.
    * todo : `3+5`
    * convert to `3.0+5.0`, get answer `8.0`
    * cast back to int type : `8`
* if sentance contains variable with int type, may need to cast it during arithmetic operation, eg.
    * todo : find x
        ```
        var x int = 10
        print(99/x+0.1)
        ```
    * cast `99/x` into int,  get `9` instead of `9.9` 
    * therefore print `9.1` but not `10`
* `STACK_MAX` is defined in `common.h`, this variable is used to set `limit stack` and `limit locals` of jasmin code. The local variable with largest index (ie. STACK_MAX-1) should be reserved as temporary variable because of some arithmetic operation.