#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdlib.h>

#define CHUNK 1024

int main(void) {
  char file[CHUNK];

  gets(file);

  if (file[8] == 'a') {
      fprintf(stderr, "[time out]\n");
      sleep(3);
  } else {
      printf("--> input=%s\n", file);
  }

    return 0;
}
