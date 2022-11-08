#include "stdint.h"
#include "stdbool.h"
#include "stdlib.h"
#include "stdio.h"

#define MASK    (1L << 63)      // Mask to get the MSBit

typedef struct ModMultiTest
{
    uint64_t    A;
    uint64_t    B;
    uint64_t    N;
    uint64_t    expected;
    char*       test_name;
    bool        correct;
} mod_multi_t;


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
            printf("chipher = %lx \n\n",chipher);
        }
            
        
        partial = ModMulti(partial, partial, n);
        exponent >>= 1;
    }
    return chipher;
}

void _test_ModMulti(mod_multi_t *test)
{
    printf("\nTest: %s\n", test->test_name);
    printf("====================\n");
    printf("A:\t\t0x%016lx\nB:\t\t0x%016lx\nN:\t\t0x%016lx\n", test->A, test->B, test->N);
    printf("Expected:\t0x%016lx\n", test->expected);
    uint64_t result     = ModMulti(test->A, test->B, test->N);
    printf("Result:\t\t0x%016lx\n", result);
    
    if (result != test->expected) {
        printf("ModMulti NOT equal to expected!\n\n");
        test->correct = false;
        return;
    }
    printf("ModMulti equal to expected!\n\n");
    test->correct = true;
    return;
}


int main(int argc, char const *argv[])
{
    uint64_t message    = 19;
    uint64_t pub_key    = 0x10001;//5;
    uint64_t priv_key   = 0x4131e2e765e8901;//77;
    uint64_t n          = 0x8e7d3131b900529;//119;


    printf("message: %x, pub_key: %x, n: %x, priv_key: %x\n", message, pub_key, n, priv_key);

    uint64_t chipher    = RSA(message, pub_key, n);
    uint64_t decrypted  = RSA(chipher, priv_key, n);

    printf("Message are: \t\t%lu\n", message);
    printf("Chipher are: \t\t%lu\n", chipher);
    printf("Decrypted message are: \t%lu\n", decrypted);


    mod_multi_t large_test = (mod_multi_t){
        .A          = 0x7659B124F9AFA93,
        .B          = 0x8849308493143DD,
        .N          = 0xA75698243958FAD,
        .expected   = 0x4f02674256cb793,
        .test_name  = "Large numbers",
        .correct    = false
    };

    _test_ModMulti(&large_test);

    return 0;
}

