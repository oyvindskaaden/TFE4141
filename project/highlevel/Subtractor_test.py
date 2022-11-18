A           = 0x00a129dfa6f6f5393f387f5e10a9070abedd66680c509f10335c34f7015b04b64
B_2s        = 0x2ccdb5d18a5352f31d58f42affe65afdbfaee071eac86ce4566de53120e0112e6

org_b       = 0x099925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D

def hex2(n, bits):
    return "0x%x"%(n & ((1<<bits) - 1))

def twos(number):
    return ~number + 1

expected    = 0x2d6edfb1314a482c5c917389108f62087e8c46d9f7190bf489ca1a28223b15e4a
#res        = 0x2d6edfb1314a482c5c917389108f62087e8c46d9f7190bf489ca1a28223b15e4a

result_twos     = A + B_2s
result_normal   = A - (org_b << 1)

print("A:               ", hex2(A, 258))
print("B:               ", hex2(B_2s, 258))
print("Org B:           ", hex2(org_b, 258))
print("Two org B:       ", hex2(org_b << 1, 258))
print("Twos org B:      ", hex2(twos(org_b) << 1, 258))
print("Two Twos org B:  ", hex2(org_b << 1, 258))

print()
print("Twos:            ", hex2(result_twos, 258))
print("Normal:          ", hex2(result_normal, 258))

