#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

int main()
{
  int n, pid;
  int wtime, rtime;
  int twtime = 0, trtime = 0;
  for (n = 0; n < NFORK; n++)
  {
    pid = fork();
    if (pid < 0)
      break;
    if (pid == 0)
    {
      if (n < IO)
      {
        settickets(5);
        sleep(200); // IO bound processes
      }
      else
      {
        settickets(15);
        for (volatile int i = 0; i < 1000000000; i++)
        {
        } // CPU bound process
      }
      printf("Process %d finished\n", n);
      exit(0);
    }
  }
  for (; n > 0; n--)
  {
    if (waitx(0, &wtime, &rtime) >= 0)
    {
      trtime += rtime;
      twtime += wtime;
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  exit(0);
}

// #include "kernel/types.h"
// #include "kernel/stat.h"
// #include "user/user.h"
// #include "kernel/fcntl.h"

// #define NCHILDREN 5
// #define RUNTIME 1000000000

// void spin()
// {
//     for (volatile int i = 0; i < RUNTIME; i++) {}
// }

// int main(int argc, char *argv[])
// {
//     int n, pid;
//     int wtime, rtime;
//     int twtime = 0, trtime = 0;

//     if (argc != NCHILDREN + 1) {
//         fprintf(2, "Usage: schedulertest t1 t2 t3 t4 t5\n");
//         fprintf(2, "Where t1, t2, ... are the number of tickets for each child process\n");
//         exit(1);
//     }

//     for (n = 0; n < NCHILDREN; n++) {
//         pid = fork();
//         if (pid < 0) {
//             fprintf(2, "Fork failed\n");
//             exit(1);
//         }
//         if (pid == 0) {
//             // Child process
//             int tickets = atoi(argv[n+1]);
//             sleep(n * 10);  // Stagger process start times
//             int new_tickets = settickets(tickets);
//             if (new_tickets != tickets) {
//                 fprintf(2, "settickets failed for process %d\n", n);
//                 exit(1);
//             }
//             printf("Child %d (PID: %d) set tickets to %d\n", n, getpid(), tickets);
//             spin();  // CPU-bound work
//             printf("Child %d (PID: %d) finished\n", n, getpid());
//             exit(0);
//         }
//     }

//     for (n = 0; n < NCHILDREN; n++) {
//         if (waitx(0, &wtime, &rtime) >= 0) {
//             printf("Child %d: wtime = %d, rtime = %d\n", n, wtime, rtime);
//             twtime += wtime;
//             trtime += rtime;
//         }
//     }

//     printf("Average wtime = %d, rtime = %d\n", twtime / NCHILDREN, trtime / NCHILDREN);
//     exit(0);
// }

// #include "kernel/types.h"
// #include "kernel/stat.h"
// #include "user/user.h"
// #include "kernel/fcntl.h"

// #define NFORK 10
// #define IO 5

// int main()
// {
//     int n, pid;
//     int wtime, rtime;
//     int twtime = 0, trtime = 0;
//     for (n = 0; n < NFORK; n++)
//     {
//         pid = fork();
//         if (pid < 0)
//             break; // Fork failed
//         if (pid == 0) // Child process
//         {
//             // Set tickets based on the process type
//             if (n < IO)
//             {
//                 settickets(5); // Assign tickets for I/O-bound processes
//                 sleep(200);     // I/O-bound processes
//             }
//             else
//             {
//                 settickets(15); // Assign tickets for CPU-bound processes
//                 for (volatile int i = 0; i < 1000000000; i++)
//                 {
//                 } // CPU-bound process
//             }
//             printf("Process %d finished\n", n);
//             exit(0);
//         }
//     }
//     // Parent process waits for all child processes
//     for (; n > 0; n--)
//     {
//         if (waitx(0, &wtime, &rtime) >= 0)
//         {
//             trtime += rtime;
//             twtime += wtime;
//         }
//     }
//     // Print average turnaround time and waiting time
//     printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
//     exit(0);
// }
