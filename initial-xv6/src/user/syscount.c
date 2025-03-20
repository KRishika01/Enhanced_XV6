#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

int
main(int argc,char *argv[]) {
    if(argc < 3) {
        printf("Error in giving the input\n");
        printf("The input format is : syscount <mask> <command> [args....]\n");
        exit(0);
    }

    int mask = atoi(argv[1]);
    int returnCode = fork();
    if(returnCode < 0) {
        printf("Error in forking\n");
        exit(0);
    }
    else if(returnCode == 0) {
        exec(argv[2],&argv[2]);
        printf("Error in exec\n");
        exit(0);
    }
    else {
        wait(0);
        getSysCount(mask);
    }
    return 0;
}