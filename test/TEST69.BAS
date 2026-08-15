10 DIM L$(50)
20 READ N
25 for i = 1 to n
30 read l$(i)
35 next i
40 FOR I = 1 TO N
50 FOR J= 1 TO N-I
60 IF L$(J) <= L$(J+1) THEN 100
70 LET A$ = L$(J)
80 LET L$(J)= L$(J+1)
90 LET L$(J+1)= A$
100 NEXT J
110 NEXT I
120 for i = 1 to n
130 print l$(i)
135 next i
900 DATA 5, "ONE", "TW0", "THREE", "F0UR", "FIVE"
999 END