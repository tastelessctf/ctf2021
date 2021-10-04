# Filter, to be compiled with seccomp-tools
# check if arch is X86_64
A = arch
A == ARCH_X86_64 ? next : kill
A = sys_number
A == close ? allow : next
A == write ? allow : next
A == fcntl ? allow : next
A == fstat ? allow : next
A == madvise ? allow : next
A == mremap ? allow : next
A == munmap ? allow : next
A == clock_gettime ? allow : next

A == exit ? allow : next
A == exit_group ? allow : next
A == rt_sigaction ? allow : next

A == mmap ? next : kill
A = args[0] 
A == 0 ? next : kill
# No Exec Maps plz
A = args[2] 
A &= 0x4
A == 4 ? kill : next
# Only private mappings
A = args[3]
A &= 0xf
A == 0x2 ? next : kill
A = args[5] 
A == 0 ? next : kill

allow:
return ALLOW
kill:
return KILL
