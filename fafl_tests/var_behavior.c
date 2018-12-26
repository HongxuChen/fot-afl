#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;

static u32 UR(u32 limit) {
  return rand() % limit;
}

int main(void) {
    srand ( time(NULL) );
    u32 n = UR(8);
    printf("n=%d\n", n);
    for(int i = 0; i < n; ++i) {
        printf("\r");
        printf("i=%d", i);
        n = UR(8);
    }
    usleep(359321);
}
