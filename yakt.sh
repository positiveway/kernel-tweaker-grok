#!/system/bin/sh

# YAKT v301
# Author: @NotZeetaa (Github)
# ×××××××××××××××××××××××××× #

sleep 30

# Function to append a message to the specified log file
log_message() {
    local log_file="$1"
    local message="$2"
    echo "[$(date "+%H:%M:%S")] $message" >> "$log_file"
}

# Function to log info messages
log_info() {
    log_message "$INFO_LOG" "$1"
}

# Function to log error messages
log_error() {
    log_message "$ERROR_LOG" "$1"
}

# Useful for debugging ig ¯\_(ツ)_/¯
# shellcheck disable=SC3033
# log_debug() {
#     log_message "$DEBUG_LOG" "$1"
# }

# Function to write a value to a specified file
write_value() {
    local file_path="$1"
    local value="$2"

    # Check if the file exists
    if [ ! -f "$file_path" ]; then
        log_error "Error: File $file_path does not exist."
        return 1
    fi

    # Make the file writable
    chmod +w "$file_path" 2>/dev/null

    # Write new value, log error if it fails
    if ! echo "$value" >"$file_path" 2>/dev/null; then
        log_error "Error: Failed to write to $file_path."
        return 1
    else
        return 0
    fi
}

MODDIR=${0%/*} # Get parent directory

# Modify the filenames for logs
INFO_LOG="${MODDIR}/info.log"
ERROR_LOG="${MODDIR}/error.log"
# DEBUG_LOG="${MODDIR}/debug.log"

# Prepare log files
:> "$INFO_LOG"
:> "$ERROR_LOG"
# :> "$DEBUG_LOG"

# Variables
UCLAMP_PATH="/dev/stune/top-app/uclamp.max"
CPUSET_PATH="/dev/cpuset"
MODULE_PATH="/sys/module"
KERNEL_PATH="/proc/sys/kernel"
IPV4_PATH="/proc/sys/net/ipv4"
NET_CORE_PATH="/proc/sys/net/core"
MEMORY_PATH="/proc/sys/vm"
MGLRU_PATH="/sys/kernel/mm/lru_gen"
SCHEDUTIL2_PATH="/sys/devices/system/cpu/cpufreq/schedutil"
SCHEDUTIL_PATH="/sys/devices/system/cpu/cpu0/cpufreq/schedutil"
ANDROID_VERSION=$(getprop ro.build.version.release)
TOTAL_RAM=$(free -m | awk '/Mem/{print $2}')

# Log starting information
log_info "Starting YAKT v301"
log_info "Build Date: 06/06/2024"
log_info "Author: @NotZeetaa (Github)"
log_info "Device: $(getprop ro.product.system.model)"
log_info "Brand: $(getprop ro.product.system.brand)"
log_info "Kernel: $(uname -r)"
log_info "ROM Build Type: $(getprop ro.system.build.type)"
log_info "Android Version: $ANDROID_VERSION"

# Sync to data in the rare case a device crashes
sync

# Schedutil rate-limits tweak
log_info "Applying schedutil rate-limits tweak"
if [ -d "$SCHEDUTIL2_PATH" ]; then
    write_value "$SCHEDUTIL2_PATH/up_rate_limit_us" 500
    write_value "$SCHEDUTIL2_PATH/down_rate_limit_us" 20000
    log_info "Applied schedutil rate-limits tweak"
elif [ -e "$SCHEDUTIL_PATH" ]; then
    for cpu in /sys/devices/system/cpu/*/cpufreq/schedutil; do
        write_value "${cpu}/up_rate_limit_us" 500
        write_value "${cpu}/down_rate_limit_us" 20000
    done
    log_info "Applied schedutil rate-limits tweak"
else
    log_info "Abort: Not using schedutil governor"
fi

# Cgroup tweak for UCLAMP scheduler
if [ -e "$UCLAMP_PATH" ]; then
    # Uclamp tweaks
    # Credits to @darkhz, adjusted for gaming boost
    log_info "UCLAMP scheduler detected, applying tweaks..."
    top_app="${CPUSET_PATH}/top-app"
    write_value "$top_app/uclamp.max" max
    write_value "$top_app/uclamp.min" 700
    write_value "$top_app/uclamp.boosted" 1
    write_value "$top_app/uclamp.latency_sensitive" 1
    foreground="${CPUSET_PATH}/foreground"
    write_value "$foreground/uclamp.max" 50
    write_value "$foreground/uclamp.min" 0
    write_value "$foreground/uclamp.boosted" 0
    write_value "$foreground/uclamp.latency_sensitive" 0
    background="${CPUSET_PATH}/background"
    write_value "$background/uclamp.max" max
    write_value "$background/uclamp.min" 20
    write_value "$background/uclamp.boosted" 0
    write_value "$background/uclamp.latency_sensitive" 0
    sys_bg="${CPUSET_PATH}/system-background"
    write_value "$sys_bg/uclamp.min" 0
    write_value "$sys_bg/uclamp.max" 40
    write_value "$sys_bg/uclamp.boosted" 0
    write_value "$sys_bg/uclamp.latency_sensitive" 0
    sysctl -w kernel.sched_util_clamp_min_rt_default=0
    sysctl -w kernel.sched_util_clamp_min=128
    log_info "Done."
fi

# Zswap tweaks
log_info "Checking if your kernel supports zswap..."
if [ -d "/sys/module/zswap" ]; then
    log_info "zswap supported, applying tweaks..."
    write_value "/sys/module/zswap/parameters/compressor" lz4
    log_info "Set zswap compressor to lz4 (fastest compressor)."
    write_value "/sys/module/zswap/parameters/zpool" zsmalloc
    log_info "Set zpool to zsmalloc."
#    write_value "/sys/module/zswap/parameters/enabled" 0
#    log_info "Disable zswap."
    log_info "Tweaks applied."
else
    log_info "Your kernel doesn't support zswap, aborting it..."
fi

#Ktweak starts
# Loop over each CPU in the system
for cpu in /sys/devices/system/cpu/cpu*/cpufreq
do
	# Fetch the available governors from the CPU
	avail_govs="$(cat "$cpu/scaling_available_governors")"

	# Attempt to set the governor in this order
	for governor in performance schedutil interactive
	do
		# Once a matching governor is found, set it and break for this CPU
		if [[ "$avail_govs" == *"$governor"* ]]
		then
			write_value "$cpu/scaling_governor" "$governor"
			break
		fi
	done
done

for queue in /sys/block/*/queue
do
	# Choose the first governor available
	avail_scheds="$(cat "$queue/scheduler")"
	for sched in kyber bfq none mq-deadline cfq noop
	do
		if [[ "$avail_scheds" == *"$sched"* ]]
		then
			write_value "$queue/scheduler" "$sched"
			break
		fi
	done

  # Kyber params: Low read latency for quick asset loads
	write_value "$queue/iosched/read_lat_nsec" 50000
	write_value "$queue/iosched/write_lat_nsec" 100000000

  # Alternative: BFQ (uncomment to use)
  # echo bfq > /sys/block/$DEV/queue/scheduler
  # echo 1 > /sys/block/$DEV/queue/iosched/low_latency
  # echo 0 > /sys/block/$DEV/queue/iosched/slice_idle
  # echo 0 > /sys/block/$DEV/queue/iosched/strict_guarantees
  # echo 125 > /sys/block/$DEV/queue/iosched/fifo_expire_sync

	# Do not use I/O as a source of randomness
	write_value "$queue/add_random" 0

	# Disable I/O statistics accounting
	write_value "$queue/iostats" 0

	# Reduce heuristic read-ahead in exchange for I/O latency
	write_value "$queue/read_ahead_kb" 128

	# Reduce the maximum number of I/O requests in exchange for latency
	write_value "$queue/nr_requests" 64
done

# My tweak
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
write_value "/proc/sys/net/ipv4/tcp_ecn" 1
write_value "/proc/sys/net/ipv4/tcp_fastopen" 3
write_value "/proc/sys/net/ipv4/tcp_syncookies" 0
write_value "/proc/sys/net/ipv4/tcp_low_latency" 1
write_value "/proc/sys/net/ipv4/tcp_timestamps" 0
write_value "/proc/sys/net/ipv4/tcp_slow_start_after_idle" 0
#
write_value "/proc/sys/net/ipv4/tcp_no_metrics_save" 1
write_value "/proc/sys/net/ipv4/tcp_tw_reuse" 1
write_value "/proc/sys/net/ipv4/tcp_window_scaling" 1
write_value "/proc/sys/net/ipv4/tcp_congestion_control" bbr
# Disable watchdog
write_value "/sys/module/workqueue/parameters/watchdog_thresh" 0


#IF
#if [ -e "/proc/sys/kernel/sched_schedstats" ]; then
#    write_value "/proc/sys/kernel/sched_schedstats" 0
#fi
#
#if [ -d "/sys/module/mmc_core" ]; then
#    log_info "Disabling SPI CRC"
#    write_value "/sys/module/mmc_core/parameters/use_spi_crc" 0
#    log_info "Done."
#fi
#
## Mglru tweaks
#log_info "Checking if your kernel has MGLRU support..."
#if [ -d "$MGLRU_PATH" ]; then
#    log_info "MGLRU support found."
#    log_info "Tweaking MGLRU settings..."
#    write_value "$MGLRU_PATH/min_ttl_ms" 3000
#    log_info "Done."
#else
#    log_info "MGLRU support not found."
#    log_info "Aborting MGLRU tweaks..."
#fi
#
#if [ -f "/sys/kernel/debug/sched_features" ]
#then
#	# Consider scheduling tasks that are eager to run
#	write_value "/sys/kernel/debug/sched_features" NEXT_BUDDY
#
#	# Schedule tasks on their origin CPU if possible
#	write_value "/sys/kernel/debug/sched_features" TTWU_QUEUE
#fi
#
#if [ -d "/dev/stune/" ]
#then
#	# We are concerned with prioritizing latency
#	write_value "/dev/stune/top-app/schedtune.prefer_idle" 0
#
#	# Mark top-app as boosted, find high-performing CPUs
#	write_value "/dev/stune/top-app/schedtune.boost" 1
#fi
#

# Sync to data in the rare case a device crashes
sync

# Always return success, even if the last write_value fails
exit 0
