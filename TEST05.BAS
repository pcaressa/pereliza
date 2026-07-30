10 rem greatest common divisor
20 print "insert two whole positive numbers:"
30 input n
40 input m
50 if n = m then 110
60 if n < m then 90
70 let n = n - m
80 goto 50
90 let m = m - n
100 goto 50
110 print "gcd = "; n
999 end