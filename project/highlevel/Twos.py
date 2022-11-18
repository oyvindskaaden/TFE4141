
number = 0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D

#print(hex(twos_comp(int(number, 16), 256)))

twos = ~number + 1
twos2 = -number

def hex2(n, bits):
    return "0x%x"%(n & ((1<<bits) - 1))

def twos_comp_trunk(n, bits = 256):
    """Take the twos complement and trunkate to bits (default: 256) long"""
    return int("0x%x"%(-n & ((1<<bits) - 1)),16)

num = int(hex2(twos2, 256), 16)

print(hex2(twos, 258))
#print(hex2(twos << 1, 258))
print(hex2(twos2, 256))
print(hex(twos_comp_trunk(number)))

#print(format(twos, '#x'))