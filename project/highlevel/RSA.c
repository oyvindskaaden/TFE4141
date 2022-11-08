#include "stdint.h"
#include "stdbool.h"
#include "stdlib.h"
#include "stdio.h"
#include "string.h"

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

typedef struct RSATest
{
    uint64_t    n;          // Modulus
    uint64_t    e;          // Encryption (public key)
    uint64_t    d;          // Decyption (private key)
    uint64_t    message;    // 64 bit message
    char*       test_name;  // Name of test
    bool        correct;    // Check if encryption and decryption works
    bool        debug;      // Set to true for debug info
} rsa_t;


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
    uint64_t    data, 
    uint64_t    exponent,      
    uint64_t    modulus,        // The modulo value
    bool        debug
    ) 
{
    uint64_t    chipher = 1,            // Chipher
                partial = data;         // Partial

    uint8_t     loop_no = 0;

    while (exponent)
    {
        if (debug)
            printf("== Loop number: %u\n", loop_no);
        if (exponent & 1) {
            if (debug)
                printf("chipher = ModMulti(0x%016lx, 0x%016lx, 0x%016lx)\n",chipher,partial, modulus);
            chipher = ModMulti(chipher, partial, modulus);
            if (debug)
                printf("chipher = 0x%016lx \n",chipher);
        }
            
        if (debug)
            printf("partial = ModMulti(0x%016lx, 0x%016lx, 0x%016lx)\n",partial,partial, modulus);
        partial = ModMulti(partial, partial, modulus);

        if (debug)
            printf("partial = 0x%016lx \n\n",partial);
        exponent >>= 1;
        loop_no++;
    }
    return chipher;
}

/**
 * Tests the multi mod function with a test struct
*/
void _test_ModMulti(mod_multi_t *test)
{
    printf("\nMM Test: %s\n", test->test_name);
    printf("====================\n");
    printf("A:\t\t0x%016lx\n",          test->A);
    printf("B:\t\t0x%016lx\n",          test->B);
    printf("N:\t\t0x%016lx\n",          test->N);
    printf("Expected:\t0x%016lx\n",     test->expected);

    uint64_t result     = ModMulti(test->A, test->B, test->N);

    printf("Result:\t\t0x%016lx\n", result);
    
    if (result != test->expected) {
        printf("ModMulti NOT equal to expected!\n\n");
        test->correct = false;
        return;
    }
    printf("ModMulti IS equal to expected!\n\n");
    test->correct = true;
    return;
}

/**
 * Tests the RSA function with a rsa test vector
*/
void _test_RSA(rsa_t *test)
{
    printf("\nRSA Test: %s\n", test->test_name);
    printf("====================\n");
    printf("Pub Key:\t0x%016lx\n",  test->e);
    printf("Priv Key:\t0x%016lx\n", test->d);
    printf("Modulus:\t0x%016lx\n",  test->n);
    printf("Message:\t0x%016lx\n",  test->message);
    putchar('\n');
    
    if (test->debug)
        printf("== ENCRYPTION\n");
    uint64_t chipher    = RSA(test->message, test->e, test->n, test->debug);

    if (test->debug)
        printf("\n== DECRYPTION\n");
    uint64_t decrypted  = RSA(chipher, test->d, test->n, test->debug);

    printf("\n===== RESULTS =====\n");
    printf("Message are: \t\t0x%016lx\n", test->message);
    printf("Chipher are: \t\t0x%016lx\n", chipher);
    printf("Decrypted message are: \t0x%016lx\n", decrypted);
    
    if (test->message != decrypted) {
        printf("Decrypted message NOT equal to test message!\n\n");
        test->correct = false;
        return;
    }
    printf("Decrypted message IS equal to test message!\n\n");
    test->correct = true;
    return;
}


int main(int argc, char const *argv[])
{
    uint64_t message    = 0x0048656C6C6F2121;//19;
    uint64_t pub_key    = 0x0000000000010001;//5;
    uint64_t priv_key   = 0x04131e2e765e8901;//77;
    uint64_t n          = 0x08e7d3131b900529;//119;

    rsa_t small_rsa_test    = (rsa_t){
        .e          = 5,
        .d          = 77,
        .n          = 119,
        .message    = 19,
        .correct    = false,
        .test_name  = "Small test case, message: 19",
        .debug      = false
    };

    rsa_t large_rsa_test    = (rsa_t){
        .e          = 0x0000000000010001,
        .d          = 0x04131e2e765e8901,
        .n          = 0x08e7d3131b900529,
        .message    = 0x0048656c6c6f2121,
        .correct    = false,
        .test_name  = "Large test case, message: 'Hello!!'",
        .debug      = true
    };

    _test_RSA(&small_rsa_test);
    _test_RSA(&large_rsa_test);


    mod_multi_t large_mm_test   = (mod_multi_t){
        .A          = 0x7659B124F9AFA93,
        .B          = 0x8849308493143DD,
        .N          = 0xA75698243958FAD,
        .expected   = 0x4f02674256cb793,
        .test_name  = "Large numbers",
        .correct    = false
    };

    _test_ModMulti(&large_mm_test);

    return 0;
}

