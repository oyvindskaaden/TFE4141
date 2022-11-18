def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val 


number = 0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D

#print(hex(twos_comp(int(number, 16), 256)))

twos = ~number + 1
#twos += 1 << 256

def hex2(n, bits):
    return "0x%x"%(n & ((1<<bits) - 1))

print(hex2(twos, 258))
print(hex2(twos << 1, 258))

#print(format(twos, '#x'))