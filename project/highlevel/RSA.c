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
    uint64_t M = 0;                     // Partial
    uint8_t k = sizeof(A) * 8;          // A is k-bit long, do algo as long as there is bits left

    while (k--) {
        M = (M << 1) + (B & MASK ? A : 0);        
        // This is probably easier to read, equivalent to above
        // M = (M << 1) + (A * (B & MASK ? 1 : 0));

        B <<= 1;

        // We know here that M <= 3n - 3
        if (M >= n << 1)
            M -= n << 1;
        
        if (M >= n)
            M -= n;
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
        if (exponent & 1)
            chipher = ModMulti(chipher, partial, n);
        
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

    printf("Message are: \t\t%llu\n", message);
    printf("Chipher are: \t\t%llu\n", chipher);
    printf("Decrypted message are: \t%llu\n", decrypted);

    return 0;
}

