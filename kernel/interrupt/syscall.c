#include "kernel/interrupt/syscall.h"
#include "kernel/config/interrupt.h"
#include "kernel/config/memory.h"
#include "kernel/device/vga.h"
#include "kernel/log.h"
#include "kernel/task/task.h"
#include "kernel/utils/print.h"
#include "kernel/utils/string.h"
#include "lib/syscall.h"
#include "lib/types.h"

static void* __sysall_table[INTR_SYSCALL_SIZE] = { 0 };

void
init_syscall(void)
{
  __sysall_table[SYSCALL_GETPID] = syscall_getpid;
  __sysall_table[SYSCALL_WRITE] = syscall_write;
}

size_t
syscall_getpid(void)
{
  return task_current()->pid;
}

size_t
syscall_write(char* buf)
{
  kputs_nint(buf);
  return kstrlen(buf);
}

void*
syscall_common_handler(u32 index, void* arg1, void* arg2, void* arg3)
{
  syscall_handler_t handler = __sysall_table[index];
  if (handler != NULL) {
    return handler(arg1, arg2, arg3);
  } else {
    KWARNING_NINT("unhandled syscall: %u", index);
    return NULL;
  }
}