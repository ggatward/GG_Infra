#/usr/bin/python

string="..."
sum=0
print sum

for i in range(len(string)):
    sum = sum + ord(string[i])

print sum

rem = sum ^ 255
rem = rem + 1
rem = rem + 256
cc1 = hex(rem)
cc = cc1.upper()
p = len(cc)
print cc[p-2:p]
