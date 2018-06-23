# Compiler for μGo

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
    * [ ] Handle arithmetic operations for integers and float32. (30pt)
    * [x] Handle the print and println function. (10pt)
    * [ ] Handle the if...else if...else statement. (40pt)
* Advanced features (30pt)
    * [ ] Handle the for statement. (10pt)
    * [ ] Handle the scoping for JVM. (10pt)
    * [ ] Handle user defined function. (10pt)