# MedTrack Machine Learning Module

## Objective
Predict the likelihood that a patient will not attend their scheduled appointment (No-Show Prediction) using patient demographics, medical history flags, lead time between booking and appointment, and reminder status.

## Academic Context
- **Dataset:** Kaggle Medical Appointment No Shows (`https://www.kaggle.com/datasets/joniarroba/noshowappointments`)
- **Records:** 110,527 clinical appointments with 14 variables.
- **Academic Discipline:** B.Tech Computer Science (Data Science)

## Features Utilized
1. `Age`: Patient age in years.
2. `Gender`: Encoded binary (0 = Female, 1 = Male).
3. `Scholarship`: Social welfare coverage under Bolsa Família (0 or 1).
4. `Hipertension`: Pre-existing hypertension diagnosed (0 or 1).
5. `Diabetes`: Pre-existing diabetes diagnosed (0 or 1).
6. `Alcoholism`: History of alcoholism (0 or 1).
7. `Handcap`: Physical disability status (0 or 1).
8. `SMS_received`: Whether SMS notification was dispatched (0 or 1).
9. `LeadDays`: Days between scheduling timestamp and appointment date.
10. `DayOfWeek`: Day of the week for the appointment (0=Monday, 6=Sunday).

## Ethical & Operational Guidelines
- **No Care Denial:** Predictions are solely for administrative reminder prioritization. Never deny medical care based on risk scoring.
- **Data Provenance:** Kaggle training data is historical benchmark data and clearly distinguished from live operational MedTrack hospital records.

## Quickstart

### 1. Install Requirements
```bash
pip install -r ml/requirements.txt
```

### 2. Train the Model
```bash
python ml/train_model.py
```
This script will:
- Check for `ml/data/KaggleV2-May-2016.csv`. If absent, generate a conforming 12,000-sample benchmark dataset.
- Clean and preprocess features avoiding data leakage.
- Train both **Logistic Regression** and **Random Forest Classifier**.
- Evaluate Accuracy, Precision, Recall, F1, and ROC-AUC.
- Save the serialized pipeline to `ml/models/noshow_model.joblib`.

### 3. Run Predictions
```bash
python ml/predict.py --age 52 --lead_days 14 --sms 1 --hypertension 1
```
Output:
```text
==================================================
MEDTRACK AI APPOINTMENT NO-SHOW RISK REPORT
==================================================
Patient Age           : 52
Booking Lead Time     : 14 days
SMS Reminder Active   : Yes
Model Applied         : RandomForest
--------------------------------------------------
No-Show Probability   : 21.40%
Risk Category         : Low
Clinical Guidance     : Low risk: Standard in-app appointment reminder.
==================================================
```
