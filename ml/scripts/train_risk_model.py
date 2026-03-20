"""
Train the XGBoost Risk Classifier — Phase 3 (Weeks 5-6).

This script trains the ML model that predicts patient risk level
from daily check-in data. Run in Google Colab (free GPU).

Input features:
- pain_level (0-10)
- symptom_count (number of symptoms reported)
- has_fever (0/1)
- has_bleeding (0/1)
- has_chest_pain (0/1)
- days_since_surgery
- mood_score (1-4)
- age
- surgery_complexity (1-3)

Output: risk_level (LOW=0, MEDIUM=1, HIGH=2, EMERGENCY=3)

After training, the model is saved as risk_classifier.pkl
and deployed to Hugging Face Spaces.
"""

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
from xgboost import XGBClassifier
import joblib


def train():
    # Load synthetic training data
    df = pd.read_csv("../data/synthetic/checkin_data.csv")

    # Feature columns
    features = [
        "pain_level",
        "symptom_count",
        "has_fever",
        "has_bleeding",
        "has_chest_pain",
        "days_since_surgery",
        "mood_score",
        "age",
        "surgery_complexity",
    ]

    X = df[features]
    y = df["risk_level"]  # 0=LOW, 1=MEDIUM, 2=HIGH, 3=EMERGENCY

    # Split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # Train XGBoost
    model = XGBClassifier(
        n_estimators=100,
        max_depth=6,
        learning_rate=0.1,
        use_label_encoder=False,
        eval_metric="mlogloss",
    )
    model.fit(X_train, y_train)

    # Evaluate
    y_pred = model.predict(X_test)
    print(classification_report(y_test, y_pred))

    # Save model
    joblib.dump(model, "../models/risk_classifier.pkl")
    print("Model saved to models/risk_classifier.pkl")


if __name__ == "__main__":
    train()
