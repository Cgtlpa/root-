#include <iostream>
#include <sys/types.h>
#include <unistd.h>
#include <vector>

int main(int argc, char *argv[]) {
  // 1. Ensure a command was provided
  if (argc < 2) {
    std::cerr << "Usage: root <command> [args...]\n";
    return 1;
  }

  // 2. Obtain real user ID (who ran the program)
  // uid_t real_uid = getuid();

  // In a full implementation, you would check if real_uid is
  // authorized in a config file or prompt for authentication here.

  // 3. Elevate privileges to root (UID 0)
  if (setuid(0) != 0) {
    std::perror("Failed to setuid to root");
    return 1;
  }

  // 4. Prepare arguments for execvp
  std::vector<char *> exec_args;
  for (int i = 1; i < argc; ++i) {
    exec_args.push_back(argv[i]);
  }
  exec_args.push_back(nullptr); // Null-terminate the argument array

  // 5. Execute the target program
  execvp(exec_args[0], exec_args.data());

  // If execvp returns, an error occurred
  std::perror("Execution failed");
  return 1;
}
