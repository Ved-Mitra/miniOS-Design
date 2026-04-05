import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

file_name = "Progress Tracker - (Group 2).xlsx"
sheet_name = "Sprint Plan"

try:
    df = pd.read_excel(file_name, sheet_name=sheet_name, skiprows=1)
except Exception as e:
    print(f"Error reading file: {e}")
    exit()

df.columns = df.columns.str.strip()
df.rename(columns={'Task / Deliverable': 'Task'}, inplace=True)

# Fill empty sprints
df['Sprint'] = df['Sprint'].replace(r'^\s*$', np.nan, regex=True).ffill()

# Filter valid tasks
tasks_df = df.dropna(subset=['Task'])
tasks_df = tasks_df[~tasks_df['Task'].astype(str).str.contains("DELIVERABLE|Foundation|Core Logic|Integration|Testing", na=False, case=False)]

# Parse Status
status_str = tasks_df['Status'].astype(str).str.strip().str.lower()
tasks_df['Status'] = status_str.isin(['true', '[x]', 'x', 'completed', 'done', 'yes'])

# Parse Completion Dates (Convert to proper datetime)
tasks_df['Date Of Completion'] = pd.to_datetime(tasks_df['Date Of Completion'], errors='coerce')

TOTAL_SCOPE = len(tasks_df)

# --- Generate Daily Timeline Data ---
if not tasks_df['Date Of Completion'].dropna().empty:
    min_date = tasks_df['Date Of Completion'].min()
    max_date = tasks_df['Date Of Completion'].max()
    
    # Create a daily date range
    date_range = pd.date_range(start=min_date, end=max_date, freq='D')
    timeline_df = pd.DataFrame({'Date': date_range})
    
    # Count how many tasks were completed on each specific day
    daily_completions = tasks_df.groupby('Date Of Completion').size().reset_index(name='Daily_Completed')
    
    # Merge and calculate cumulative progression
    timeline_df = pd.merge(timeline_df, daily_completions, left_on='Date', right_on='Date Of Completion', how='left')
    timeline_df['Daily_Completed'] = timeline_df['Daily_Completed'].fillna(0)
    timeline_df['Cumulative_Completed'] = timeline_df['Daily_Completed'].cumsum()
    timeline_df['Remaining_Tasks'] = TOTAL_SCOPE - timeline_df['Cumulative_Completed']
    
    # Ideal Burndown (Linear drop from total scope to 0 over the timeframe)
    timeline_df['Ideal_Burndown'] = np.linspace(TOTAL_SCOPE, 0, len(timeline_df))
else:
    print("Warning: No valid completion dates found. Cannot generate timeline charts.")
    exit()

print("--- Agile Metrics Summary (Timeline Based) ---")
print(f"Total Scope: {TOTAL_SCOPE} Tasks")
print(f"Currently Completed: {int(timeline_df['Cumulative_Completed'].iloc[-1])} Tasks")
print(f"Schedule Variance (Completed vs Ideal Today): {int(timeline_df['Cumulative_Completed'].iloc[-1] - (TOTAL_SCOPE - timeline_df['Ideal_Burndown'].iloc[-1]))} tasks\n")

# --- Plotting ---

# 1. Daily Burndown Chart
plt.figure(figsize=(8, 6))
plt.plot(timeline_df['Date'], timeline_df['Remaining_Tasks'], marker='o', color='red', label='Actual Remaining')
plt.plot(timeline_df['Date'], timeline_df['Ideal_Burndown'], linestyle='--', color='gray', label='Ideal Burndown')
plt.title('Daily Sprint Burndown Chart')
plt.xlabel('Date'); plt.ylabel('Tasks Remaining'); plt.legend()
plt.ylim(bottom=0)
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig("agile_burndown_chart.png")
plt.close()

# 2. Daily Burnup Chart
plt.figure(figsize=(8, 6))
plt.plot(timeline_df['Date'], timeline_df['Cumulative_Completed'], marker='o', color='green', label='Completed Tasks')
plt.axhline(y=TOTAL_SCOPE, color='blue', linestyle='--', label='Total Scope')
plt.title('Daily Sprint Burnup Chart')
plt.xlabel('Date'); plt.ylabel('Tasks'); plt.legend()
plt.ylim(bottom=0)
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig("agile_burnup_chart.png")
plt.close()

# 3. Cumulative Flow Diagram
plt.figure(figsize=(8, 6))
plt.fill_between(timeline_df['Date'], TOTAL_SCOPE, color='lightblue', label='To Do')
plt.fill_between(timeline_df['Date'], timeline_df['Cumulative_Completed'], color='lightgreen', label='Done')
plt.title('Cumulative Flow Diagram (CFD)')
plt.xlabel('Date'); plt.ylabel('Cumulative Tasks'); plt.legend()
plt.ylim(bottom=0)
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig("agile_cfd.png")
plt.close()

# 4. Throughput Report (Tasks completed per Day)
plt.figure(figsize=(8, 6))
plt.bar(timeline_df['Date'], timeline_df['Daily_Completed'], color='purple')
plt.title('Throughput Report (Daily Velocity)')
plt.xlabel('Date'); plt.ylabel('Tasks Completed')
plt.ylim(bottom=0)
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig("agile_throughput.png")
plt.close()
print("Charts saved successfully as individual PNG files.")