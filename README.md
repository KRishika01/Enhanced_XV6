# XV6 System Call and Scheduling Implementation

This project extends the XV6 operating system with additional system calls and scheduling algorithms. The implementation includes system call counting, process alarms, and two alternative scheduling policies.

## System Calls 
### 1. getSysCount - System Call Counter 
Added a new system call `getSysCount` and corresponding user program `syscount` that counts the number of times a specific system call is executed by a process.

#### Features:
- Tracks system call usage for a specified process and its children
- Takes an integer mask to specify which system call to count
- Outputs the count along with the system call name and process ID

#### Usage:
``` sh
syscount <mask> command [args]
```

### 2. Sigalarm & Sigreturn - Process Timer

Added system calls to alert a process periodically as it consumes CPU time.

#### Features:
- `sigalarm(interval, handler)`: Sets up a timer that triggers after the specified interval
- `sigreturn()`: Resets the process state to before the handler was called
- Allows processes to perform periodic actions during computation

## Scheduling Algorithms 

- Modified the XV6 scheduling system to support alternative scheduling policies declared at compile time.
- Build Options:

``` sh
make clean; make qemu                 # Default Round Robin
make clean; make qemu SCHEDULER=LBS   # Lottery Based Scheduling
make clean; make qemu SCHEDULER=MLFQ  # Multi Level Feedback Queue
```
###  Lottery Based Scheduling (LBS) 
- Implemented a preemptive lottery-based scheduling policy that assigns time slices to processes based on their ticket count.
- **Features** :

  - Each process gets 1 ticket by default
  - Processes with more tickets have a proportionally higher chance of being selected
  - Tiebreaker: When processes have the same number of tickets, the one with earlier arrival time wins
  - Added settickets(int number) system call to allow processes to adjust their ticket count

### Multi-Level Feedback Queue (MLFQ) 
- Implemented a preemptive MLFQ scheduler that dynamically adjusts process priorities based on behavior.
- **Features**:

  - Four priority queues (0-3, with 0 being highest priority)
  - Time slices vary by priority level:

    - Priority 0: 1 timer tick
    - Priority 1: 4 timer ticks
    - Priority 2: 8 timer ticks
    - Priority 3: 16 timer ticks


  - New processes start at the highest priority queue
  - Processes that use their full time slice are moved to a lower priority queue
  - Processes that voluntarily relinquish CPU (e.g., for I/O) remain at the same priority
  - Priority boosting every 48 ticks to prevent starvation
