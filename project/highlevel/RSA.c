#include "stdint.h"
#include "stdbool.h"
#include "stdlib.h"
#include "stdio.h"

uint64_t ModMulti (uint64_t A, uint64_t B, uint64_t n)
{
    uint64_t M = 0;                     // Partial

    uint64_t k = sizeof(A) * 8;         // A is k-bit long, do algo as long as there is bits left

    uint64_t mask = (1L << (k - 1));    // Mask to get the i-th bit

    while (k--) {
        M = (M << 1) + (A * (B & mask ? 1 : 0)); 
        
        // This is for HW implement, equivalent to above
        //M = (M << 1) + (B & mask ? A : 0);        
        
        // The two following lines are equivalent
        //B <<= 1;          
        mask >>= 1;

        while (M >= n)
            M -= n;
    }

    return M;
}


uint64_t RSA(uint64_t d, uint64_t e, uint64_t n) 
{
    uint64_t    c = 1, 
                p = d;

    while (e)
    {
        if (e & 1)
            c = ModMulti(c, p, n);
        
        p = ModMulti(p, p, n);

        e >>= 1;
    }

    return c;
}


int main(int argc, char const *argv[])
{
    uint64_t message    = 19;
    uint64_t pub_key    = 5;
    uint64_t n          = 119;
    uint64_t priv_key   = 77;

    uint64_t chipher    = RSA(message, pub_key, n);
    uint64_t decrypted  = RSA(chipher, priv_key, n);

    printf("Message are: \t\t%llu\n", message);
    printf("Chipher are: \t\t%llu\n", chipher);
    printf("Decrypted message are: \t%llu\n", decrypted);

    return 0;
}

