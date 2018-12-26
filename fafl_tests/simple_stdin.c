#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#define CHUNK 32768

int main(int argc, char ** argv) {
  char file[CHUNK];
  size_t nread;

  gets(file);

  size_t flen = strlen(file);

  if (flen) {
      if (flen > 8) {
        printf("file size larger than 8 bytes: \n");
        switch(file[8]) {
          case 65: // 'A'
            printf("crashing case:\n");
            int *b = 0x1234;
            *b = 99;
            break;
          case 97: // 'a'
            printf("time out case: \n");
            sleep(3);
            break;
          case 42: // '*'
            printf("assert fail: \n");
            assert(0);
            break;
          case 63: // '?' <- '>' flip one can get this
            // test loop bucket
            if (file[7] == 60) { // '<' <- '>' flip one can get this
              uint8_t  j = 0, k = 0;
              uint8_t limit = file[7];

              for (j=0; j < limit; j++) {
                k++;
              }
              printf("counter k is %d\n", k);

            }
            else if (file[7] > 100) {
              printf("exit 1\n");
              return 1;
            }
            else {
              if ((file[6] + file[7]) == 100) {
                printf("rare case, huh?\n");
              }
              else {
                printf("very common case\n");
              }
            }
            break;
          default:
            printf("nothing happens\n");
            break;
        }
      }
      else if (flen > 2) {
        printf("file size smaller than 9 bytes but larger than 2 bytes: \n");
        switch(file[2]) {
          case 65: // 'A'
            printf("crashing case:\n");
            int *b = 0x1234;
            *b = 99;
            break;
          case 97: // 'a'
            printf("time out case: \n");
            sleep(5);
            break;
          case 42: // '*'
            printf("assert fail: \n");
            assert(0);
            break;
          case 63: // '?'
            printf("exit 1: \n");
            return 1;
          default:
            printf("nothing happens\n");
            break;
        }
      }
      else {
        printf("the file size must be at least 2 bytes\n");
      }
  }
  else {
    printf("input length 0\n");
  }
  return 0;
}
