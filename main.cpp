#include <iostream>
#include <sys/types.h>
#include <unistd.h>
#include <vector>

int main(int argc, char *argv[]) {
  if (argc < 2) {
    std::cerr << "Usage: root <command> [args...]\n";
    return 1;
  }


  if (setuid(0) != 0) {
    std::perror("Failed to setuid to root");
    return 1;
  }

  std::vector<char *> exec_args;
  for (int i = 1; i < argc; ++i) {
    exec_args.push_back(argv[i]);
  }
  exec_args.push_back(nullptr);

  execvp(exec_args[0], exec_args.data());

  std::perror("Execution failed");
  return 1;
//root is a simple replacement for sudo
}

