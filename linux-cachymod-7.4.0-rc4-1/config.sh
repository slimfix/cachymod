scripts/config --set-val NR_CPUS_RANGE_BEGIN 2 --set-val NR_CPUS_RANGE_END 512 --set-val NR_CPUS_DEFAULT 64
scripts/config -e CPU_FREQ_GOV_REFLEX
scripts/config -e LRU_CAST
scripts/config -e ZRAM_BACKEND_LZ4KDR
