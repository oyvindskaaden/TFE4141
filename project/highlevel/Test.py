import sys

A   = 0x7659B124F9AFA93
B   = 0x8849308493143DD
N   = 0xA75698243958FAD


M   = (A * B) % N

print(f"A: {hex(A)}")
print(f"A: {hex(B)}")
print(f"A: {hex(N)}")
print(f"M: {hex(M)}")


number = "0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D"

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val 

# def twos(number):
#     twos_part = ~number + 1
#     print(f"Org num:        {number}")
#     print(f"Twos num:       {twos_part}")
#     print(f"Org num (hex):  {hex(number)}")
#     print(f"Twos num (hex): {hex(twos_part)}")
#     print(bin(number))
#     print(bin(twos_part))
#     return twos_part

# print(hex(twos(number)))                        # return positive value as is

print(twos_comp(int(number, 16), 256))
binary = "1001100110010010010100010111001110101101011001010110100001100111000101010011100001011110101010000000000011001101001010000001001000000010100010001111110001110000101010011011110010011000110111010100110010010000110101100111011011111000111111110111011010001101"
flipped = "0b"

for c in binary:
    match c:
        case "0":
            flipped += "1"
        case "1":
            flipped += "0"
        case other:
            flipped += c

print(binary)
print(flipped)

print(int(binary,2))
print(int(flipped,2) + 1)