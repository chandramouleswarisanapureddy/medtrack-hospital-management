"""
=============================================================================
MEDTRACK: MACHINE LEARNING MODULE
FILE: ml/predict.py
PURPOSE: Inference engine for patient appointment no-show risk prediction
=============================================================================
Usage:
    python predict.py --age 45 --lead_days 14 --sms 1 --hypertension 1
"""

import os
import argparse
import joblib
import pandas as pd
import numpy as np

MODEL_PATH = os.path.join(os.path.dirname(__file__), "models", "noshow_model.joblib")

def load_predictor():
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(
            f"Trained model not found at {MODEL_PATH}. Run 'python ml/train_model.py' first."
        )
    return joblib.load(MODEL_PATH)

def predict_noshow_risk(
    age=35,
    gender=0,            # 0=Female, 1=Male
    scholarship=0,       # 0 or 1 (Bolsa Família social welfare)
    hipertension=0,      # 0 or 1
    diabetes=0,          # 0 or 1
    alcoholism=0,        # 0 or 1
    handcap=0,           # 0 or 1
    sms_received=1,      # 0 or 1
    lead_days=7,         # Days between scheduled date and appointment date
    day_of_week=1        # 0=Monday, 6=Sunday
):
    """
    Evaluates patient appointment features and returns risk estimation.
    """
    bundle = load_predictor()
    model = bundle['model']
    scaler = bundle.get('scaler')
    features = bundle['feature_names']

    input_df = pd.DataFrame([{
        'Age': age,
        'Gender': gender,
        'Scholarship': scholarship,
        'Hipertension': hipertension,
        'Diabetes': diabetes,
        'Alcoholism': alcoholism,
        'Handcap': handcap,
        'SMS_received': sms_received,
        'LeadDays': lead_days,
        'DayOfWeek': day_of_week
    }])[features]

    if bundle.get('uses_scaler') and scaler is not None:
        X_eval = scaler.transform(input_df)
    else:
        X_eval = input_df

    prob = float(model.predict_proba(X_eval)[0, 1])
    pred = int(model.predict(X_eval)[0])

    if prob >= 0.55:
        risk_level = "High"
        recommendation = "High risk of no-show: Send automated phone call reminder & confirm attendance 24h prior."
    elif prob >= 0.30:
        risk_level = "Medium"
        recommendation = "Moderate risk: Send 2-way SMS confirmation reminder."
    else:
        risk_level = "Low"
        recommendation = "Low risk: Standard in-app appointment reminder."

    return {
        'no_show_probability': round(prob, 4),
        'predicted_class': pred,
        'risk_level': risk_level,
        'recommendation': recommendation,
        'model_used': bundle.get('model_name')
    }

def main():
    parser = argparse.ArgumentParser(description="MedTrack AI No-Show Predictor")
    parser.add_argument("--age", type=int, default=45, help="Patient age")
    parser.add_argument("--gender", type=str, default="F", choices=["M", "F"], help="Patient gender")
    parser.add_argument("--scholarship", type=int, default=0, help="Scholarship welfare (0 or 1)")
    parser.add_argument("--hypertension", type=int, default=0, help="Hypertension (0 or 1)")
    parser.add_argument("--diabetes", type=int, default=0, help="Diabetes (0 or 1)")
    parser.add_argument("--alcoholism", type=int, default=0, help="Alcoholism (0 or 1)")
    parser.add_argument("--handicap", type=int, default=0, help="Handicap status (0 or 1)")
    parser.add_argument("--sms", type=int, default=1, help="SMS notification sent (0 or 1)")
    parser.add_argument("--lead_days", type=int, default=12, help="Days in advance appointment was booked")
    parser.add_argument("--day_of_week", type=int, default=2, help="Day of week (0=Mon, 6=Sun)")

    args = parser.parse_args()
    gender_code = 1 if args.gender == "M" else 0

    result = predict_noshow_risk(
        age=args.age,
        gender=gender_code,
        scholarship=args.scholarship,
        hipertension=args.hypertension,
        diabetes=args.diabetes,
        alcoholism=args.alcoholism,
        handcap=args.handicap,
        sms_received=args.sms,
        lead_days=args.lead_days,
        day_of_week=args.day_of_week
    )

    print("\n" + "=" * 50)
    print("MEDTRACK AI APPOINTMENT NO-SHOW RISK REPORT")
    print("=" * 50)
    print(f"Patient Age           : {args.age}")
    print(f"Booking Lead Time     : {args.lead_days} days")
    print(f"SMS Reminder Active   : {'Yes' if args.sms else 'No'}")
    print(f"Model Applied         : {result['model_used']}")
    print("-" * 50)
    print(f"No-Show Probability   : {result['no_show_probability'] * 100:.2f}%")
    print(f"Risk Category         : {result['risk_level']}")
    print(f"Clinical Guidance     : {result['recommendation']}")
    print("=" * 50 + "\n")

if __name__ == "__main__":
    main()
