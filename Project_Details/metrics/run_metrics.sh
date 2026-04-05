#!/bin/bash

echo "Starting metrics generation..."

# Run Agile Metrics and redirect output
echo "Running agile_metrics.py..."
python3 agile_metrics.py > agile_metrics_report.txt
echo "✅ Agile metrics saved to agile_metrics_report.txt"

# Run Code Metrics and redirect output
echo "Running code_metrics.py..."
python3 code_metrics.py > code_metrics_report.txt
echo "✅ Code metrics saved to code_metrics_report.txt"

echo "All metrics generated successfully!"