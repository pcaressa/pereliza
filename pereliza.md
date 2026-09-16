# PERELIZA

## Introduction

This document describes the `PERELIZA` implementation of the ELIZA chatbot as described by Joseph Weizenbaum, CACM 9 (1966) 36-45. This implementation is written in a fictional Basic66 language, which is just the version of Dartmouth Basic available in 1967 (up to some non implemented features as matrix statements).

## Scripts

In his paper, Weizenbaum describes the structure of a script according to a Lisp-like syntax which was targeted on the language he used, MAD-Slip. To use it in my Basic program would amount to implement a Lisp parser, therefore I used a command-oriented syntax to express the same constructs.

Since Basic66 does not deal with text or data files, the script should be encoded into a series of DATA statements, usually with line numbers >= 9000.

When parsing the script, PERELIZA stores all strings into a huge (actually very small according to the current standards) table of strings: in a more sophisticated implementation, strings would be stored in a hash table, but here the KISS principle won and we use a simple but space consuming representation.

A vector `S$(1024)` is dimensioned and an index `S0` is initialized to 0, denoting the index of the first free element in the table. Since the table is filled by appending strings and no other list operations are needed, this suffices the purposes of the program.

A script is a sequence of DATA statements which must have the following form (each one can be split in several DATA statements since the item of the command are READ sequentially):

    DATA "ALIAS", w1$, w2$
    DATA "END"
    DATA "GROUP", w$, w1$, ..., wm$
    DATA "KEY", k$, r, r1, ..., rk, 0
    DATA "PRINT", s$
    DATA "RULE", n, p$, t1$, ..., tm$, ""

The `"ALIAS", w1$, w2$` command insert the pair `(w1$,w2$)` into a list which is scanned each time a word is parsed from the input text: each occurrence of `w1$` is replaced by `w2`. This substitution occurs before the text is transformed somehow. PERELIZA maintains an array `A(32,1)` such that `A(I,0)` is the index of `w1$` in `R$()` and `A(I,1)` is the index of `w2$` in `R$()`, which is inspected each time a word is parsed from the input text.

The `"RULE", n, p$, t1$, ..., tm$, ""` rule defines a new set of transformations associated to a pattern `p$`. For example:

    "RULE", 10, "0 MY 0",
        "WHY ARE YOU CONCERNED OVER MY 3",
        "WHAT ABOUT YOUR OWN 3",
        "ARE YOU WORRIED ABOUT SOMEONE ELSE'S 3",
        "REALLY, MY 3",
        ""

inserts a new rule, with number 10, whose pattern is `"0 MY 0"` (zero matches any sequence of words), and whose possible transformations are given by the four strings following the pattern (`""` marks the end of the list). To keep track of rules, PERELIZA maintains a matrix `R(128,2)`, where `R(I,0)` is the index in `S$()` to the string containing the rule pattern, `R(I,1)` is the index of the first element of a list of strings containing the possible transformations associated to the pattern and `R(I,2)` is the number of items in this list. Thus, the previous rule, could be stored as `R(10,0) = 100`, `R(10,1) = 101`, `R(10,2) = 4`, where

    S$(100) = "0 MY 0"
    S$(101) = "WHY ARE YOU CONCERNED OVER MY 3"
    S$(102) = "WHAT ABOUT YOUR OWN 3"
    S$(103) = "ARE YOU WORRIED ABOUT SOMEONE ELSE'S 3"
    S$(104) = "REALLY, MY 3"

The "GROUP" command is used to define a group of words:

    "GROUP", c$, w1$, ..., wn$, ""

For example

    "GROUP", "/FAMILY", "SON", "DAUGHTER", "MOTHER", "FATHER", ""

defines a group `"/FAMILY"` which, during the pattern matching phase, matches against each of the words listed after it. PERELIZA uses an array `G(16,2)`, whose elements `G(I,0)` are group names, `G(I,1)` contains the first item of the group and `G(I,2)` is the number of items in the group.

Next we have the "KEYWORD" command

    "KEYWORD", k$, s$, r, r1, ..., rn, 0

in which a keyword `k$` is defined, with rank `r`, and rules (identified by their numbers `r1`, ...) are associated to it. The final 0 ends the list. If `s$` is not empty, it is substituted for `k$` whenever one of its rules applies. Keywords are the words upon which the system pay attention when it tries to parse a sentence: when a keyword is found in a sentence, a match against the pattern of one of its rules is attempted and, if it succeed, the corresponding transformation is performed. To keep track of keywords, PERELIZA uses an array `K(128,)` where `K(I,0)` is the index in `S$()` of k$, `K(I,1)` is 0 if `s$` is empty, else it is its index in `S$()`, `K(I,2)` is the rank of the keyword, `K(I,3)` contains the number n of rules associated to the keyword and `K(I,4)`, ..., `K(I,16)` are the indexes of the rules in table `R()`.

The "DEFAULT" command is used if no match can be found with the user input text, and it has the form

    "DEFAULT", r1, ..., rk, 0

where the numbers of rules to apply in the default situation are listed, ended by 0. The indexes of these rules are stored in the array `D(16)`, where `D(0)` contains the number k of rules and `D(1)`, ..., `D(16)` contains the indexes r1, ..., rk.

The "PRINT" command is used to immediately print a message x$ on the screen:

    "PRINT", x$

The "END" command marks the end of the script.

The algorithm to parse a stript should be straightforward: it assumes that the following data are declared:

    DIM A$(32, 1)   ' Array of aliases
    LET A0 = 1      ' First free item in A$()
    LET A9 = 32     ' SIZE OF A$()
    DIM D(16)       ' Array of default rules
    LET D0 = 1      ' First free item in A$()
    LET D9 = 16     ' SIZE OF D()
    DIM G$(16,16)   ' Array of groups
    LET G0 = 1      ' First free item in G$()
    LET G9 = 16     ' SIZE OF G$()
    DIM K$(64)      ' Keyword names
    DIM K(64,16)    ' Keyword Rules
    LET K0 = 1      ' First free item in K$() and K()
    LET K9 = 64     ' SIZE OF K()
    DIM R$(256,16)  ' Array of rules
    DIM R(256)      ' Actual column used in each item of R$
    LET R0 = 1      ' First free item in R$()
    LET R9 = 256    ' SIZE OF R$() AND R()

Then the parsing script algorithm is the following (The script is stored as a list of DATA statement containing the script commands):

1. Read x$
2. If x$ = "END", then return.
3. If x$ = "ALIAS", then:
31. If A0 > 32, then error: too many aliases
32. Read A$(A0,0), A$(A0,1)
33. Let A0 = A0 + 1
34. Go to 1.
4. If x$ = "DEFAULT", then
41. If D0 > 16 then error: too many default rules.
42. Read D(D0)
43. If D(D0) <> 0, then increase D0 and go to 41.
44. Go to 1.
5. If x$ = "GROUP", then
51. If G0 > 16, then error: too many groups.
52. Read G$(G0,0)
53. If G$(G0,0) does not start by "/" then error: invalid group name
54. Let i = 1
55. If i > 16 then error: too many words in a group.
56. Read G$(G0,i)
57. If G$(G0,i) <> "", then increase i, go to 55.
58. Go to 1.
6. If x$ = "KEYWORD", then
61. If K0 > 64 then error: too many keys.
62. Read K$(K0,0), K$(K0,1)
63. Let i = 0
64. If i > 16, then error: too many rules for a key.
65. Read K(K0,i)
66. If K(K0,i) <> 0, then increase i, go to 64.
67. Go to 1.
7. If x$ = "RULE", then
71. Read i
72. If i < 0 or i > 256, then error: invalid rule number.
73. Read R$(i, 0)
74. Let j = 1.
75. If j > 16 then error: too many replacement for a pattern.
76. Read R$(i,j)
77. If R$(i,j) <> 0, then increase j, go to 75.
78. Go to 1.
8. Error: invalid command.


## Script execution

Once a script is parsed with no errors, it is used for the interactive session: a welcome message is printed and the user can insert a prompt.

Next, PERELIZA parses all words of the prompt into a list, in search of keywords, so to apply one of the rules associated to the keyword. To do that, a keystack is defined, and the following algorithm is used to detect a keyword.

1. Set the keystack to empty
2. Set r = 0 (rank).
3. Parse next word w$.
4. If there are no more words to parse and return.
5. If w$ = "," or w$ = ".", then:
51. If the keystack is not empty, then delete all words from the sentence from w$ included on, and return.
52. Else, delete all words from the sentence up to w$ included and go to 3.
6. If w$ is not a keyword, then go to 3.
7. If the rank of the keyword is > r, then place the key on bottom of the keystack.
8. Else:
81. Place the key on top of the keystack.
82. Set r = precedence of the keyword.
9. Go to 3.

After this algorithm is executed, if the keystack is empty, then a random output from the "DEFAULT" list is selected and printed, else from top to bottom the elements of the stack are popped and the patterns of their rules is matched against the input text resulting from the previous algorithm.

The pattern matcher splits the string containing the user prompt in words and tries to match this sequence against the pattern according to the following rules:

- The "0" pattern matches with any sequence of words (even empty).
- A word matches  itself.
- A group matches any word belonging to it.

A "0" symbol in a pattern can be the first one, the last one, or it must be surrounded by words or groups. If a pattern matches a list of words, the result is a list of strings which prepresent the matched words and the strings resulting by matching 0s.

For example consider the pattern "0 IS 0", that matches the string "A DOG IS AN ANIMAL"; the result of the match is the list ("A DOG", "IS", "AN ANIMAL"). If there's no match, the empty list is returned by the matching algorithm, which is as follows, given a pattern p$() and a list w$() of words to match.

1. Set M to be the empty list.
2. Set i = 1, j = 1.
2. If i > LEN(p$):
21. If j <= LEN(w$), then M = empty.
22. Return.
3. Parse a symbol s$ from p$, updating i to point after it.
4. If s$ = "0":
41. Parse a symbol s1$ from p$, updating i.
42. If no symbol can be parsed:
421. Set s2$ = w$(j) + " " + ... + " " + w$(LEN(w$))
422. Append s2$ to M.
423. Return M.
43. If s1$ = "0", then an error in the pattern occur, fail the execution.
44. If s1$ is a group name, then:
441. Parse words from w$, increasing j, until a word in the group is found
442. If no such word is found, then M = empty and return.
443. Append the concatenation of those words to M.
444. Append the word found to M.
445. Go to 2.
45. Parse words from w$, increasing j, until s1$ found
46. If s1$ cannot be found, then M = empty and return.
47. Append the concatenation of those words to M.
48. Append s1$ to M.
49. Go to 2.
5. If s$ is a group name:
51. Look for the index i of s$ in the group table.
52. If no such index can be found, then error: undefined group
53. Parse a word s1$ from w$ updating j.
54. If the word does not belong to the group, then M = empty, return.
55. Go to 2. 
6. Parse a word s1$ from w$ updating j.
7. If s$ <> s1$, then M = empty and return.
8. Go to 2.

