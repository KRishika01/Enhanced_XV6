#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

char *syscall_names[] = {
    "unknown",
    "fork",
    "exit",
    "wait",
    "pipe",
    "read",
    "kill",
    "exec",
    "fstat",
    "chdir",
    "dup",
    "getpid",
    "sbrk",
    "sleep",
    "uptime",
    "open",
    "write",
    "mknod",
    "unlink",
    "link",
    "mkdir",
    "close",
    "waitx",
    "getSysCount",
    "sigalarm",
    "sigreturn",
};


// extern char *syscall_names[];

// int sys_getSysCount(void)
// {
//     int mask;
//     struct proc *p = myproc();  // Get the current process

//     // Fetch the mask provided by the user program
//     // if (argint(0, &mask) < 0) {
//     //     return -1;
//     // }
//     argint(0,&mask);
//     // Find the syscall based on the mask
//     int syscall_index = 0;
//     for (int i = 0; i < 32; i++) {
//         if (mask == (1 << i)) {
//             syscall_index = i;
//             break;
//         }
//     }

//     // Sum syscall counts from the current process
//     int total_syscall_count = p->sysCounter[syscall_index];

//     printf("Parent process (PID %d) syscall count: %d\n", p->pid, total_syscall_count);  // Debugging parent process syscall count

//     // Lock proc table
//     acquire(&proc->lock);

//     // Iterate over all processes to sum the counts from child processes
//     // for (int i = 0; i < NPROC; i++) {
//     //     struct proc *child = &proc[i];

//     //     // Check if this process is a child of the current process and is in ZOMBIE state
//     //     if (child->parent == p && child->state == ZOMBIE) {
//     //         printf("Found child process (PID %d) with syscall count: %d\n", child->pid, child->sysCounter[syscall_index]);  // Debug child syscalls
//     //         total_syscall_count += child->sysCounter[syscall_index];  // Sum child's syscall count
//     //     }
//     // }

//     for(int i=0;i<32;i++) {
//       printf("In sysproc.c syscall %d called %d times\n",i,p->sysCounter[i]);
//     }

//     // Unlock proc table
//     release(&proc->lock);

//     // Print the result
//     printf("PID %d called %s %d times.\n", p->pid, syscall_names[syscall_index], total_syscall_count);

//     return 0;
// }

uint64
sys_getSysCount(void) {
  // printf("In getsyscount\n");
  int mask;
  struct proc *my_proc = myproc();
  argint(0,&mask);

  int index = 0;
  // int new_mask = mask;
  for(int i=0;i<32;i++) {
    if(mask == (1 << i)) {
      index = i;
      break;
    }
  }

  int counter_in_total = my_proc->sysCounter[index];

  printf("Parent process (PID %d) syscall count : %d\n",my_proc->pid,counter_in_total);
  acquire(&proc->lock);
  for(int i=0;i<NPROC;i++) {
    // printf("Entered\n");
    struct proc *child = &proc[i];
    struct proc *child_proc = child;

    if(child_proc->parent == my_proc && child_proc->state == ZOMBIE) {
      printf("There is a child process with (PID %d) with syscount %d\n",child_proc->pid,child_proc->sysCounter[index]);
      counter_in_total += child_proc->sysCounter[index];
    }
  }

  for(int i=0;i<32;i++) {
    printf("In sysproc.c syscall %d called %d times.\n",i,my_proc->sysCounter[i]);
  }
  release(&proc->lock);
  printf("PID %d called %s %d times.\n",my_proc->pid,syscall_names[index],counter_in_total);
  return 0;
}

uint64
sys_sigalarm(void) {
  uint64 addr;
  int ticks_sigalarm;

  argint(0,&ticks_sigalarm);
  argaddr(1,&addr);
  struct proc *p = myproc();

  p->ticks_of_alarm = ticks_sigalarm;
  p->handling_alarm = addr;
  if(ticks_sigalarm == 1) {
    p->ticks_of_alarm = 0;
  }
  // p->ticks_of_alarm = 0;

  return 0;
}

uint64
sys_sigreturn(void) {
  struct proc *p = myproc();
  if(p->trapframe_alarm) {
    memmove(p->trapframe,p->trapframe_alarm,sizeof(struct trapframe));
    kfree(p->trapframe_alarm);
    p->trapframe_alarm = 0;
    p->alarm_status = 0;
    // p->cur_ticks = 0;
  }
  // p->alarm_on = 0;
  return 0;
}

uint64
sys_settickets(void) {
  int number;
  argint(0,&number);
  return settickets(number);
}