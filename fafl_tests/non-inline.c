void foo(char *a) {
  if (a)
    *a = 0;
}

int main(int argc, char** argv) {
    if (argc == 2) {
        foo(argv[1]);
    }
}
