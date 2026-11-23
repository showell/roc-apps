// count_allocs: how many times a program calls three functions, counted by
// breakpoints, as gdb's "breakpoint already hit N times" counts them.
//
//   count_allocs OUT ALLOC REALLOC DEALLOC PROGRAM [ARG]...
//
// ALLOC, REALLOC and DEALLOC are the addresses `nm PROGRAM` gives roc_alloc,
// roc_realloc and roc_dealloc, in hex. PROGRAM runs under ptrace with a
// breakpoint at each; its output is its own. When it exits, OUT gets one
// line, `alloc N realloc N dealloc N`, and count_allocs exits as it did.
//
// **WHY BREAKPOINTS:** Roc 0.1.0-RC1's default platform links its allocator
// into a static executable, which takes memory from the kernel a few large
// pieces at a time (brk), so counting mmap calls (the controls' method
// before RC1) no longer sees an allocation. roc_alloc is the one door every
// allocation of the Roc's goes through, and a breakpoint there counts each
// call of the very executable that is timed, with nothing relinked.
//
// The program must be single-threaded (BASIC's is): a thread it started
// would not be traced, and would stop on the first breakpoint it hit.
// Built by tools/alloc_ladder.shale with the system's C compiler.

#define _GNU_SOURCE
#include <errno.h>
#include <inttypes.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ptrace.h>
#include <sys/user.h>
#include <sys/wait.h>
#include <unistd.h>

enum { POINTS = 3 };

static void die(const char *what) {
    fprintf(stderr, "count_allocs: %s: %s\n", what, strerror(errno));
    exit(125);
}

// The address the executable is loaded at: the start of its first mapping,
// the one at file offset 0.
static uintptr_t load_base(pid_t pid) {
    char path[64];
    snprintf(path, sizeof path, "/proc/%d/maps", (int)pid);
    FILE *f = fopen(path, "r");
    if (f == NULL) die("open the program's maps");
    char line[4096];
    uintptr_t base = 0;
    while (fgets(line, sizeof line, f) != NULL) {
        uintptr_t start = 0, end = 0, offset = 0;
        char perms[8];
        if (sscanf(line, "%" SCNxPTR "-%" SCNxPTR " %7s %" SCNxPTR, &start, &end, perms, &offset) == 4 && offset == 0) {
            base = start;
            break;
        }
    }
    fclose(f);
    if (base == 0) {
        fprintf(stderr, "count_allocs: no mapping of the program at offset 0\n");
        exit(125);
    }
    return base;
}

static long peek(pid_t pid, uintptr_t at) {
    errno = 0;
    long w = ptrace(PTRACE_PEEKTEXT, pid, (void *)at, NULL);
    if (errno != 0) die("read the program's code");
    return w;
}

static void poke(pid_t pid, uintptr_t at, long w) {
    if (ptrace(PTRACE_POKETEXT, pid, (void *)at, (void *)w) != 0) die("write the program's code");
}

static long with_trap(long w) {
    return (w & ~0xffL) | 0xcc;
}

int main(int argc, char **argv) {
    if (argc < 6) {
        fprintf(stderr, "usage: count_allocs OUT ALLOC REALLOC DEALLOC PROGRAM [ARG]...\n");
        return 125;
    }
    uintptr_t offsets[POINTS];
    for (int i = 0; i < POINTS; i++) offsets[i] = (uintptr_t)strtoull(argv[2 + i], NULL, 16);
    pid_t pid = fork();
    if (pid < 0) die("fork");
    if (pid == 0) {
        if (ptrace(PTRACE_TRACEME, 0, NULL, NULL) != 0) die("trace the program");
        execv(argv[5], argv + 5);
        die("start the program");
    }
    int status = 0;
    // The stop at the program's exec, before it runs a line.
    if (waitpid(pid, &status, 0) != pid || !WIFSTOPPED(status)) die("wait for the program's start");
    if (ptrace(PTRACE_SETOPTIONS, pid, NULL, (void *)PTRACE_O_EXITKILL) != 0) die("set the trace's options");
    uintptr_t base = load_base(pid);
    uintptr_t at[POINTS];
    long saved[POINTS];
    uint64_t hits[POINTS] = {0, 0, 0};
    for (int i = 0; i < POINTS; i++) {
        at[i] = base + offsets[i];
        saved[i] = peek(pid, at[i]);
        poke(pid, at[i], with_trap(saved[i]));
    }
    int pass = 0;
    for (;;) {
        if (ptrace(PTRACE_CONT, pid, NULL, (void *)(intptr_t)pass) != 0) die("continue the program");
        pass = 0;
        if (waitpid(pid, &status, 0) != pid) die("wait for the program");
        if (WIFEXITED(status) || WIFSIGNALED(status)) break;
        if (!WIFSTOPPED(status)) continue;
        int sig = WSTOPSIG(status);
        if (sig != SIGTRAP) {
            pass = sig;
            continue;
        }
        struct user_regs_struct regs;
        if (ptrace(PTRACE_GETREGS, pid, NULL, &regs) != 0) die("read the program's registers");
        int which = -1;
        for (int i = 0; i < POINTS; i++) {
            if (regs.rip - 1 == at[i]) which = i;
        }
        if (which < 0) continue;
        hits[which]++;
        // The call's first instruction put back and run alone, then the
        // breakpoint set again.
        poke(pid, at[which], saved[which]);
        regs.rip -= 1;
        if (ptrace(PTRACE_SETREGS, pid, NULL, &regs) != 0) die("write the program's registers");
        if (ptrace(PTRACE_SINGLESTEP, pid, NULL, NULL) != 0) die("step the program");
        if (waitpid(pid, &status, 0) != pid) die("wait for the program's step");
        if (WIFEXITED(status) || WIFSIGNALED(status)) break;
        poke(pid, at[which], with_trap(saved[which]));
    }
    FILE *out = fopen(argv[1], "w");
    if (out == NULL) die("open OUT");
    fprintf(out, "alloc %" PRIu64 " realloc %" PRIu64 " dealloc %" PRIu64 "\n", hits[0], hits[1], hits[2]);
    if (fclose(out) != 0) die("write OUT");
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    return 128 + WTERMSIG(status);
}
