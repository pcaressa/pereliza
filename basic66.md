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

#### GOTO

The infamous jump instruction of Basic66 is `GOTO` (also spelled as `GO TO`). When executed, it makes the program to continue from the line after it: if this line does not exist an error occurs. Thus a `GOTO` alter the usual order of execution of the program stataments, that is dictated by the increasing order of the line numbers. 

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

#### INPUT

#### LET

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





## Eliza In Basic66

When PERELIZA starts, it reads a script and then use it to reply to the user commands. In Basic66, since there's no file facility, the script is contained in a series of `DATA` instructions, that are merged into the program.

The first part of the program reads and parses strings from `DATA` statements that contain the text of the script in its original Lisp form.

A S-expression parser reads the script and use it to fill some arrays used during the transformation process. Therefore, the Lisp-like stuff needed is very limited and easily implemented in Basic, by using numerical arrays.

### The script parser

An ELIZA script has the form of a sequence of S-expressions, where an S-expression can be:

- An atom (identifier in a broad sense: a sequence of non blanks characters not containing parentheses).
- An open parenthesis "(" followed by zero or more S-expressions and by a closed ")" parenthesis.
- Nothing else.

The first S-expressions of the script are printed on the screen at the start of the session, so they can be used to contain welcome messages.

When the `START` atom is parsed, subsequent S-expressions are considered to be keyword definitions.

Recall that the general form of a keyword definition is as follows:

    (keyword = alias rank
        (pattern index rule ...)
        ...)

where `rank` can be omitted (defaulting to 0), `index` is usually omitted (defaulting to 1) and also the `= alias` part is optional.

Each word read by the parser is stored in the word dictionary, a string vector dimensioned as

    LET W0 = 2^12 - 1
    DIM W$(W0)

This is actually a hash table. When a word is parsed, a simple hash `H` is computed for it, so to address an element `W$(H)` of the dictionary. If the `W$(H)` is empty, the word is inserted in it, else a collision check is performed and, on collision, `W$(H)` is substituted with `W$(H)` concatenated with a space, concatenated with the new word, and the hash of the latter is `H + I/100` being `I` the index of the word inside the element `W$(I)`. Since collisions should be very few, this should suffice to handle them properly.

When a word is a keyword, its hash is copied into the `K()` matrix, which is a stack where new keywords are added along with pointers to their description. The matrix K() is defined as

    LET K0 = 128
    DIM K(K0, 3)

where, given a keyword of hash `H`, an item describing it in the `I`-th row of `K` is

- `K(I,0) = H`
- `K(I,1) =` hash of the alias, or -1 if there's no alias.
- `K(I,2) =` rank of the word (0 if there's no rank).
- `K(I,3) =` index of S-expression defining it.

S-expressions are stored in matrix as pairs (head, tail) where both head and tail can be:

- A word.
- A special character (=, *, /, 0, ...).
- A pointer to a S-expression.
- The NIL pointer.

The S() matrix contains such pairs, being defined as

    LET S0 = 4096
    DIM S(S0, 2)

A pair (head, tail) is stored in an item of index `I` of `S()` as

- `S(I,0) =` a code denoting the type of both head and tail.
- `S(I,1) =` head.
- `S(I,2) =` tail.

Codes are of the form `C1 + 16*C2` where `C1` and `C2` refer to the head or tail and are integers between 0 and 15 as follows:

- 0 means NIL
- 1 means hash of a word in W$()
- 2 means address of a pair in S()
- 3 means = 
- 4 means *
- 5 means /
- 6 means 0 
- 7 means 1
- 8 means 2
- 9 means 3
- 10 means 4
- 11 means 5
- 12 means 6
- 13 means 7
- 14 means 8
- 15 means 9

Digits are used to refer to items in a pattern.

For example, the S-expression

    ((0 ME) (WHY YOU SAY 1 YOU))

which, written in the (head tail) notation is

    ((0 ME) (WHY (YOU (SAY (1 YOU)))))

is represented as

    S(I)   = (2+16*2, I+1, I+2)
    S(I+1) = (6+16*1, 0, H0)
    S(I+2) = (1+16*2, H1, I+3)
    S(I+3) = (1+16*2, H2, I+4)
    S(I+4) = (1+16*2, H3, I+5)
    S(I+5) = (7+16*1, 0, H2)

where H0, H1, H2, H3 are the hash codes of ME, WHY, YOU, SAY. Notice that, in a more constrained system, one could represent values S(I,0) just as single bytes.

There is a special feature to keep into account when parsing the S-expression associated to a list of pattern/rules: a pattern of the form (=keyword) means a pointer to the list of pattern-rules of that keyword.

### The conversation engine

Once the script has been parsed with no errors, control passes to the conversation engine, which loops through a sequence of question/answer where the question is prompted by ELIZA and the answer given by the user.

The string with the answer is tokenized, thus words are recognized by looking for delimiters, such as spaces, commas etc. With the exception of spaces, delimiters are considered single words, too. In particular, if no keyword is parsed before a dot or comma, the text in the answer is deleted, and the same occurs for the text following such a sign when a keyword is parsed. In this way, the reply of ELIZA will focus only on the sentence containing the chosen keyword.


