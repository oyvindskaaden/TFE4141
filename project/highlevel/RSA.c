#include "stdint.h"
#include "stdbool.h"
#include "stdlib.h"
#include "stdio.h"

#define MASK    (1L << 63)      // Mask to get the MSBit

/**
 * Calculates the modular multiplication using the blakley method
 * 
 * Calculates A * B mod n
 */
uint64_t ModMulti (uint64_t A, uint64_t B, uint64_t n)
{
    uint64_t    M               = 0;            // M variable
    int64_t     partial         = 0,            // First partial, after M + A
                partial_mod_1n  = 0,            // One of the two second partials, Partial - 1*n
                partial_mod_2n  = 0;            // The second of the two partials, Partial - 2*n
    
    uint8_t k = sizeof(A) * 8;                  // A is k-bit long, do algo as long as there is bits left

    while (k--) {
        partial = (M << 1) + (B & MASK ? A : 0);        
        // This is probably easier to read, equivalent to above
        // M = (M << 1) + (A * (B & MASK ? 1 : 0));

        B <<= 1;

        // We know here that M <= 3n - 3
        partial_mod_1n = partial - n;
        partial_mod_2n = partial - (n << 1);

        M = partial;
        
        if (partial_mod_1n >= 0)
            M = partial_mod_1n;
        
        if (partial_mod_2n >= 0)
            M = partial_mod_2n;
    }

    return M;
}


/**
 * Calculates the RSA using $data^{exponent} mod n$
 */
uint64_t RSA(
    uint64_t data, 
    uint64_t exponent,      
    uint64_t n                          // The modulo value
    ) 
{
    uint64_t    chipher = 1,            // Chipher
                partial = data;         // Partial

    while (exponent)
    {
        if (exponent & 1) {
            printf("chipher = ModMulti(%lx, %lx, %lx)\n",chipher,partial,n);
            chipher = ModMulti(chipher, partial, n);
            printf("chipher = %lx \n",chipher);
        }
            
        
        partial = ModMulti(partial, partial, n);
        exponent >>= 1;
    }
    return chipher;
}


int main(int argc, char const *argv[])
{
    uint64_t message    = 19;
    uint64_t pub_key    = 5;
    uint64_t n          = 119;
    uint64_t priv_key   = 77;

    uint64_t chipher    = RSA(message, pub_key, n);
    uint64_t decrypted  = RSA(chipher, priv_key, n);

    printf("Message are: \t\t%lu\n", message);
    printf("Chipher are: \t\t%lu\n", chipher);
    printf("Decrypted message are: \t%lu\n", decrypted);

    return 0;
}

