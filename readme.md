# Per ELIZA

## A strictly useless retro-experiment in programming and AI

### Paolo Caressa

#### Version 1.0 - August 2026

## Foreword

In view of some talks I wanted to give on the occasion of the 60 years of the ELIZA chatbot, a masterpiece in programming and computer-human interactions, I decided to implement my own version. There are some excellent implementations that simulate the original system, but I wanted to code by myself a new one, a perfectly useless task.

Namely, I've decided to program the chatbot in a way that strictly follows Weizenbaum's 1966 CACM paper, using a mid 60s version of the Basic language. When ELIZA was programmed in MAD-SLIP by Weizenbaum, Basic was essentially implemented only in the Dartmouth system, where it was created by Kemeny and Kurtz some two years earlier.

So, I decided to implement a version of the Dartmouth Basic system as it was in the 1966/67, including strings and string vectors, but with just the CHANGE instruction to deal with them. I wrote a compiler for this Basic66 in pure JavaScript to run inside a browser, in the first place.

Next, I decided to implement ELIZA for this Basic dialect by following the description given by Weizenbaum in his classic 1966 paper, at the end of which a script (i.e. a rule database as usual for symbolic AI of those days) was listed. This script is essentially a Lisp description of the rule database, today we would code it in Json. The PERELIZA.BAS program requires the bare text of this script inside a series of strings in DATA instructions, parse them and create inner lists to handle them.

Since the program just needs to read and store the lists resulting from those S-expressions, I did not implemented a complete library for list processing in Basic (although it would be nice to implement a Basic appliance of Weizenbaum Slip language), but just the minimum needed to handle the script and program the answer engine.

In any case, my Basic implementation digests just the same Lisp text that the original Weizenbaum program required.

In this document I describe these useless efforts: as paradoxical as it may seem, no AI has been used neither in writing the code, nor in writing the documentation: this is a programming and coding effort done for fun.

Hope you enjoy, too.
P

## A short description of ELIZA

### A classical rule-based symbolic AI

ELIZA was an interactive chatbot, which means that the main program implemented a REPL asking for a sentence from the user, processing it and providing an answer to be printed, and so on, until some ending condition.

The program did not attempt at an analysis of the sentences typed by the user, but barely applied some transformation to them so to produce the answer, according to a set of rules, specified in a *script*.

A script contains dozens of rules to handle such transformations, and the base principle of those rules is that some *keyword* needs to be singled out in the input sentence: this keyword will determine which transformation to apply. If no keyword could be found, a generic answer will be prompted to the user.

More precisely, to each keyword a set of pairs pattern/transformations is associated and, when the pattern matches the user sentence, one of the corresponding transformations is applied.

Of course, it may happen that several keywords are identified in a single sentence, so the algorithm should have a criterion to choose among them, and the previous order of appearence is not the most suitable. Rather, a ranking is associated to each keyword, and in case of different keywords found in the same sentences, the highest rank one is chosen.

The clever device devised by Weizenbaum to deal with ranks uses a data structure, the *keystack*. Whenever a keyword is parsed in a sentence, its rank is compared to the rank of the keyword pushed on top of the keystack. If the new keyword has rank higher than the topmost keyword already parsed, then the new one is pushed on top of the keystack, else it is placed at the bottom of it.

After the all sentence has been parsed, if the keystack is empty, then a generic answer is chosen and printed, else the topmost keyword is considered and matches are tried for its patterns. If no match can be found, the process continues with the next keyword in the keystack.

ELIZA algorithm is more or less the following:

    Accept a sentence from the user.
    Tokenize the sentence in atoms.
    For each keyword found in the sentence:
        If a pattern associated to the keyword matches the sencence:
            Apply the corresponding rule to produce an answer.
            Print the answer.
            Repeat from the beginning.
    Print a generic sentence.
    Repeat from the beginning.

So, ELIZA was a clever exercise in rewriting rules, whose fundamental idea is to keep the rule engine as simple as possible and to put the "intelligence" of the model in the rule dataset, which in the ELIZA parlance is called a *script*.

### Scripts

A script is a series of Lisp S-expressions that contains atoms and sublists, and that describe the transformation rules associated to a keyword. The general structure of such S-expression is:

    (keyword rank
        ((pattern_{1}) next_{1} (rule_{1,1}) (rule_{1,2}) ... (rule_{1,n_1}))
        ...
        ((pattern_{m}) next_{m} (rule_{m,1}) (rule_{m,2}) ... (rule_{m,n_m})))

Where:

- `keyword` is an atom.
- `rank` is a natural number, if omitted then it is taken to be 0.
- `pattern` is a list containing atoms, representing fixed elements in a sentence, or 0s, representing variable elements in the sentence.
- `next` is a natural number from 1 to the number of rules associated to the pattern, if omitted it is taken to be 1.
- `rule` is a list containing atoms, representing fixed elements in the transformed pattern, and numbers, representing chunks of the pattern itself.

The idea is that, once a keyword has been detected, a rule associated to it is looked for, corresponding to a pattern matching a sentence. If no match can be found, the system looks for another keyword or, if all else fails, uses a generic answer.

When more than one keyword has been detected, ELIZA chooses the one with the highest rank, where the rank is a number which may follow the keyword in the previous S-expression. For example, the rule

    (NAME 15
        ((0)
         (I AM NOT INTERESTED IN NAMES)
         (I'VE TOLD YOU BEFORE, I DON'T CARE ABOUT NAMES - PLEASE CONTINUE)))

assures that the keyword NAME has rank 15 and that, when selected, it has just one pattern to match, (0), which means "match everything" (the 0 is like `(\.)*` in a regular expression) which is associated to two possible transforms, where only constant elements appear. If selected for the first time, the first transform is applied and a 1 number is inserted after the (0). Next time, this number will point to the last used transform, so that the second will be used, and the number updated to 2. Next time, it'll be set to 1 again.

One could think to a random choice as an alternative to select a transform from a set associated to a single pattern, but we stick to Weizenbaum design choices.

When, inside a rule, a number appears, it refers to the item in the pattern: for example, consider

    (IF 3
        ((0 IF 0)
        (DO YOU THINK ITS LIKELY THAT 3)
        (DO YOU WISH THAT 3)
        (WHAT DO YOU THINK ABOUT 3)
        (REALLY, 2 3)))

This rule for the `IF` keyword (which has rank 3), states that, whenever a pattern (0 IF 0) is found, it can generate the following answer:

        DO YOU THINK ITS LIKELY THAT 3

where the 3 means that the third parsed item in the pattern is substituted. For example, the sentence

    SOCRATES IS MORTAL IF SOCRATES IS A MAN

matches the pattern (0 IF 0) where the first 0 matches "SOCRATES IS MORTAL" and the second 0 matches "SOCRATES IS A MAN", so that on applying the rule, the result will be "DO YOU THINK ITS LIKELY THAT SOCRATES IS A MAN".

Some variants of the previous syntax for scripts are allowed to perform special operations. First of all, one can define aliases for keywords, just putting `=` and the alias after the keyword, as in

    (YOUR = MY
        ((0 MY 0)
        (WHY ARE YOU CONCERNED OVER MY 3)
        (WHAT ABOUT YOUR OWN 3)
        (ARE YOU WORRIED ABOUT SOMEONE ELSE'S 3)
        (REALLY, MY 3)))

The equation YOUR = MY means that whenever YOUR is parsed, it is immediately transformed into MY, and this is done before any other processing is performed by the algorithm.

PRE

NEWKEY

DLIST

### The ELIZA algorithm

We can summarize the description of ELIZA by writing the algorithm it executes: I'll use a BASIC-like pseudocode, with jumps instead of control structures (indeed, when Weizenbaum was writing, Bohm and Jacopini paper was still in print).

10. Empty the keystack.
20. Let P = 0.
30. Accept a sentence in input.
40. Parse the next word W from the input.
45. If W has an alias, then substitute W for the alias in the input.
50. If W is the end of the text, then jump to 18.
60. If W = '.' or W = ',' then jump to 14.
70. If W is not a keyword, then jump to 4.
80. If the rank of W is > P, then jump to 11.
90. Push W on the bottom of the keystack.
100. Jump to 4.
110. Push W on the top of the keystack.
120. Let P = rank of W.
130. Jump to 4.
140. If the keystack is not empty, then jump to 17.
150. Delete all words preceding and including W from the text.
160. Jump to 4.
170. Delete W and all words following it from the text.
180. If the keystack is not empty, then jump to 22.
190. Perform the next transform associated to the special keyword NONE.
200. Print the answer.
210. Jump to 1.
220. Pop a keyword K from the keystack.
230. Looks for a pattern matching the current input sentence among the patterns of K.
240. If a match is not found, then jump to 18.
250. Perform the next transform associated to the pattern.
260. Print the answer.
270. Jump to 1.


## Basic66: language and implementation

In 1966 there were different languages that could be used to implement a chatbot such as Eliza, for example Lisp, Snobol, etc. Weizenbaum used a language he himself invented, a variant of MAD with a list processing library Slip.

In this implementation I will use a version of Basic such as the one available when ELIZA was implemented, in 1966.

### The Time Sharing interface

To lanuch Basic66, just open the html file `basic66.html` in your browser. A black window with some printings in green will appear, displaying something like

    BASIC66 - A DARTMOUTH BASIC DIALECT
    (C) 2026 BY PAOLO CARESSA
    >|

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

### The Basic66 language

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

This program defines three variables, assigning to them values. The `^` operator means raising to the power, while `SQR` means "squared root".

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
    30  V(I) = I^2
    40 NEXT I

If you use a non dimensioned vector or matrix, an error occurs, but if you try to assign a value to an element of it, then it is assumed that it is a vector with 10 elements, or a matrix with 10x10 elements. Thus, the previous example could be written in worse style as

    10 REM LINE 30 MAKES AN IMPLICIT DIM V(10) DECLARATION
    20 FOR I = 1 TO 10
    30  V(I) = I^2
    40 NEXT I

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

### Basic66 statements

The complete list of all Basic66 follows.


        CHANGE v TO v$
        CHANGE v$ TO v
        DATA n, ...
        DATA s, ...
        DIM v(n), ...
        DIM v(n,n1), ...
        DIM v$(n), ...
        FOR v = n TO n1
        FOR v = n TO n1 STEP n2
        GOSUB p
        GOTO p
        IF n1 rel n2 THEN p
        IF s1 rel s2 THEN p
        INPUT v, ...
        INPUT v$, ...
        LET v = n
        LET v(n) = n1
        LET v(n,n1) = n2
        LET v$ = s
        LET v$(n) = s
        NEXT v
        PRINT n, ...
        READ v, ...
        READ v$, ...
        REM ...
        RETURN
        STOP
        END

     WHERE
        Variables v are letters possibly followed by letters or digits
        Numbers n are operands connected via arithmetical operators "+", "-",
            "*", "/", where an operand is a number constant, a number variable,
            a function applied to an actual parameter, minus followed by an
            operand, a number between parentheses.
        Strings s are string operands, thus string constants, string variables,
            functions applied to an actual parameter. A string can be subscripted
            as a vector and a string vector as a matrix. For example S$(1,2)
            addresses the second character of string S$(1). 
        A relation can be "=", "<", ">", "<>", ">=", "<="
    
    The last statement of the program ought to be END.


#### CHANGE

The general form of this statement is

    CHANGE v1 TO v2

where `v1` and `v2` are a string variable and a vector variable, or a vector variable and a string variable. In the first case, for example `CHANGE X$ TO V`, both variables `X$` and `V` should exist, else an error is raised; in the second case, for example `CHANGE V TO X$`, the array `V` should exist, while the string `X$` should not, and in this case it is defined by the `CHANGE` statement.

#### DATA, READ and RESTORE

#### DIM

#### FOR and NEXT

#### GOTO

#### GOSUB and RETURN

#### IF

#### INPUT

#### LET

#### PRINT

#### END, STOP, REM

Any program should end with the `END` statement on the last line, else the compilation terminates with an error.

### Basic66 functions

While Basic provided the possibility to define one-line user defined functions, I found no need for that in Basic66. In any case, built-in functions are provided, just the main ones for general purpose numerical applications: most are not useful for PERELIZA, but still it was simple to add them.

#### Numerical functions

#### String functions

Basic66 implements three functions which were available in Dartmouth Basic after the introduction of strings, and essentially available on any Basic implementation of the 70s and 80s.

- `ASC(s)` compute the ASCII code of the first character of string `s` (if the string is empty, 0 is returned).
- `CHR$(n)` return the string whose only character is the one with ASCII code `n`.
- `LEN(s)` return the number of characters of string `s`.

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


