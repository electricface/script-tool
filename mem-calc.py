'''
MemTotal = MemFree +【Slab + VmallocUsed + PageTables + KernelStack + HardwareCorrupted + Bounce + X】+【Active + Inactive + Unevictable + (HugePages_Total * Hugepagesize)】
'''

content = """
MemTotal:        7998520 kB
MemFree:          148548 kB
MemAvailable:     382856 kB
Buffers:           53444 kB
Cached:           458908 kB
SwapCached:       957664 kB
Active:          1475936 kB
Inactive:         281004 kB
Active(anon):    1059224 kB
Inactive(anon):   278488 kB
Active(file):     416712 kB
Inactive(file):     2516 kB
Unevictable:       27764 kB
Mlocked:              96 kB
SwapTotal:       8281084 kB
SwapFree:        6683988 kB
Dirty:               396 kB
Writeback:             0 kB
AnonPages:        369084 kB
Mapped:           268228 kB
Shmem:             97240 kB
KReclaimable:      76752 kB
Slab:             156416 kB
SReclaimable:      76752 kB
SUnreclaim:        79664 kB
KernelStack:       14608 kB
PageTables:        23508 kB
NFS_Unstable:          0 kB
Bounce:                0 kB
WritebackTmp:          0 kB
CommitLimit:    12280344 kB
Committed_AS:    7591100 kB
VmallocTotal:   34359738367 kB
VmallocUsed:       41396 kB
VmallocChunk:          0 kB
Percpu:             7936 kB
HardwareCorrupted:     0 kB
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
ShmemPmdMapped:        0 kB
FileHugePages:         0 kB
FilePmdMapped:         0 kB
CmaTotal:              0 kB
CmaFree:               0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:               0 kB
DirectMap4k:      329740 kB
DirectMap2M:     6864896 kB
DirectMap1G:     2097152 kB
"""

dict = {}
lines = content.split('\n')
for line in lines:
	parts = line.split(':')
	if len(parts) == 2:
		key = parts[0].strip()
		value = parts[1].strip().removesuffix('kB').strip()
		print("key", key, "value:", value)
		dict[key] = value

MemTotal = int(dict["MemTotal"])
MemFree = int(dict["MemFree"])
Slab = int(dict['Slab'])
VmallocUsed = int(dict['VmallocUsed'])
PageTables = int(dict['PageTables'])
KernelStack = int(dict['KernelStack'])
HardwareCorrupted = int(dict['HardwareCorrupted'])
Bounce = int(dict['Bounce'])
X = 0
Active = int(dict['Active'])
Inactive = int(dict['Inactive'])
Unevictable = int(dict['Unevictable'])
HugePages_Total = int(dict['HugePages_Total'])
Hugepagesize = int(dict['Hugepagesize'])

tempSum = MemFree + (Slab + VmallocUsed + PageTables + KernelStack + HardwareCorrupted +
                 Bounce)+(Active + Inactive + Unevictable + (HugePages_Total * Hugepagesize))
X = MemTotal - tempSum
print("X:", X / 1024.0 / 1024.0, "GiB")