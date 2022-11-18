import sys

# A   = 0x7659B124F9AFA93
# B   = 0x8849308493143DD
# N   = 0xA75698243958FAD
A   = 0x0a23232323232323232323232323232323232323232323232323232323232323
B   = 0x0a23232323232323232323232323232323232323232323232323232323232323
N   = 0x99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d
#N   = 0x666dae8c529a9798eac7a157ff32d7edfd77038f56436722b36f298907008973

def hex2(n, bits):
    return "0x%x"%(n & ((1<<bits) - 1))

def MultiMod(A, B, N):
    M               = 0
    partial         = 0
    partial_mod_1n  = 0
    partial_mod_2n  = 0

    times = 256
    mask = 1 << times - 1

    while (times):
        print("==== Round:", 256 - times)
        print("M before algo:   ", hex2(M, 260))
        partial = (M << 1) + (A if B & mask else 0)

        B = B << 1

        
        partial_mod_1n = partial - N
        partial_mod_2n = partial - (N << 1)

        print("Partial:         ", hex2(partial, 260))
        print("Partial mod n:   ", hex2(partial_mod_1n, 260))
        print("Partial mod 2n:  ", hex2(partial_mod_2n, 260))

        mux_sel = 0
        
        if partial_mod_1n < 0:
            mux_sel += 1 << 1

        if partial_mod_2n < 0:
            mux_sel += 1

        print("Borrow:          ", bin(mux_sel))
        
        # print("Mux sel:         ", mux_sel)
        

        #M = partial

        match mux_sel:
            case 0b00:
                print("Mux sel:         ", 2)
                M = partial_mod_2n
            case 0b01:
                print("Mux sel:         ", 1)
                M = partial_mod_1n
            case 0b11:
                print("Mux sel:         ", 0)
                M = partial
            case 0b10:
                print("Mux sel:         ", "Invalid")
                M = 0
                


        # M = partial

        # if (partial_mod_1n >= 0):
        #     print("Mux: 1")
        #     M = partial_mod_1n
        
        # if (partial_mod_2n >= 0):
        #     print("Mux: 2")
        #     M = partial_mod_2n
        
        print("M:               ", hex2(M, 260))
        print()
        times -= 1

    return M


M1  = (A * B) % N

M2  = MultiMod(A, B, N)

print(f"A: {hex(A)}")
print(f"B: {hex(B)}")
print(f"N: {hex(N)}")
print(f"M: {hex(M1)}")
print(f"MM:{hex(M2)}")
