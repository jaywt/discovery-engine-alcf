"""netns.py CMD [ARGS...]: run CMD in a private network namespace that has only loopback.

No root and no setuid helper. unshare(2) makes a user namespace that maps our own uid and gid
to themselves, plus a network namespace owned by it. Within the call we hold CAP_NET_ADMIN over
that namespace, just long enough to bring lo up. exec then drops every capability (we are not
uid 0 in there), so CMD runs as an ordinary process. Nothing it listens on is reachable from the
rest of the machine, and it has no route out. Works with the host's python3 (3.6 on SLES 15).
"""
import ctypes, fcntl, os, socket, struct, sys

CLONE_NEWUSER, CLONE_NEWNET = 0x10000000, 0x40000000
SIOCGIFFLAGS, SIOCSIFFLAGS, IFF_UP = 0x8913, 0x8914, 0x1
IFREQ = "16sH22x"  # struct ifreq on x86_64: 16-byte name + 24-byte union, flags first

uid, gid = os.getuid(), os.getgid()
libc = ctypes.CDLL(None, use_errno=True)
if libc.unshare(CLONE_NEWUSER | CLONE_NEWNET) != 0:
    sys.exit("netns.py: unshare: %s" % os.strerror(ctypes.get_errno()))
for path, text in (("/proc/self/setgroups", "deny"),
                   ("/proc/self/uid_map", "%d %d 1\n" % (uid, uid)),
                   ("/proc/self/gid_map", "%d %d 1\n" % (gid, gid))):
    with open(path, "w") as f:
        f.write(text)
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
flags = struct.unpack(IFREQ, fcntl.ioctl(s, SIOCGIFFLAGS, struct.pack(IFREQ, b"lo", 0)))[1]
fcntl.ioctl(s, SIOCSIFFLAGS, struct.pack(IFREQ, b"lo", flags | IFF_UP))
s.close()
os.execvp(sys.argv[1], sys.argv[1:])
