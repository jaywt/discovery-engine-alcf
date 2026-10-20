# nscheck.sh UID SIF: run inside netns.py by dle_up.sh before the namespace is trusted.
[ "$(id -u)" = "$1" ] || { echo "uid is $(id -u), expected $1"; exit 3; }
ifs=$(awk 'NR > 2 { sub(":", "", $1); printf "%s ", $1 }' /proc/net/dev)
[ "$ifs" = "lo " ] || { echo "interfaces: $ifs"; exit 4; }
python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); s.listen(1); socket.create_connection(s.getsockname(), 2)' \
  || { echo "loopback does not connect"; exit 5; }
apptainer exec --cleanenv "$2" true || { echo "apptainer cannot run in here"; exit 6; }
echo "ok: uid $(id -u), interfaces: $ifs, apptainer runs"
