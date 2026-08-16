# BASIC66

## A version of Dartmouth Basic in your browser

### Paolo Caressa

#### Version 1.0 - August 2026

## Intro

One of the cornerstone of computer science was doubtfully the BASIC programming language, designed and implemented by John Kemeny and Thomas Kurtz in 1964: it was the first language ever conceived to be simple, interactive, addressed to anyone. Within a decade, it became the language of microcomputers, the first language ever learnt from generations of programmer, either for hobby or for job.

Basic66 is a more or less faithful implementation of Basic as it was between 1966 and 1967: it contains the same facilities of the Basic as described in the 1968 version of the manual (the so called "Basic the 4th") with the important exceptions of:

- No matrix statements.
- No user defined functions.
- Data inserted interactively is collected one item for line, while in Dartmouth Basic one can have several items on a same line separated by commas.

The system maintains a source program at the time, which can be saved and loaded from the disk via the browser interface (see below), and which the Basic66 compiler compiles to JavaScript, ready to be executed.

I wrote this compiler for fun (indeed no AIs were harmed, I coded by hands and brain, so forgive the bugs and bad style) as a html page with a JavaScript embedded ready to run: actually, I needed a retro-envinronment in which to program a version of the classic ELIZA chatbot implemented by Weienbaum in 1966, and I wanted a language of that time (the natural choice would be Lisp).

Anyway, here it is, hope you'll enjoy it.

## The Time Sharing interface

To launch Basic66, just open the html file `basic66.html` in your browser. A black window with some printings in green will appear, displaying something like

    BASIC66 - A DARTMOUTH BASIC DIALECT
    (C) 2026 BY PAOLO CARESSA
    TERMINAL ON AT SAT AUG 15 2026
    READY
    >|

The `>` sign is the user prompt
Now you can insert commands to edit, save, load or launch a Basic program: they are the classic DTSS terminal commands. A single source file can be dealt with at the time: to create a new one, type

    >NEW name

An empty file is created. Such a file has lines indexed by integer numbers between 1 and 9999. To enter a new line, write its number followed by the text of the line, for example

    >10 PRINT 0

To replace this line with another one, just use the same number:

    >10 PRINT 10

You'll notice that characters are capitalized: we use a system with only capital letters available. To delete a line just type its number and press return.

After a while, you'll want to see the program ordered according to the line numbers: to do that type `LIST` which will print some twenty lines, then ask for a key to be pressed, and so on, until all the program has been listed. One can also specify the first or the last line to list (or both), with `LIST n1-n2` being `n1` and `n2` the first and last line to list, both being optional (of course, if `n1` is omitted, as in `LIST -200`, then it is assumed that `n1` is the first line, while if `n2` is omitted, as in `LIST 200-`, it is assumed that `n2` is the last line).

To save the program just type `SAVE` (the name of the program has been declared in the `NEW` statement), while to load a saved program, use `OLD`: notice, that `OLD` actually interprets the lines of the text file read as if they were inserted interactively, so you can use it to execute batch programs, or simply to insert the lines of a Basic program. Before doing that, `OLD` destroys the current program. If you want to preserve it, use `MERGE` instead.

To run the program, just type `RUN`: this actually compiles the program and then executes it. You can accomplish both tasks separately, by the commands `BASIC`, that compiles the program in an inner file that you can peruse with `CODE` (that acts like `LIST` for the source code, included the possibily to list only a part of the code), and `EXEC`, that executes the current code. After the execution, especially if some error occurs, you can look the contents of the program's variables by the `VARS` command (all those commands are not in the original Basic systems, I needed them to perform debug and left them in the program).

A program can be loaded also by drag-dropping it into the window.

## The Basic66 language

Basic was a very simple yet effective programming language: it lacked most features nowadays considered essential, like local variables in subroutines, etc. It resembled assembly in several respects, borrowing from Fortran.

Basic66 allows the following data types:

- Numbers (aka scalars).
- Strings.
- Vectors of numbers.
- Vectors of strings.
- Matrices of numbers.

Numbers and strings are not declared but directly assigned, as in Python. For example, consider

    10 LET X = 128
    20 LET Y = (X + 1)*(X-1)
    30 LET R = SQR(X^2 + Y^2)
    99 END

Notice that a program should always end with the `END` instruction which should be the last one (else an error occurs). This program defines three variables, assigning to them values. The `^` operator means raising to the power, while `SQR` means "squared root".

As prescribed by Kemeny and Kurtz, each Basic statement should start with a keyword, so to assign a new value to an already defined variable you cannot use `X = ...` but still `LET X = ...`.

All variables are set to zero at start, but their values can be changed by the `LET`, `READ` or `CHANGE` statement. Thus, there's no `UNDEFINED VARIABLE` error, any mentioned numerical variable exists with value zero at start, and any mentioned string variable exists with value the empty string at start.

Strings can be assigned from string constants or string variables: there is no concatenation operator, as in later Basics, but it can be simulated via the `CHANGE` statement.

String variables must have a `$` suffix, moreover variable's names can be letters possibly followed by a digit (actually the compiler accepts any alphanumerical sequence not starting by a digit, another apocryphal feature, since in 1966 Basic did not allowed it).

Vector and matrices, instead, should be declared in advance by a `DIM` statement, of the form

    DIM v(i1,i2), w(j1,j2), ...

where i2, j2, ... may be omitted and, in this case, v, w, ... can be string variables.

After dimensioning, one can refer to an element of a vector or matrix by the functional notation `v(e1,e2)`. For example, this program fills a vector.

    10 DIM V(10)
    20 FOR I = 1 TO 10
    30 LET V(I) = I^2
    40 NEXT I
    99 END

If you use a non dimensioned vector or matrix, an error occurs, but if you try to assign a value to an element of it, then it is assumed that it is a vector with 10 elements, or a matrix with 10x10 elements. Thus, the previous example could be written in worse style as

    10 REM LINE 30 MAKES AN IMPLICIT DIM V(10) DECLARATION
    20 FOR I = 1 TO 10
    30 LET V(I) = I^2
    40 NEXT I
    99 END

Among numbers, the usual arithmetical operations are allowed. Number or string comparisons are allowed only inside `IF` statements, and are the usual ones: `=`means equality, `<>` means inquality, `<`, `<=`, `>`, `>=` have the usual meaning for numbers and strings as all current programming languages.

To deal with strings, Basic66 dwells upon a single statement, the `CHANGE` one. One can use this instruction to convert a string into a numerical vector, which contains the ASCII code of the string characters from index 1 to the string length, while the 0-th element of the vector contains the string length. The statement

    CHANGE X$ TO V

accepts a string `X$` and a vector `V`, which should have dimension at least the length of the string: after the change, `V(0)` contains the string length, and `V(1)...V(N)` contain the ASCII code of the string characters. To convert such a vector into a string, of course one uses

    CHANGE V TO X$

For example, to concatenate two strings one can do the following:

    10 LET X$ = "PER"
    20 LET Y$ = "ELIZA"
    30 DIM V1(LEN(X$) + LEN(Y$)), V2(LEN(Y$))
    40 CHANGE X$ TO V1
    50 CHANGE Y$ TO V2
    60 FOR I = 1 TO LEN(Y$)
    70 LET V1(LEN(X$) + I) = V2(I)
    80 NEXT I
    90 LET V1(0) = LEN(X$) + LEN (Y$)
    100 CHANGE V1 TO X$
    200 PRINT X$
    999 END

### Basic66 statements

#### Constants, expressions and relations

Constants can be numerical ones, in the usual decimal (possibly with exponential part) format, and strings, enclosed between double quotes (double quotes cannot be quoted inside a string).

Constants aside, there are the following operands:

- Variables, which are just a variable identifier (a letter, possibly followed by a digit, possibly followed by a dollar sign), followed by one or two comma separated numerical expressions in case of vector or matrix variable.
- Subexpressions, thus expressions enclosed between parentheses.
- Function evaluation, thus a built-in function name (such as `SIN` or `CHR$`) followed by an operand (typically a subexpression) with the only exception of `RND` which accepts no parameter and behaves like a variable, although it provides every time a different value, more or less uniformly distributed among 0 and 1.
- Negations, thus the minus sign followed by a numerical operand.

Available built-in functions are:

- `ABS x` that computes the absolute value of number `x`.
- `ASC s` that computes ASCII code of the first character of string `x`.
- `ATN x` that computes the inverse function of the tangent of `x`.
- `CHR$ x` that computes the one-character string corresponding to ASCII code `x`.
- `COS x` that computes the cosine of `x`.
- `EXP x` that computes the exponential of `x`.
- `INT x` that computes the integer part of `x` (the so called *floor* function).
- `LEN s` that computes the length of string `s`.
- `LOG x` that computes the natural logarithm of `x`.
- `RND` that provides a pseudo-random number.
- `SGN x` that returns -1, 0 or 1 whether `x < 0`, `x = 0` or `x > 0`.
- `SIN x` that computes the sine of `x`.
- `SQR x` that computes the squared root of `x`.
- `TAN x` that computes the tangent of `x`.

Operands can be connected by binary operators to form expressions, the operators being the usual arithmetical ones: `+ - * / ^`, the latter denoting the raising of its left parameter to the second one.

#### CHANGE

The general form of this statement is

    CHANGE v1 TO v2

where `v1` and `v2` are a string variable and a vector variable, or a vector variable and a string variable. In the first case, for example `CHANGE X$ TO V`, both variables `X$` and `V` should exist, else an error is raised; in the second case, for example `CHANGE V TO X$`, the array `V` should exist, while the string `X$` should not, and in this case it is defined by the `CHANGE` statement.

#### DATA, READ and RESTORE

The compiler reserves a read only memory area to collect a list of constants, which may be number of strings. Such constants are declared by a `DATA` statement which contains a comma separated list of numbers or strings, that are stored in the memory area in the order in which the `DATA` statements appear along the program.

So a `DATA` statement produces no code. Instead, the `READ` statement can be used to read those data, in the order in which they appear. For example, consider

    10 DATA 2, "A", "AB"
    20 READ X, A$, B$
    30 DATA "C", "CD", 3
    40 READ C$, D$
    50 PRINT A$, B$, C$, D$
    60 READ Y
    70 PRINT X + Y
    90 END

Lines 10 and 30 contains data, that are stored in the memory area as a list `[2, "A", "AB", "C", "CD", 3]`. When the first `READ` statement is executed, line 20, it reads a number and two strings, storing them in the variables `X`, `A$` and `B$` respectively. The subsequent `READ` statement, line 40, expects two strings, indeed it parses `"C", "CD"` from the memory area, storing them respectively into variable `C$` and `D$`. Lastly, at line 60, the last item of the memory area, `3`, is read and assigned to variable `Y`.

On running the program, one has the output

    A              AB             C              CD
    5

Would we add another READ statement, there would be no more data to parse in the memory area: for example, on adding

    80 READ X

we would get

    A              AB             C              CD
    5
    OUT OF DATA IN 80

Notice that a same variable can be read time and again in a `READ` statement, that has the same effect of an assignment where the assigned value is taken from the first unread element of the data memory area.

Of course, the type of a variable and the one of the correponding data read have to match, else a type mismatch error occurs.

One can reset the pointer to the next data item by the `RESTORE`statement, after which a `READ` statement will start parsing the data sequence from the beginning.

#### DIM

#### FOR and NEXT

#### GOTO and ON

The infamous jump instruction of Basic66 is `GOTO` (also spelled as `GO TO`). When executed, it makes the program to continue from the line after it: if this line does not exist an error occurs. Thus a `GOTO` alter the usual order of execution of the program stataments, that is dictated by the increasing order of the line numbers.

The `ON` statement can be used if one could jump to different lines according to the integer part of the value of an expression:

    ON e GOTO l1, ..., ln

The expression `e` is computed and it should result in a number, which is truncated to an integer `i`: if `i < 1` or `i > n`, then an error is issued, else a `GOTO li` is performed. 

#### GOSUB and RETURN

When a chunk of code is to be used time and again in a program, one can put it into a subroutine, thus a piece of code ending with a `RETURN` instruction. To execute the subroutine, one uses the statement `GOSUB x`, being `x` the line number of the first instruction of the subroutine. This has the effect of a `GOTO x`, with the important difference of remembering the line number of the `GOSUB` instruction. When `RETURN` is executed, it is like a `GOTO` to the instruction immediately following the `GOSUB`.

For example

    10 LET X = 10
    20 LET Y = 20
    30 GOSUB 100
    40 PRINT X
    50 STOP
    100 LET X = X + Y
    110 RETURN
    999 END

This program is equivalent to 

    10 LET X = 10
    20 LET Y = 20
    30 GOTO 100
    40 PRINT X
    50 STOP
    100 LET X = X + Y
    110 GOTO 40
    999 END

However, had we used the subroutine more than one time, this equivalence break: indeed

    10 LET X = 10
    20 LET Y = 20
    30 GOSUB 100
    33 GOSUB 100
    36 GOSUB 100
    40 PRINT X
    50 STOP
    100 LET X = X + Y
    110 RETURN
    999 END

cannot easily be substituted by a program containing only `GOTO`s, since the `RETURN` instruction at line 110 jumps each time to a different line, to resume the execution after the subroutine has been executed.

There are no local variables in Basic, so you should pay attention to avoid conflicts between variables used in a subroutine and in the main program. Of course, a subroutine can call other subroutines in turn.

#### IF

In Basic66, decisions are taken with the `IF` instruction, whose form is

    IF e1 rel e2 THEN line

where `e1` and `e2` are expressions of the same type (thus, both numerical or both string) and `rel` is one of `< = > >= <> <=` meaning respectively "less, equai, greater, greater or equal, different, less or equal" according to the usual order relation between numbers and the lexicographic order between strings (where single characters are ordered according their ASCII code, e.g. "0" < "A").

When the statement is executed, the expressions are evalued and the relation among them checked: if the relation holds true, then `GOTO line` is executed, else nothing is done and the execution flow proceed to the statement following `IF`.

#### INPUT

The input statements is used to get data interactively from the terminal during the program execution: whenever the instruction

    INPUT v1, ..., vn

is executed, being `v1`, ..., `vn` variables (either numbers or strings, not vector or matrices), the terminal prompt the user for a line of text which is interpreted either as a number or as as string, according to the variable type.

For example:

    10 DIM N$(20), S$(20)
    20 PRINT "NUMBER OF PEOPLE";
    30 INPUT L
    40 FOR I = 1 TO L
    50 PRINT "NAME AND SURNAME";
    60 INPUT N$(I), S$(I) 
    60 NEXT I
    99 END

Notice that we can get values for array elements.

#### LET

By the `LET` statement, a new value is assigned to a variable, or to an element of a vector or matrix variable: the formats are:

    LET v = e
    LET v(e1) = e2
    LET v(e1,e2) = e3

Where subscript appears, they have to be expressions resulting in numbers, whose non integer part is drop to transform them into array indexes. If an index if out of range, then an error occurs, as when the variable is quoted, to retrieve its current value, inside an expression.

#### PRINT

#### END, STOP, REM

Any program should end with the `END` statement on the last line, else the compilation terminates with an error. The `STOP` instruction is the same as a `GOTO x` being `x` the line number of the `END` instruction. The `REM` statement is ignored, so after `REM` you can insert a comment.

Comments can also start anywhere by a single quote, which let the rest of the line to be ignored by the compiler.

### Differences from the actual Dartmouth Basic

This implementation of Basic was programmed purposely to have a language in which to implement ELIZA, so it is not a strict implementation of Dartmouth Basic. Hereinafter, I list the main differences.

- The `PRINT` and `INPUT` statements were more flexible in Dartmouth Basic, I implemented the bare minimum needed to ELIZA.
- The `MAT` family of statements, that allowed to deal with vector and matrices in a very simple way, are not implemented in Basic66.
- The `DEF` statement is not implemented.
- A string in a `DATA` statement should always enclosed between double quotes in Basic66, while this is not true in Dartmouth Basic, unless the string can be confused with a number or a series of comma separated data.

File handling was not available in Dartmouth Basic in 1966 and, a fortiori, it is not in Basic66.

### Implementation in JavaScript

Since Basic66 was just addressed at getting an environment in which to program PERELIZA, its design and implementation heavily relied on the KISS principle.

In the first place, the JavaScript program runs on a naked web page where a simple terminal line is simulated. A global object `rt` contains all runtime data needed to run both the terminal RELP and the Basic compiler.

The source code is arranged in an object `rt.source` whose keys are line numbers and whose values are the texts of lines corresponding to those numbers. Thus, the program

    10 LET X = 10
    20 PRINT X

is stored as `{10: "LET X = 10", 20: "PRINT X"}`. The compiler, which can be invoked via the `BASIC` command or via the `RUN` command, compiles the program line-by-line, into an object `rt.code` which has exactly the same keys as the source program but that, instead, has JavaScript asynchronous functions as values, each function containing code that compiles the corresponding source program line.

For example, the previous program, when compiled, will result in the following object assigned to `rt.code`:

    {
    10: (async function anonymous() {
        if(!rt.vars.X)rt.vars.X={d1:0,d2:0,value:[0]};rt.vars.X.value[0]=10;
    }),
    20: (async function anonymous() {
        let p='';p+=(()=>{if(!rt.vars.X)throw"UNDEFINED VARIABLE @ 20";return rt.vars.X.value[0];})();rt.out.push(p);TTY_Refresh(rt);
    })
    }

When the compiled code is executed, via the `EXEC` command or via the `RUN` command, the ordered list of all program's line numbers (which are the same both for the source and the code) is created into `rt.lines`, and an instruction pointer `rt.ip` is set to 0. Then, the function `rt.code[rt.lines[rt.ip]]()` is executed, the pointer updated to the next instruction (some functions can alter its value for example when a `GOTO` is compiled) and this cycle continues until an error occurs or the `rt.ip` counter exceeds the limits of the `rt.lines` array.

During program's execution, the object `rt.vars` contains all variables defined by the program: each variable is stored with the key being its name, with the suffix "@" in case of an array, and its value being the variable's value in case of a scalar, or an object with three attributes in case of an array:

- `name.d1` which is the number of rows of the object (0 for a scalar).
- `name.d2` which is the number of column of the object (0 for a vector).
- `name.value` which is an array of (1+d1)*(1+d2) numbers or strings, according to the type of the variable (decided by the last character of `name`).

