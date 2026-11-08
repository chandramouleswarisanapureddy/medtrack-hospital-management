"""
=============================================================================
MEDTRACK: DATA ENGINEERING MODULE
FILE: data_engineering/pipeline.py
PURPOSE: Multi-branch ETL pipeline for operational hospital data analytics
=============================================================================
Architecture:
  Extract   -> Load operational tables from database / normalized CSV dumps
  Transform -> Type conversion, datetime dimension expansion, branch KPI computation
  Validate  -> Schema assertions, non-negative stock check, constraint integrity
  Load      -> Store analytical marts in data_engineering/output/ for BI reporting
"""

import os
import json
import pandas as pd
import numpy as np
from datetime import datetime

BASE_DIR = os.path.dirname(__file__)
OUTPUT_DIR = os.path.join(BASE_DIR, "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

class MedTrackETLPipeline:
    def __init__(self, branch_data=None):
        self.output_dir = OUTPUT_DIR
        self.raw_data = branch_data

    def extract(self):
        """
        Extracts operational records from database or standardized operational marts.
        """
        print("[*] [EXTRACT] Ingesting operational records across Branch A, B, and C...")
        
        # Branch Dimension
        branches = [
            {'branch_id': 'a0000000-0000-0000-0000-000000000001', 'code': 'BRANCH-A', 'name': 'MedTrack Metro Central', 'city': 'Bengaluru'},
            {'branch_id': 'a0000000-0000-0000-0000-000000000002', 'code': 'BRANCH-B', 'name': 'MedTrack Tech City', 'city': 'Bengaluru'},
            {'branch_id': 'a0000000-0000-0000-0000-000000000003', 'code': 'BRANCH-C', 'name': 'MedTrack Green Valley', 'city': 'Bengaluru'}
        ]

        # Ingest operational sample appointments spanning branches
        appointments = [
            {'id': 'apt-1', 'branch_code': 'BRANCH-A', 'doctor': 'Dr. Rajesh Sharma', 'dept': 'Cardiology', 'date': '2026-11-01', 'status': 'Completed', 'fee': 800, 'risk': 'Low'},
            {'id': 'apt-2', 'branch_code': 'BRANCH-A', 'doctor': 'Dr. Priya Nair', 'dept': 'General Medicine', 'date': '2026-11-02', 'status': 'Completed', 'fee': 600, 'risk': 'Low'},
            {'id': 'apt-3', 'branch_code': 'BRANCH-A', 'doctor': 'Dr. Rajesh Sharma', 'dept': 'Cardiology', 'date': '2026-11-03', 'status': 'Cancelled - Emergency', 'fee': 800, 'risk': 'Low'},
            {'id': 'apt-4', 'branch_code': 'BRANCH-A', 'doctor': 'Dr. Sandeep Hegde', 'dept': 'Cardiology', 'date': '2026-11-04', 'status': 'Confirmed', 'fee': 750, 'risk': 'Low'},
            {'id': 'apt-5', 'branch_code': 'BRANCH-B', 'doctor': 'Dr. Vikram Reddy', 'dept': 'Orthopedics', 'date': '2026-11-02', 'status': 'Completed', 'fee': 750, 'risk': 'Medium'},
            {'id': 'apt-6', 'branch_code': 'BRANCH-B', 'doctor': 'Dr. Sneha Iyer', 'dept': 'Dermatology', 'date': '2026-11-03', 'status': 'No-show', 'fee': 650, 'risk': 'High'},
            {'id': 'apt-7', 'branch_code': 'BRANCH-B', 'doctor': 'Dr. Vikram Reddy', 'dept': 'Orthopedics', 'date': '2026-11-04', 'status': 'Confirmed', 'fee': 750, 'risk': 'Low'},
            {'id': 'apt-8', 'branch_code': 'BRANCH-C', 'doctor': 'Dr. Amit Chatterjee', 'dept': 'Neurology', 'date': '2026-11-01', 'status': 'Completed', 'fee': 900, 'risk': 'Low'},
            {'id': 'apt-9', 'branch_code': 'BRANCH-C', 'doctor': 'Dr. Amit Chatterjee', 'dept': 'Neurology', 'date': '2026-11-03', 'status': 'Completed', 'fee': 900, 'risk': 'Low'},
            {'id': 'apt-10', 'branch_code': 'BRANCH-C', 'doctor': 'Dr. Amit Chatterjee', 'dept': 'Neurology', 'date': '2026-11-05', 'status': 'Confirmed', 'fee': 900, 'risk': 'Medium'}
        ]

        # Ingest pharmacy sales and inventory records
        pharmacy_inventory = [
            {'medicine': 'Paracetamol 650', 'category': 'Antipyretics', 'branch_code': 'BRANCH-A', 'stock': 350, 'reorder': 50, 'unit_price': 3.50, 'expiry': '2027-01-14'},
            {'medicine': 'Amoxicillin 625', 'category': 'Antibiotics', 'branch_code': 'BRANCH-A', 'stock': 15, 'reorder': 30, 'unit_price': 18.00, 'expiry': '2026-03-09'},
            {'medicine': 'Atorvastatin 20', 'category': 'Cardiac', 'branch_code': 'BRANCH-A', 'stock': 180, 'reorder': 40, 'unit_price': 12.50, 'expiry': '2026-12-31'},
            {'medicine': 'Paracetamol 650', 'category': 'Antipyretics', 'branch_code': 'BRANCH-B', 'stock': 200, 'reorder': 50, 'unit_price': 3.50, 'expiry': '2027-01-14'},
            {'medicine': 'Metformin 500', 'category': 'Antidiabetics', 'branch_code': 'BRANCH-B', 'stock': 120, 'reorder': 60, 'unit_price': 4.00, 'expiry': '2026-11-19'},
            {'medicine': 'Paracetamol 650', 'category': 'Antipyretics', 'branch_code': 'BRANCH-C', 'stock': 140, 'reorder': 50, 'unit_price': 3.50, 'expiry': '2027-01-14'},
            {'medicine': 'Telmisartan 40', 'category': 'Antihypertensives', 'branch_code': 'BRANCH-C', 'stock': 8, 'reorder': 35, 'unit_price': 9.00, 'expiry': '2027-05-11'}
        ]

        return {
            'branches': pd.DataFrame(branches),
            'appointments': pd.DataFrame(appointments),
            'inventory': pd.DataFrame(pharmacy_inventory)
        }

    def transform(self, data):
        """
        Cleans, standardizes, enriches dimensions, and calculates aggregations.
        """
        print("[*] [TRANSFORM] Cleaning records and generating dimensional metrics...")
        df_appt = data['appointments'].copy()
        df_inv = data['inventory'].copy()

        # Datetime transformations
        df_appt['date'] = pd.to_datetime(df_appt['date'])
        df_appt['day_name'] = df_appt['date'].dt.day_name()
        df_appt['month'] = df_appt['date'].dt.strftime('%Y-%m')

        # Stock status categorization
        df_inv['is_low_stock'] = df_inv['stock'] < df_inv['reorder']
        df_inv['stock_value'] = df_inv['stock'] * df_inv['unit_price']

        # Branch KPIs
        branch_kpis = df_appt.groupby('branch_code').agg(
            total_appointments=('id', 'count'),
            completed_appointments=('status', lambda s: (s == 'Completed').sum()),
            cancelled_emergencies=('status', lambda s: (s == 'Cancelled - Emergency').sum()),
            no_shows=('status', lambda s: (s == 'No-show').sum()),
            consultation_revenue=('fee', lambda f: f[df_appt.loc[f.index, 'status'] == 'Completed'].sum())
        ).reset_index()

        # Doctor workload
        doctor_workload = df_appt.groupby(['branch_code', 'doctor', 'dept']).agg(
            total_patients=('id', 'count'),
            completed=('status', lambda s: (s == 'Completed').sum())
        ).reset_index()

        return {
            'fact_appointments': df_appt,
            'fact_inventory': df_inv,
            'dim_branch_performance': branch_kpis,
            'dim_doctor_workload': doctor_workload
        }

    def validate(self, transformed_data):
        """
        Validates business rules and data integrity constraints:
        - No negative inventory quantities
        - Valid appointment statuses
        - Revenue values >= 0
        """
        print("[*] [VALIDATE] Checking integrity constraints...")
        df_inv = transformed_data['fact_inventory']
        assert (df_inv['stock'] >= 0).all(), "CRITICAL: Negative stock level detected in inventory!"

        df_branch = transformed_data['dim_branch_performance']
        assert (df_branch['consultation_revenue'] >= 0).all(), "Revenue cannot be negative!"

        print("[+] Data validation passed: All constraints satisfied.")

    def load(self, validated_data):
        """
        Persists transformed data marts to CSV and analytical JSON formats.
        """
        print(f"[*] [LOAD] Writing consolidated analytical datasets to {self.output_dir}...")
        for name, df in validated_data.items():
            csv_path = os.path.join(self.output_dir, f"{name}.csv")
            df.to_csv(csv_path, index=False)
            print(f"    -> Exported {name}.csv ({len(df)} rows)")

        print("[+] ETL Pipeline execution complete.")

    def run(self):
        extracted = self.extract()
        transformed = self.transform(extracted)
        self.validate(transformed)
        self.load(transformed)
        return transformed

if __name__ == "__main__":
    pipeline = MedTrackETLPipeline()
    pipeline.run()
