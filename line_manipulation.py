def main():
    lines = """
    /proc/sys/kernel/printk_devkmsg
    /proc/sys/kernel/timer_migration
    /proc/sys/kernel/sched_child_runs_first
    /proc/sys/kernel/sched_schedstats
    /proc/sys/kernel/sched_nr_migrate
    /proc/sys/kernel/sched_min_task_util_for_colocation
    /proc/sys/kernel/sched_tunable_scaling
    /proc/sys/kernel/sched_migration_cost_ns
    /proc/sys/kernel/sched_min_granularity_ns
    /proc/sys/kernel/sched_wakeup_granularity_ns
    /sys/kernel/debug/sched_features
    /sys/kernel/debug/sched_features
    /dev/stune/top-app/schedtune.prefer_idle
    /dev/stune/top-app/schedtune.boost
    /sys/module/mmc_core/parameters/use_spi_crc
    /sys/module/workqueue/parameters/power_efficient
    /proc/sys/net/ipv4/tcp_tw_reuse
    /proc/sys/net/ipv4/tcp_ecn
    /proc/sys/net/ipv4/tcp_fastopen
    /proc/sys/net/ipv4/tcp_syncookies
    /proc/sys/net/ipv4/tcp_no_metrics_save
    /proc/sys/net/ipv4/tcp_low_latency
    /proc/sys/net/ipv4/tcp_timestamps
    /proc/sys/net/ipv4/tcp_slow_start_after_idle
    /proc/sys/net/ipv4/tcp_window_scaling
    /proc/sys/net/ipv4/tcp_congestion_control
    /proc/sys/net/ipv4/route.flush
    /sys/block/*/queue/add_random
    /sys/block/*/queue/iostats
    /sys/block/*/queue/read_ahead_kb
    /sys/block/*/queue/nr_requests
    /sys/module/workqueue/parameters/watchdog_thresh
    """

    for line in lines.split('\n'):
        line = line.strip()
        if line:
            # line = f'"{line}"'
            line = f'write_value "{line}" '
            print(line)

if __name__ == "__main__":
    main()