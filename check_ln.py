last_read = 0
with open("PERELIZA.BAS") as file_in:
    i = 1
    for row in file_in:
        n = int(row[:4])
        if n < last_read:
            raise BaseException("Line " + str(i))
        last_read = n
        i += 1
        