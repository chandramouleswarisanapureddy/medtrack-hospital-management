"""
=============================================================================
MEDTRACK: DATA ENGINEERING MODULE
FILE: data_engineering/generate_reports.py
PURPOSE: Generate daily, monthly & branch performance reports from ETL marts
=============================================================================
"""

import os
import json
import pandas as pd
from datetime import datetime
from pipeline import MedTrackETLPipeline

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "output")

def generate_reports():
    print("=" * 70)
    print("MEDTRACK DATA ENGINEERING: HOSPITAL REPORT GENERATOR")
    print("=" * 70)

    # Run ETL pipeline first to guarantee fresh analytical data marts
    pipeline = MedTrackETLPipeline()
    data = pipeline.run()

    df_branch = data['dim_branch_performance']
    df_inv = data['fact_inventory']
    df_appt = data['fact_appointments']

    # 1. Hospital Wide Consolidated KPI Summary
    total_appointments = int(df_appt['id'].count())
    completed_appointments = int((df_appt['status'] == 'Completed').sum())
    total_revenue = float(df_branch['consultation_revenue'].sum())
    low_stock_items = df_inv[df_inv['is_low_stock'] == True]

    executive_summary = {
        'generated_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'total_branches_reporting': 3,
        'hospital_kpis': {
            'total_appointments': total_appointments,
            'completed_appointments': completed_appointments,
            'emergency_cancellations': int((df_appt['status'] == 'Cancelled - Emergency').sum()),
            'no_shows': int((df_appt['status'] == 'No-show').sum()),
            'completion_rate_pct': round((completed_appointments / total_appointments) * 100, 2) if total_appointments > 0 else 0,
            'total_consultation_revenue_inr': total_revenue
        },
        'branch_breakdown': df_branch.to_dict(orient='records'),
        'critical_stock_alerts': low_stock_items[['branch_code', 'medicine', 'stock', 'reorder']].to_dict(orient='records')
    }

    # Save JSON Report
    json_path = os.path.join(OUTPUT_DIR, "executive_report.json")
    with open(json_path, "w") as f:
        json.dump(executive_summary, f, indent=4)
    print(f"[+] Saved Executive Report (JSON) to {json_path}")

    # Save Markdown Human-Readable Summary
    md_content = f"""# MedTrack Multi-Branch Hospital Operations Report
**Generated on:** {executive_summary['generated_at']}

## 1. Executive Summary
- **Active Hospital Branches:** 3 (Branch A - Metro Central, Branch B - Tech City, Branch C - Green Valley)
- **Total Scheduled Appointments:** {total_appointments}
- **Successfully Completed:** {completed_appointments} ({executive_summary['hospital_kpis']['completion_rate_pct']}%)
- **Emergency Cancellations & Auto-Reschedules:** {executive_summary['hospital_kpis']['emergency_cancellations']}
- **No-Show Patient Rate:** {executive_summary['hospital_kpis']['no_shows']}
- **Total Consultation Revenue:** ₹{total_revenue:,.2f}

## 2. Branch Performance Breakdown
| Branch Code | Total Appts | Completed | Emergencies | No-Shows | Revenue (₹) |
|---|---|---|---|---|---|
"""
    for b in executive_summary['branch_breakdown']:
        md_content += f"| {b['branch_code']} | {b['total_appointments']} | {b['completed_appointments']} | {b['cancelled_emergencies']} | {b['no_shows']} | ₹{b['consultation_revenue']:,.2f} |\n"

    md_content += """
## 3. Pharmacy Stock Replenishment Alerts
| Branch | Medicine Name | In Stock | Reorder Level | Status |
|---|---|---|---|---|
"""
    for alert in executive_summary['critical_stock_alerts']:
        md_content += f"| {alert['branch_code']} | {alert['medicine']} | {alert['stock']} | {alert['reorder']} | ⚠️ LOW STOCK |\n"

    md_path = os.path.join(OUTPUT_DIR, "executive_report.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md_content)
    print(f"[+] Saved Human-Readable Report (Markdown) to {md_path}")
    print("=" * 70 + "\n")

if __name__ == "__main__":
    generate_reports()
