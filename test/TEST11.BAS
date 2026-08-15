    10 LET X$ = "PER"
    20 LET Y$ = "ELIZA"
    30 DIM V1(20), V2(20)
    40 CHANGE X$ TO V1
    50 CHANGE Y$ TO V2
    60 FOR I = 1 TO LEN(Y$)
    70 LET V1(LEN(X$) + I) = V2(I)
    80 NEXT I
    90 LET V1(0) = LEN(X$) + LEN (Y$)
    100 CHANGE V1 TO X$
    200 PRINT X$
    999 END
