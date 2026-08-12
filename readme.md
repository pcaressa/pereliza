# Per ELIZA

## A strictly useless retro-experiment in programming and AI

### Paolo Caressa

#### Version 1.0 - August 2026

## Foreword

In view of some talks I wanted to give on the occasion of the 60 years of the ELIZA chatbot, a masterpiece in programming and computer-human interactions, I decided to implement my own version. There are some excellent implementations that simulate the original system, but I wanted to code by myself a new one.

When I was 14 or so, I came across a Basic implementation of an ELIZA-like chatbot, that circulated in a street Basic in the 70s and 80s, and ported it to the ZX Spectrum, attempting at modification so to let the program to speak a little bit of Italian.

Therefore, for the PER ELIZA talk, I've decided to program the chatbot in a way that strictly follows Weizenbaum's 1966 CACM paper, with some version of the Basic language. When ELIZA was programmed in MAD-SLIP by Weizenbaum, Basic was essentially implemented only in the Dartmouth system, where it was created by Kemeny and Kurtz some two years earlier.

I decided to implement a version of the Dartmouth Basic system as it was in the 1966/67, including strings and string vectors, with the only CHANGE instruction to deal with them. I wrote a compiler for this Basic66 in pure JavaScript to run inside a browser, in the first place.

Next, I decided to implement ELIZA for this Basic dialect by following the description given by Weizenbaum in his classic 1966 paper, at the end of which a script (i.e. a rule database as usual for symbolic AI of those days) was listed. This script is essentially a Lisp description of the rule database, today we would code it in Json, The PER ELIZA program requires the bare text of this script inside a series of strings in DATA instructions, parse them and create inner lists to handle them.

Since the program just needs to read and store the lists resulting from those S-expressions, I did not implemented a complete library for list processing in Basic (although it would be nice to implement a Basic appliance of Weizenbaum Slip language), but just the minimum needed to handle the script and program the answer engine.

In this document I describe these useless efforts: as paradoxical as it may seem, no AI has been used neither in writing the code, nor in writing the documentation: this is a programming and coding effort done for fun.

Enjoy,
P

## A short description of ELIZA as of 1966

ELIZA was an interactive chatbot, which means that the main program implemented a REPL asking for a sentence from the user, processing it and providing an answer to be printed, and so on, until some ending condition.

The program did not attempt at an analysis of the sentences typed by the user, but barely applied some transformation to them so to produce the answer, according to a set of rules, specified in a *script*.

A script contains dozens of rules to handle such transformations, and the base principle of those rules is that some keyword needs to be singled out in the input sentence: this keyword will determine which transformation to apply. If no keyword could be found, a generic answer will be prompted to the user.

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

matches the pattern (0 IF 0) where the first 0 matches "LOOSE THE MATCH" and the second 0 matches "LOOSE THIS GAME", so that on applying the rule, the result will be "DO YOU THINK ITS LIKELY THAT SOCRATES IS A MAN".


### More on scripts

Some variants of the previous syntax for scripts are allowed to perform special operations. First of all, one can define aliases for keywords, just putting `=` and the alias after the keyword, as in

    (YOUR = MY
        ((0 MY 0)
        (WHY ARE YOU CONCERNED OVER MY 3)
        (WHAT ABOUT YOUR OWN 3)
        (ARE YOU WORRIED ABOUT SOMEONE ELSE'S 3)
        (REALLY, MY 3)))

The equation YOUR = MY means that whenever YOUR is parsed, it is immediately transformed into MY, and this is done before any other processing is performed by the algorithm

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


## Basic66

In 1966 there were different languages that could be used to implement a chatbot such as Eliza, for example Lisp, Snobol, etc. Weizenbaum used a language he himself invented, a variant of MAD with a list processing library Slip.

In this implementation I will use a version of Basic such as the one available when ELIZA was implemented, in 1966.

### The Time Sharing interface

To lanuch Basic66, just open the html file `basic66.html` in your browser. A black window with some printings in green appear, it'll display something like

    B A S I C 6 6
    (C) 2026 BY PAOLO CARESSA
    TYPE HELP TO GET A GENERIC HELP, HELP W TO GET HELP ON W.
    >|

Now you can insert commands to edit, save, load or launch a Basic program: they are the classic DTSS terminal commands. A single source file can be dealt with at the time: to create a new one, type

    >NEW name

An empty file is created. Such a file has lines indexed by integer numbers between 1 and 9999. To enter a new line, write its number followed by the text of the line, for example

    >10 PRINT 0

To replace this line with another one, just use the same number:

    >10 PRINT 10

You'll notice that characters are capitalized: we use a system with only capital letters available. To delete a line just type its number and press return.

After a while, you'll want to see the program ordered according to the line numbers: to do that type `LIST` which will print some twenty lines, then ask for a key to be pressed, and so on, until all the program has been listed.

To save the program just type `SAVE` (the name of the program has been declared in the `NEW` statement), while to load a saved program, use `OLD`.

To run the program, just type `RUN`: this actually compiles the program and then executes it. You can accomplish both tasks separately, by the commands `BASIC`, that compiles the program in an inner file that you can peruse with `CODE` (that acts like `LIST` for the source code), and `EXEC`, that executes the current code. After the execution, especially if some error occurs, you can look the contents of the program's variables by the `VARS` command (all those commands are not in the original Basic systems, I needed them to perform debug and left them in the program).

A simple help can be provided by typing `HELP w` where `w` is a keyword or a Basic function or a terminal command.

A program can be loaded also by drag-dropping it into the window.

Notice: when a program is loaded, its lines are just processed as they would be type interactively, so you can also use commands and not just line numbers followed by a text. Moreover, the previous program is not deleted, unless you use `NEW`, so that it is actually merged in the current one.

### The Basic66 language

Basic was a very simple yet effective programming language: it lacked most features nowadays considered essential, like local variables in subroutines, etc. It resembled assembly in several respects, borrowing from Fortran some features.

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

Strings can be assigned from string constants or string variables: also, one can use the `&` operator to concatenate them (which was not available in the 1966 version of Basic, so it is to be considered apocryphal).

    10 LET X$ = "ALPHA"
    20 LET Y$ = "GO"
    30 LET Z$ = X$ & Y$

String variables must have a `$` suffix, moreover variable's names can be letters possibly followed by a digit (actually the compiler accepts any alphanumerical sequence not starting by a digit, another apocryphal feature, since in 1966 Basic did not allowed it).

Vector and matrices, instead, should be declared in advance by a `DIM` statement, of the form

    DIM v(i1,i2), w(j1,j2), ...

where i2, j2, ... may be omitted and, in this case, v, w, ... can be string variables.

After dimensioning, one can refer to an element of a vector or matrix by the functional notation `v(e1,e2)`. For example, this program fills a vector.

    10 DIM V(10)
    20 FOR I = 1 TO 10
    30  V(I) = I^2
    40 NEXT I

A string is considered to be a vector of the ASCII codes of its characters, with the 0-th element as the length of the string. For example to look for a character inside a string one can use

    10 LET S$ = "0123456789"
    20 LET C$ = "3"
    30 FOR I = 1 TO S$(0)
    40  IF C$ = S$(I) THEN 100
    50 NEXT I
    60 PRINT "NOT FOUND"
    70 STOP
    100 PRINT "FOUND, WITH INDEX ";I
    999 END

Hence, a vector of strings is actually a matrix of characters.

Among numbers, the usual arithmetical operations are allowed. Number or string comparisons are allowed only inside `IF` statements, and are the usual ones: `=`means equality, `<>` means inquality, `<`, `<=`, `>`, `>=` have the usual meaning for numbers and strings as all current programming languages.



### Differences from the actual Dartmouth Basic

This implementation of Basic was programmed purposely to have a language in which to implement ELIZA, so it is not a strict implementation of Dartmouth Basic. Hereinafter, I list the main differences.

- In Dartmouth Basic one can use vector and matrices without DIMensioning them, in which case the system supposed a size of 10 items in each dimension.
- The `PRINT` and `INPUT` statements were more flexible in Dartmouth Basic, I implemented the bare minimum needed to implement ELIZA.
- The `MAT` family of statements, that allowed to deal with vector and matrices in a very simple way, are not implemented in Basic66.

File handling was not available in Dartmouth Basic in 1966, nor it is in Basic66.

## Eliza In Basic

