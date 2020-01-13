#include "cmd.h"

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <unistd.h>

int system_cmd(char * const *argv, char *output_buffer, int length)
{
    int pipefd[2];
    if (pipe(pipefd) < 0)
        return -1;

    pid_t pid = fork();
    if (pid == 0) {
        // child
        int devnull = open("/dev/null", O_RDWR);
        if (devnull < 0)
            exit(EXIT_FAILURE);

        close(pipefd[0]); // no reads from the pipe
        close(STDIN_FILENO);
        close(STDOUT_FILENO);
        dup2(devnull, STDIN_FILENO);
        dup2(pipefd[1], STDOUT_FILENO);
        close(devnull);

        execvp(argv[0], argv);

        // Not supposed to reach here.
        exit(EXIT_FAILURE);
    } else {
        // parent
        close(pipefd[1]); // No writes to the pipe

        if (length > 0) {
            memset(output_buffer, 0, length);
            length--; // Save room for a final '\0'
        }

        int index = 0;
        for (;;) {
            char throwaway[256];

            char *p;
            int amount_to_read = length - index;
            if (amount_to_read > 0) {
                p = &output_buffer[index];
            } else {
                p = throwaway;
                amount_to_read = sizeof(throwaway);
            }

            int amount_read = read(pipefd[0], p, amount_to_read);
            if (amount_read <= 0)
                break;

            if (p != throwaway)
                index += amount_read;
        }

        close(pipefd[0]);

        int status;
        if (waitpid(pid, &status, 0) != pid)
            return -1;

        return status;
    }
}