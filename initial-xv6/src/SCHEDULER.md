
# SCHEDULING
There are three scheduling policies that are implemented in thi project.
1) Round Robin (By default)
2) Lottery-based-scheduling (LBS)
3) Multi-level Feedback Queue (MLFQ)

Commands to run
```bash
make clean
make qemu SCHEDULER=<typeofscheduler>
```

##  Lottery-based-scheduling

Lottery based scheduling is a probabilistic scheduling policy where each process is assigned with certain number of tickets.

Processes with more number of tickets have higher chance of winning the lottery.
At each scheduling decision point, the schedulers holds the lottery and winning process gets to run.
Each process gets proportinal amount of CPU time based on the number of tickets each process holds.

### Implementation

#### In proc.h :
```c 
    int tickets;
    int start_time_lbs;
```

#### In proc.c :
```c
    In `allocproc()` :
    #ifdef LBS
        p->tickets = 1;
        p->start_time_lbs = ticks;
    #endif

    In `fork()` :
    #ifdef LBS
        np->tickets = p->tickets;
    #endif

    In `scheduler()` :
    #ifdef LBS
    struct proc *p;
    int total_tickets = 0;
    for(p = proc;p< &proc[NPROC];p++) {
        acquire(&p->lock);
        if(p->state == RUNNABLE) {
        total_tickets += p->tickets;
        }
        release(&p->lock);
    }
    if(total_tickets > 0) {
        int winner = rand() % total_tickets;

        struct proc *chosen = 0;
        int current_tickets = 0;

        for(p = proc;p < &proc[NPROC];p++) {
        acquire(&p->lock);
        if(p->state == RUNNABLE) {
            current_tickets += p->tickets;
            if(current_tickets > winner && (!chosen || (chosen->tickets == p->tickets && p->start_time_lbs < chosen->start_time_lbs))) {
            if(chosen) {
                release(&chosen->lock);
            }
            chosen = p;
            }
            else {
            release(&p->lock);
            }
        }
        else {
            release(&p->lock);
        }
        }
        if(chosen) {
        chosen->state = RUNNING;
        c->proc = chosen;
        swtch(&c->context,&chosen->context);
        c->proc = 0;
        release(&chosen->lock);
        }
    }
    #endif

    In `procdump()` :
    #ifdef LBS
        printf("LBS\n");
        printf("%d %s %s %d Tickets:%d\n",p->pid,state,p->name,ticks - p->start_time_lbs,p->tickets);
    #endif
```

## output 

``` bash
Process 7 finished
Process 6 finished
Process 5 finished
Process 9 finished
Process 8 finished
Process 2 finished
Process 0 finished
Process 3 finished
Process 4 finished
Process 1 finished
Average rtime 14,  wtime 148
```
## Usage :

During compiling run : 
``` bash
make clean
make qemu CPUS=2 SCHEDULER=LBS
```

## Multilevel Feedback Queue

MLFQ is designed to dynamically adjust the priority of the processes based on their execution behavoiur.

Processes in higher priority queue are given CPU time before the processes in lower priority queues.

### Implementation

#### In proc.h :
    ```c
        int priority_queue_number;
        int start_time;
        int wait_ticks;
        int status_queue;
        int number_process;

        #ifdef MLFQ
            struct MLFQ_queue {
            int head;
            int tail;
            int length;
            int priority_queue_ticks;
            struct proc *mlfq_queue[NPROC];
            };
            extern struct MLFQ_queue queue[4];
            struct proc *pop(int queue_number);

        #endif
    ```

#### In proc.c :
    ```c
        #ifdef MLFQ
            #define queue_size 4
        #endif

        #ifdef MLFQ
            struct MLFQ_queue queue[queue_size];
        #endif

        struct proc *pop(int queue_number) {
            if(queue[queue_number].tail < 0) {
                panic("Queue is empty");
            }

            struct proc *mypro;
            mypro = queue[queue_number].mlfq_queue[0];
            queue[queue_number].mlfq_queue[0] = 0;

            for(int i=0;i<NPROC-1;i++) {
                queue[queue_number].mlfq_queue[i] = queue[queue_number].mlfq_queue[i+1];
            }
            queue[queue_number].tail = queue[queue_number].tail - 1;
            queue[queue_number].length = queue[queue_number].length - 1;
            mypro->status_queue = 0;
            return mypro;
        }

        In `allocproc()` :
            #ifdef MLFQ
                p->wait_ticks = 0;
                p->status_queue = 0;
                p->priority_queue_number = 0;
            #endif

        In `userinit()` :
            #ifdef MLFQ
            // initialising queue for mlfq
                int priority_queue_ticks[] = {1,4,8,16};
                for(int i=0;i<queue_size;i++) {
                    queue[i].priority_queue_ticks = priority_queue_ticks[i];
                    queue[i].head = 0;
                    queue[i].tail = 0;
                    queue[i].length = 0;
                    for(int k=0;k<48;k++) {
                        queue[i].mlfq_queue[k] = 0;
                    }
                }
            #endif

        In scheduler() :
            I added a code that implements the MLFQ.
        In procdump() :
            #ifdef MLFQ
                printf("%d %s %s %d Time : %d\n",p->pid,state,p->name,p->number_process,ticks-p->start_time);
            #endif
    ```
#### In trap.c :

    ```c
        #ifdef MLFQ
            struct proc *current_process_track;
                for(current_process_track = proc;current_process_track < &proc[NPROC];current_process_track++) {
                    if(current_process_track->status_queue == 1 && current_process_track->state == RUNNABLE && current_process_track != 0) {
                    if(current_process_track->wait_ticks >= 48) {
                        current_process_track->status_queue = 0;
                        struct proc *newproc;
                        for(newproc = queue[current_process_track->priority_queue_number].mlfq_queue[0];newproc < current_process_track;newproc++) {


                        }
                        newproc = newproc + 1;
                        for(;newproc < queue[current_process_track->priority_queue_number].mlfq_queue[NPROC-1];newproc++) {
                        *(newproc - 1) = *(newproc);
                        }
                        queue[current_process_track->priority_queue_number].mlfq_queue[NPROC-1] = 0;
                        // deque(current_process_track->priority_queue_number,current_process_track);
                        if(current_process_track->priority_queue_number > 0) {
                        // int track_number = current_process_track->priority_queue_number;
                        // printf("Track_number %d\n",track_number);
                        current_process_track->priority_queue_number = current_process_track->priority_queue_number - 1;
                        }
                        // printf("Wait_ticks %d\n",current_process_track->wait_ticks);
                        current_process_track->wait_ticks = 0;
                    }
                }
            }
            #endif

            I also made some changes in (if(which_dev == 2)).
    ```

## Output :

``` bash
Process 5 finished
Process 6 finished
Process 7 finished
Process 8 finished
Process 9 finished
Process 0 finished
Process 1 finished
Process 2 finished
Process 3 finished
Process 4 finished
Average rtime 13,  wtime 140

```
## Usage :

During compiling run : 
``` bash
make clean
make qemu CPUS=2 SCHEDULER=MLFQ
```

# Overall comparision for all scheduling polices :

1) Waittime : MLFQ > LBS > RR (DEFAULT).
2) Avarage Runtime : MLFQ < LBS < RR (DEFAULT).

But sice I didn't implement priority boost I am getting the waittime og MLFQ is less than other two scheduling policies.

### Answers to the questions

1) What is the implication of adding the arrival time in the lottery based scheduling policy? 

Ans : The implication of adding arrival time to the LBS is it gives early arriving processes the priority if there is tie in number of tickets that it if both processes have same number of tickets.
-> This ensures that processes with equal tickets but different arrival times have a tie-breaking mechanism, favoring older processes.

2) Are there any pitfalls to watch out for? 

Ans : One pitfall is that earlier-arriving processes may take entire CPU time if they continually tie with others, leading to starvation of newer processes.

3) What happens if all processes have the same number of tickets?

Ans : If all the processes have same number of tickets then LBS is same as Round Robin.
