import matplotlib.pyplot as plt
import re
import sys
import os

# Set a non-interactive backend for server environments
import matplotlib
matplotlib.use('Agg')

def parse_trace(filename):
    data = []
    # Pattern to match SCHED_STATS: pid=%d priority=%d cpu=%ld wait=%ld turnaround=%ld
    pattern = re.compile(r'SCHED_STATS: pid=(\d+) priority=(\d+) cpu=(\d+) wait=(\d+) turnaround=(\d+)')
    
    if not os.path.exists(filename):
        print(f"Error: {filename} not found.")
        return []

    with open(filename, 'r') as f:
        for line in f:
            match = pattern.search(line)
            if match:
                data.append({
                    'pid': int(match.group(1)),
                    'priority': int(match.group(2)),
                    'cpu': int(match.group(3)),
                    'wait': int(match.group(4)),
                    'turnaround': int(match.group(5))
                })
    return data

def generate_plots(data):
    if not data:
        print("No data extracted from trace.")
        return

    # Sort data by PID for better plotting
    data.sort(key=lambda x: x['pid'])
    
    pids = [d['pid'] for d in data]
    cpu_ticks = [d['cpu'] for d in data]
    wait_ticks = [d['wait'] for d in data]
    turnarounds = [d['turnaround'] for d in data]
    priorities = [d['priority'] for d in data]

    # Plot 1: PID vs Turnaround Time (Performance)
    plt.figure(figsize=(10, 6))
    plt.bar(pids, turnarounds, color='skyblue', label='Turnaround (Total Time)')
    plt.bar(pids, cpu_ticks, color='darkblue', alpha=0.7, label='CPU Time')
    plt.xlabel('PID')
    plt.ylabel('Ticks')
    plt.title('Execution and Turnaround Time per Process')
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.6)
    plt.xticks(pids)
    plt.savefig('performance_plot.png')
    print("Performance plot saved to 'performance_plot.png'")

    # Plot 2: CPU Ticks and Wait Ticks (Fairness)
    plt.figure(figsize=(10, 6))
    x_indices = list(range(len(pids)))
    width = 0.35
    plt.bar([x - width/2 for x in x_indices], cpu_ticks, width, label='CPU Ticks', color='green', alpha=0.8)
    plt.bar([x + width/2 for x in x_indices], wait_ticks, width, label='Wait Ticks', color='orange', alpha=0.8)
    plt.xlabel('PID')
    plt.ylabel('Ticks')
    plt.title('Scheduler Fairness Analysis (CPU vs Wait Ticks)')
    plt.xticks(x_indices, pids)
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.6)
    plt.savefig('fairness_plot.png')
    print("Fairness plot saved to 'fairness_plot.png'")

if __name__ == '__main__':
    trace_file = sys.argv[1] if len(sys.argv) > 1 else 'trace.log'
    print(f"Parsing {trace_file}...")
    stats = parse_trace(trace_file)
    generate_plots(stats)
