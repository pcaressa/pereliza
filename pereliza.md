# PERELIZA

## Introduction

This document describes the `PERELIZA` implementation of the ELIZA chatbot as described by Joseph Weizenbaum, CACM 9 (1966) 36-45. This implementation is written in a fictional Basic66 language, which is just the version of Dartmouth Basic available in 1967 (up to some non implemented features as matrix statements).

## Scripts

In his paper, Weizenbaum describes the structure of a script according to a Lisp-like syntax which was targeted on the language he used, MAD-Slip. To use it in my Basic program would amount to implement a Lisp parser, therefore I used a command-oriented syntax to express the same constructs.

Since Basic66 does not deal with text or data files, the script should be encoded into a series of DATA statements, usually with line numbers >= 9000.

When parsing the script, PERELIZA stores all strings into a huge (actually very small according to the current standards) table of strings: in a more sophisticated implementation, strings would be stored in a hash table (perhaps with quadratic hashing), but here the KISS principle won and we use a simple but space consuming representation. So, a vector `S$(2048)` is dimensioned and an index `S0` is initialized to 0, denoting the index of the first free element in the table. Basic66 is fast enough to let us rely on a brutal linear insertion algorithm: when a new string is parsed, we look for it, by a linear search, in `S$()` and, if we succeed, then its index is retrieve, else it is appended to the end of `S$()` and the index of the new appended element is returned (which is the old `S0`, the latter being increased).

Furthermore, since it is needed to store lists of strings, there's also a numerical vector `L(512)` whose items contains the indexes of those strings inside `S$()`: since no string processing is actually required but to store immutable string lists, a list in `L()` is stored as a contiguous sequence `L(I)`, `L(I+1)`, `L(I+2)`, `L(I+3)`, ..., `L(I+N)` where `L(I)` is the length `N` of the list, and `L(I+1)`, ..., `L(I+N)` are its elements.

A script is a sequence of DATA statements which must have the following form (each one can be split in several DATA statements since the item of the command are READ sequentially):

    DATA "ALIAS", w1$, w2$
    DATA "END"
    DATA "GROUP", w$, w1$, ..., wm$
    DATA "KEY", k$, r, r1, ..., rk, 0
    DATA "PRINT", s$
    DATA "RULE", n, p$, t1$, ..., tm$, ""

The `"ALIAS", w1$, w2$` command insert the pair `(w1$,w2$)` into a list which is scanned each time a word is parsed from the input text: each occurrence of `w1$` is replaced by `w$2`. This substitution occurs before the text is transformed somehow. PERELIZA maintains an array `A(32,1)` such that `A(I,0)` is the index of `w1$` in `S$()` and `A(I,1)` is the index of `w2$` in `S$()`, which is inspected each time a word is parsed from the input text.

The `"RULE", n, p$, t1$, ..., tm$, ""` rule defines a new set of transformations associated to a pattern `p$`. For example:

    "RULE", 10, "0 MY 0",
        "WHY ARE YOU CONCERNED OVER MY 3",
        "WHAT ABOUT YOUR OWN 3",
        "ARE YOU WORRIED ABOUT SOMEONE ELSE'S 3",
        "REALLY, MY 3",
        ""

inserts a new rule, with number 10, whose pattern is `"0 MY 0"` (zero matches any sequence of words), and whose possible transformations are given by the four strings following the pattern (`""` marks the end of the list). To keep track of rules, PERELIZA maintains a vector `R(64)` whose elements points to list of strings inside `L()`, that contains the pattern as first element and the transforms in the remaining elements. The INDEX element of such list is used to address the transformation to choose if the corresponding pattern matches the user input. For example, the previous rule is stored as `R(10) = K`, where `L(K) = 5`, `L(K+1) = 100`, `L(K+2) = 101`, `L(K+3) = 102`, `L(K+4) = 103`, `L(K+5) = 104`, where

    S$(100) = "0 MY 0"
    S$(101) = "WHY ARE YOU CONCERNED OVER MY 3"
    S$(102) = "WHAT ABOUT YOUR OWN 3"
    S$(103) = "ARE YOU WORRIED ABOUT SOMEONE ELSE'S 3"
    S$(104) = "REALLY, MY 3"

The "GROUP" command is used to define a group of words:

    "GROUP", c$, w1$, ..., wn$, ""

For example

    "GROUP", "'FAMILY", "SON", "DAUGHTER", "MOTHER", "FATHER", ""

defines a group `"'FAMILY"` which, during the pattern matching phase, matches against each of the words listed after it. PERELIZA uses a vector `G(16)`, whose elements `G(I)` are indexes to lists in `L()`, whose first element is the group name and the remaining ones the elements of the group.

Next we have the "KEYWORD" command

    "KEYWORD", k$, s$, r, r1, ..., rn, 0

in which a keyword `k$` is defined, with rank `r`, and rules (identified by their numbers `r1`, ...) are associated to it. The final 0 ends the list. If `s$` is not empty, it is substituted for `k$` whenever one of its rules applies. Keywords are the words upon which the system pay attention when it tries to parse a sentence: when a keyword is found in a sentence, a match against the pattern of one of its rules is attempted and, if it succeed, the corresponding transformation is performed. To keep track of keywords, PERELIZA uses an array `K(64,16)` where `K(I,0)` is the index in `S$()` of k$, `K(I,1)` is 0 if `s$` is empty, else it is its index in `S$()`, `K(I,2)` is the rank of the keyword, `K(I,3)` contains the number n of rules associated to the keyword and `K(I,4)`, ..., `K(I,16)` are the indexes of the rules in table `R()`.

The "DEFAULT" command is used if no match can be found with the user input text, and it has the form

    "DEFAULT", s1$, ..., sk$, 0

where a list of possible answers is listed, ended by "". PERELIZA stores in the variable D the index of a list in `L()` containing this set of strings, which are randomly chosen when a default answer is to be printed.

The "PRINT" command is used to immediately print a message x$ on the screen:

    "PRINT", x$

The "END" command marks the end of the script.

The algorithm to parse a script should be straightforward: it just scans the `DATA` instructions of the program, parse them and transforms the information therein into data inside the vector and matrices described above.

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

- The "0" pattern matches with any non empty sequence of words.
- A word matches  itself.
- A group matches any word belonging to it.

A "0" symbol in a pattern can be the first one, the last one, or it must be surrounded by words or groups. If a pattern matches a list of words, the result is a list of strings which prepresent the matched words and the strings resulting by matching 0s.

For example consider the pattern "0 IS 0", that matches the string "A DOG IS AN ANIMAL"; the result of the match is the list ("A DOG", "IS", "AN ANIMAL"). If there's no match, the empty list is returned.

To implement such a match, PERELIZA stores in a numerical array `W()` the list of all (index in `S$()` to) words of the input sentence, in `Y()` the list of words of the pattern and uses a matrix `M(16,2)` to store the matched item: `M(I,0)` and `M(I,1)` contain respectively the index in `W()` of the first and of the last word of the matched item.

For example, is the user prompt is "A DOG IS AN ANIMAL", the pattern is "0 IS 0", assuming that

    S$(100) = "A"
    S$(101) = "DOG"
    S$(102) = "IS"
    S$(103) = "AN"
    S$(104) = "ANIMAL"
    S$(105) = "0"

then we'll have:

    W(0) = 5, W(1) = 100, W(2) = 101, W(3) = 102, W(4) = 103, W(5) = 104
    Y(0) = 3, Y(1) = 105, Y(2) = 102, W(3) = 105
    M(1,0) = 1, M(1,1) = 101    ' "A DOG"
    M(2,0) = 3, M(2,1) = 3      ' "IS"
    M(3,0) = 4, M(3,1) = 4      ' "AN ANIMAL"

In the transformation corresponding to a pattern, numbers from 1 on refers to the corresponding items in the `M()` matrix. For example, the transformation "WHAT IS 3" would generate the answer "WHAT IS AN ANIMAL".




 by the matching algorithm, which is as follows, given a pattern p$() and a list w$() of words to match.

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

