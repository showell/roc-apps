// count_copies: which builtin each of a Roc program's allocations came
// through, and from which call site in the Roc code, counted by
// breakpoints: count_allocs' sibling, for tools/copy_oracle.shale.
//
//   count_copies OUT PLAN PROGRAM [ARG]...
//
// PLAN names the addresses, `nm PROGRAM`'s, in hex, one a line:
//
//   alloc <addr>           roc_alloc
//   realloc <addr>         roc_realloc
//   entry <addr> <id>      a builtin's first instruction, and its number
//   roc <start> <end>      a Roc procedure's code, [start, end)
//
// **WHY:** RC1 writes into a list in place when its refcount is 1 and
// otherwise copies it, and the copy is an allocation made inside the
// builtin (list_set, list_replace, list_swap, the appends). The builtins
// stay named functions in both the dev and the release build, so a
// breakpoint at each builtin's entry reads the return address there, the
// call site in a Roc procedure, and a breakpoint at roc_alloc reads its
// own: an allocation whose return address is in no Roc procedure was made
// by builtin code, and is the last builtin entered from Roc code's. An
// allocation from a Roc procedure itself (a list literal, a record boxed)
// is counted as `direct`.
//
// OUT gets one line a key, aggregated:
//
//   entry <id> <sites> <count>       a builtin entered from a call site
//   via <kind> <id> <sites> <count>  allocations (`alloc` or `realloc`)
//                                    made inside a builtin entered there
//   direct <kind> <sites> <count>    allocations made by Roc code itself
//
// <sites> is the call site and the return addresses above it, up to six,
// by the frame pointers (`rbp`) as far as they lead, comma-separated: the
// first is the builtin's caller, often the Builtin module's own Roc code
// (`List.set`), and a later one the program's procedure that called it.
// Each is an offset from the program's load address, in hex, as nm's
// addresses are. count_copies exits as the program did. The program must
// be single-threaded, as for count_allocs.
// Built by tools/copy_oracle.shale with the system's C compiler.

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

enum { MAX_POINTS = 512, MAX_RANGES = 65536, TABLE = 1 << 16, CHAIN = 6 };

enum { KIND_ALLOC = 0, KIND_REALLOC = 1 };

typedef struct {
    uintptr_t at;
    long saved;
    int id;   // a builtin's number; -1 for roc_alloc, -2 for roc_realloc
} Point;

typedef struct {
    uintptr_t start, end;
} Range;

// The call sites a count is kept for: the caller, and those above it.
typedef struct {
    uintptr_t at[CHAIN];
} Sites;

// One aggregated count: what, which builtin, which call sites.
typedef struct {
    int used;
    int what;  // 0 entry, 1 via, 2 direct
    int kind;
    int id;
    Sites sites;
    uint64_t count;
} Slot;

static Point points[MAX_POINTS];
static int point_count = 0;
static Range ranges[MAX_RANGES];
static int range_count = 0;
static Slot table[TABLE];

static void die(const char *what) {
    fprintf(stderr, "count_copies: %s: %s\n", what, strerror(errno));
    exit(125);
}

static void refuse(const char *what) {
    fprintf(stderr, "count_copies: %s\n", what);
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
    if (base == 0) refuse("no mapping of the program at offset 0");
    return base;
}

static long peek(pid_t pid, uintptr_t at) {
    errno = 0;
    long w = ptrace(PTRACE_PEEKTEXT, pid, (void *)at, NULL);
    if (errno != 0) die("read the program's memory");
    return w;
}

static void poke(pid_t pid, uintptr_t at, long w) {
    if (ptrace(PTRACE_POKETEXT, pid, (void *)at, (void *)w) != 0) die("write the program's code");
}

static long with_trap(long w) {
    return (w & ~0xffL) | 0xcc;
}

static int compare_ranges(const void *a, const void *b) {
    const Range *x = a, *y = b;
    return x->start < y->start ? -1 : x->start > y->start ? 1 : 0;
}

// Whether an offset is inside a Roc procedure, by binary search.
static int in_roc(uintptr_t offset) {
    int lo = 0, hi = range_count - 1;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (offset < ranges[mid].start) {
            hi = mid - 1;
        } else if (offset >= ranges[mid].end) {
            lo = mid + 1;
        } else {
            return 1;
        }
    }
    return 0;
}

static void count(int what, int kind, int id, const Sites *sites) {
    uint64_t h = ((uint64_t)(id + 7) << 40) ^ ((uint64_t)what << 56) ^ ((uint64_t)kind << 60);
    for (int i = 0; i < CHAIN; i++) h = (h ^ sites->at[i]) * 0x9e3779b97f4a7c15ULL;
    for (uint64_t probe = 0; probe < TABLE; probe++) {
        Slot *s = &table[(h + probe) & (TABLE - 1)];
        if (!s->used) {
            *s = (Slot){1, what, kind, id, *sites, 1};
            return;
        }
        if (s->what == what && s->kind == kind && s->id == id && memcmp(&s->sites, sites, sizeof *sites) == 0) {
            s->count++;
            return;
        }
    }
    refuse("more call sites than the table holds");
}

// At a function's first instruction: its return address, then those the
// frame pointers lead to, each an offset from `base`. A frame pointer that
// is not above the last, or not within 64 MiB of the stack's top, ends the
// walk: code built without them leaves `rbp` as anything.
static Sites sites_at(pid_t pid, const struct user_regs_struct *regs, uintptr_t base) {
    Sites s;
    memset(&s, 0, sizeof s);
    s.at[0] = (uintptr_t)peek(pid, regs->rsp) - base;
    uintptr_t frame = regs->rbp;
    uintptr_t floor = regs->rsp;
    for (int i = 1; i < CHAIN; i++) {
        if (frame <= floor || frame - regs->rsp > ((uintptr_t)64 << 20) || (frame & 7) != 0) break;
        uintptr_t back = (uintptr_t)peek(pid, frame + 8);
        if (back < base) break;
        s.at[i] = back - base;
        floor = frame;
        frame = (uintptr_t)peek(pid, frame);
    }
    return s;
}

static void read_plan(const char *path) {
    FILE *f = fopen(path, "r");
    if (f == NULL) die("open PLAN");
    char line[512];
    while (fgets(line, sizeof line, f) != NULL) {
        uintptr_t a = 0, b = 0;
        int id = 0;
        if (sscanf(line, "alloc %" SCNxPTR, &a) == 1) {
            if (point_count == MAX_POINTS) refuse("too many breakpoints in PLAN");
            points[point_count++] = (Point){a, 0, -1};
        } else if (sscanf(line, "realloc %" SCNxPTR, &a) == 1) {
            if (point_count == MAX_POINTS) refuse("too many breakpoints in PLAN");
            points[point_count++] = (Point){a, 0, -2};
        } else if (sscanf(line, "entry %" SCNxPTR " %d", &a, &id) == 2) {
            if (point_count == MAX_POINTS) refuse("too many breakpoints in PLAN");
            points[point_count++] = (Point){a, 0, id};
        } else if (sscanf(line, "roc %" SCNxPTR " %" SCNxPTR, &a, &b) == 2) {
            if (range_count == MAX_RANGES) refuse("too many Roc procedures in PLAN");
            ranges[range_count++] = (Range){a, b};
        } else if (line[0] != '\n' && line[0] != '#') {
            fprintf(stderr, "count_copies: PLAN: not a line it reads: %s", line);
            exit(125);
        }
    }
    fclose(f);
    qsort(ranges, (size_t)range_count, sizeof ranges[0], compare_ranges);
}

int main(int argc, char **argv) {
    if (argc < 4) {
        fprintf(stderr, "usage: count_copies OUT PLAN PROGRAM [ARG]...\n");
        return 125;
    }
    read_plan(argv[2]);
    pid_t pid = fork();
    if (pid < 0) die("fork");
    if (pid == 0) {
        if (ptrace(PTRACE_TRACEME, 0, NULL, NULL) != 0) die("trace the program");
        execv(argv[3], argv + 3);
        die("start the program");
    }
    int status = 0;
    // The stop at the program's exec, before it runs a line.
    if (waitpid(pid, &status, 0) != pid || !WIFSTOPPED(status)) die("wait for the program's start");
    if (ptrace(PTRACE_SETOPTIONS, pid, NULL, (void *)PTRACE_O_EXITKILL) != 0) die("set the trace's options");
    uintptr_t base = load_base(pid);
    for (int i = 0; i < point_count; i++) {
        points[i].at += base;
        points[i].saved = peek(pid, points[i].at);
        poke(pid, points[i].at, with_trap(points[i].saved));
    }
    // The last builtin entered from Roc code, and where from.
    int last_id = -1;
    Sites last_sites;
    memset(&last_sites, 0, sizeof last_sites);
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
        for (int i = 0; i < point_count; i++) {
            if (regs.rip - 1 == points[i].at) which = i;
        }
        if (which < 0) continue;
        // At a function's first instruction the return address is on top
        // of the stack.
        uintptr_t back = (uintptr_t)peek(pid, regs.rsp) - base;
        int id = points[which].id;
        if (id >= 0) {
            if (in_roc(back)) {
                last_id = id;
                last_sites = sites_at(pid, &regs, base);
                count(0, 0, id, &last_sites);
            }
        } else {
            int kind = id == -1 ? KIND_ALLOC : KIND_REALLOC;
            if (in_roc(back)) {
                Sites here = sites_at(pid, &regs, base);
                count(2, kind, -1, &here);
            } else {
                count(1, kind, last_id, &last_sites);
            }
        }
        // The call's first instruction put back and run alone, then the
        // breakpoint set again.
        poke(pid, points[which].at, points[which].saved);
        regs.rip -= 1;
        if (ptrace(PTRACE_SETREGS, pid, NULL, &regs) != 0) die("write the program's registers");
        if (ptrace(PTRACE_SINGLESTEP, pid, NULL, NULL) != 0) die("step the program");
        if (waitpid(pid, &status, 0) != pid) die("wait for the program's step");
        if (WIFEXITED(status) || WIFSIGNALED(status)) break;
        poke(pid, points[which].at, with_trap(points[which].saved));
    }
    FILE *out = fopen(argv[1], "w");
    if (out == NULL) die("open OUT");
    static const char *kinds[] = {"alloc", "realloc"};
    for (int i = 0; i < TABLE; i++) {
        Slot *s = &table[i];
        if (!s->used) continue;
        char chain[CHAIN * 20];
        int at = 0;
        for (int k = 0; k < CHAIN && (k == 0 || s->sites.at[k] != 0); k++) {
            at += snprintf(chain + at, sizeof chain - (size_t)at, "%s%" PRIxPTR, k == 0 ? "" : ",", s->sites.at[k]);
        }
        if (s->what == 0) {
            fprintf(out, "entry %d %s %" PRIu64 "\n", s->id, chain, s->count);
        } else if (s->what == 1) {
            fprintf(out, "via %s %d %s %" PRIu64 "\n", kinds[s->kind], s->id, chain, s->count);
        } else {
            fprintf(out, "direct %s %s %" PRIu64 "\n", kinds[s->kind], chain, s->count);
        }
    }
    if (fclose(out) != 0) die("write OUT");
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    return 128 + WTERMSIG(status);
}
