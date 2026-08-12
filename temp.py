with open("DOCTOR.BAS") as file_in, open("DOCTOR_NEW.BAS", "w") as file_out:
    n = 9000
    for row in file_in:
        file_out.write(str(n) + " " + row)
        n += 2
