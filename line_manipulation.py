lines = """
write_value "/proc/sys/net/ipv4/tcp_no_metrics_save" 1
write_value "/proc/sys/net/ipv4/tcp_tw_reuse" 1
write_value "/proc/sys/net/ipv4/tcp_window_scaling" 1
write_value "/proc/sys/net/ipv4/tcp_congestion_control" bbr
"""


def main():
    result = set()
    for line in lines.split('\n'):
        line = line.strip()
        if line:
            if line.startswith('#'):
                continue
            # line = f'"{line}"'
            # line = f'write_value "{line}" '
            line = line[line.index('"'):line.rindex('"') + 1]
            result.add(line)

    for line in result:
        print(line)


if __name__ == "__main__":
    main()
