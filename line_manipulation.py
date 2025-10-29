lines = """
write_value "/proc/sys/vm/dirty_background_ratio" 5
write_value "/proc/sys/vm/dirty_ratio" 10
write_value "/proc/sys/vm/dirty_expire_centisecs" 500
write_value "/proc/sys/vm/dirty_writeback_centisecs" 200

write_value "/proc/sys/kernel/sched_autogroup_enabled" 0
write_value "/proc/sys/vm/stat_interval" 120

write_value "/proc/sys/vm/vfs_cache_pressure" 50
write_value "/proc/sys/vm/compaction_proactiveness" 0
write_value "/proc/sys/vm/page_lock_unfairness" 1
write_value "/proc/sys/vm/watermark_boost_factor" 5000
write_value "/proc/sys/vm/watermark_scale_factor" 5

write_value "/sys/kernel/mm/lru_gen/enabled" 0x7
write_value "/sys/kernel/mm/lru_gen/min_ttl_ms" 3000

write_value "/proc/sys/kernel/numa_balancing" 0
write_value "/sys/kernel/mm/ksm/run" 0
write_value "/sys/kernel/mm/transparent_hugepage/enabled" never

write_value "/proc/sys/vm/swappiness" 10
write_value "/sys/block/zram0/comp_algorithm" lz4
write_value "/sys/block/zram0/disksize" 4G
write_value "/sys/block/zram0/mem_limit" 4G

write_value "/proc/sys/vm/page-cluster" 0

write_value "/proc/sys/kernel/printk_devkmsg" off
write_value "/proc/sys/kernel/timer_migration" 0
write_value "/proc/sys/kernel/sched_child_runs_first" 1
write_value "/proc/sys/kernel/sched_schedstats" 0
write_value "/proc/sys/kernel/sched_nr_migrate" 1
write_value "/proc/sys/kernel/sched_min_task_util_for_colocation" 0
write_value "/proc/sys/kernel/sched_tunable_scaling" 0
write_value "/proc/sys/kernel/sched_migration_cost_ns" 5000000
write_value "/proc/sys/kernel/sched_min_granularity_ns" 10000000
write_value "/proc/sys/kernel/sched_wakeup_granularity_ns" 2000000
write_value "/sys/kernel/debug/sched_features" GENTLE_FAIR_SLEEPERS
write_value "/sys/kernel/debug/sched_features" NEXT_BUDDY
write_value "/sys/kernel/debug/sched_features" TTWU_QUEUE
write_value "/sys/kernel/debug/sched_features" START_DEBIT
write_value "/dev/stune/top-app/schedtune.prefer_idle" 1
write_value "/dev/stune/top-app/schedtune.boost" 15
write_value "/sys/module/mmc_core/parameters/use_spi_crc" 0
write_value "/sys/module/workqueue/parameters/power_efficient" 0
# Disable watchdog
write_value "/sys/module/workqueue/parameters/watchdog_thresh" 0
write_value "/proc/sys/net/ipv4/tcp_ecn" 1
write_value "/proc/sys/net/ipv4/tcp_fastopen" 3
write_value "/proc/sys/net/ipv4/tcp_syncookies" 0
write_value "/proc/sys/net/ipv4/tcp_low_latency" 1
write_value "/proc/sys/net/ipv4/tcp_timestamps" 0
write_value "/proc/sys/net/ipv4/tcp_slow_start_after_idle" 0
write_value "/proc/sys/net/ipv4/tcp_congestion_control" bbr
#
write_value "/proc/sys/net/ipv4/tcp_no_metrics_save" 1
write_value "/proc/sys/net/ipv4/tcp_tw_reuse" 0
write_value "/proc/sys/net/ipv4/tcp_window_scaling" 0
"""


def main():
    # result = set()
    result = list()
    for line in lines.split('\n'):
        line = line.strip()
        if line:
            if line.startswith('#'):
                continue
            # line = f'"{line}"'
            # line = f'write_value "{line}" '
            line = line[line.index('"'):line.rindex('"') + 1]
            # result.add(line)
            result.append(line)

    for line in result:
        print(line)


if __name__ == "__main__":
    main()
