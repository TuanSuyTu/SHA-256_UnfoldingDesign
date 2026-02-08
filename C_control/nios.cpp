#include <stdio.h>
#include <stdint.h>
#include "system.h"
#include "io.h"

#define IP_BASE SHA256_0_BASE

#define DATA_IN_OFFSET 0x1
#define RESET_OFFSET 0x11
#define HASH_OFFSET 0x1

#define DATA_WORDS 16
#define HASH_WORDS 8

#define CTRL_START 0x1
#define BUSY 0x2

#define TIMEOUT 1000000

void reset();
void load(const uint32_t data[DATA_WORDS]);
int wait();
void print();
void process(const uint32_t blk[DATA_WORDS], int final);

void reset()
{
    IOWR(IP_BASE, RESET_OFFSET, 0x0);
}

void load(const uint32_t data_block[DATA_WORDS])
{
    int i;
    IOWR(IP_BASE, 0, CTRL_START);

    for (i = 0; i < DATA_WORDS; i++)
    {
        IOWR(IP_BASE, DATA_IN_OFFSET + i, data_block[i]);
    }
}

int wait()
{
    int timeout = TIMEOUT;
    while (((IORD(IP_BASE, 0) & BUSY) != 0) && timeout > 0)
    {
        timeout--;
    }
    if (timeout == 0)
    {
        printf("Timeout");
        return 0;
    }
    return 1;
}

void print()
{
    int i;
    for (i = 0; i < HASH_WORDS; i++)
    {
        printf("%08lx", (unsigned long)IORD(IP_BASE, HASH_OFFSET + i));
    }
    printf("\n");
}

void process(const uint32_t input_block[DATA_WORDS], int is_final_block)
{
    load(input_block);
    wait();

    if (is_final_block)
    {
        print();
    }
}

int main()
{
    int i;
    printf("--- Testcase 1 block ---\n");
    const uint32_t test_vectors[][DATA_WORDS] = {
        // Test 1: "abc"
        {0x61626380, 0x00000000, 0x00000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000018},
        // Test 2: "aaaaaaaa"
        {0x61616161, 0x61616161, 0x80000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000040}};

    int num_single_tests = sizeof(test_vectors) / sizeof(test_vectors[0]);
    for (i = 0; i < num_single_tests; i++)
    {
        printf("Test %d: ", i + 1);
        reset();
        process(test_vectors[i], 1);
    }

    printf("\n--- Testcase 2 block ---\n");
    const uint32_t double_block[][2][DATA_WORDS] = {

        // Test 3: "Ngay mai van den nang van uom vang, ma nguoi bien mat nhu phao hoa tan"
        {{// Block 1
          0x4e676179, 0x206d6169, 0x2076616e, 0x2064656e,
          0x206e616e, 0x67207661, 0x6e20756f, 0x6d207661,
          0x6e672c20, 0x6d61206e, 0x67756f69, 0x20626965,
          0x6e206d61, 0x74206e68, 0x75207068, 0x616f2068},
         {// Block 2
          0x6f612074, 0x616e8000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000, 0x00000230}},

        // Test 4: "Dong thu trao nhau nam ay theo may ngan. Ngay mai van den gio hat ngang troi"
        {{// Block 1
          0x446f6e67, 0x20746875, 0x20747261, 0x6f206e68,
          0x6175206e, 0x616d2061, 0x79207468, 0x656f206d,
          0x6179206e, 0x67616e2e, 0x204e6761, 0x79206d61,
          0x69207661, 0x6e206465, 0x6e206769, 0x6f206861},
         {// Block 2
          0x74206e67, 0x616e6720, 0x74726f69, 0x80000000,
          0x00000000, 0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000, 0x00000260}}};

    int num_double_tests = sizeof(double_block) / sizeof(double_block[0]);
    for (i = 0; i < num_double_tests; i++)
    {
        printf("Test %d: ", i + 3);
        reset();
        process(double_block[i][0], 0);
        process(double_block[i][1], 1);
    }

    // Test 5: 256 chu 'a'
    printf("\n--- Testcase nhieu block : 256 chu a --- \n");
    const uint32_t test3_block[5][DATA_WORDS] = {
        // Block 1 - 64 chu a dau
        {0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161},
        // Block 2
        {0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161},
        // Block 3
        {0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161},
        // Block 4
        {0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161,
         0x61616161, 0x61616161, 0x61616161, 0x61616161},
        // Block 5 - block cuoi cung
        {0x80000000, 0x00000000, 0x00000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000000,
         0x00000000, 0x00000000, 0x00000000, 0x00000800}};

    printf("Test %d: ", 5);
    reset();
    for (i = 0; i < 4; i++)
    {
        process(test3_block[i], 0);
    }
    process(test3_block[4], 1);

    return 0;
}
