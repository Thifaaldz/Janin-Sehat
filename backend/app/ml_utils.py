import numpy as np
import pandas as pd
import os
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, "../data/prediksiml.xlsx")

try:
    ref_df = pd.read_excel(DATA_PATH)
except Exception as e:
    print("[WARNING] Tidak bisa load prediksiml.xlsx:", e)
    ref_df = pd.DataFrame()

def get_week_row(df_ref, week):
    if 'week' not in df_ref.columns:
        return None
    row = df_ref[df_ref['week'] == week]
    if row.empty:
        return None
    return row.iloc[0]

def build_normative_samples(df_ref):
    samples = []
    for _, row in df_ref.iterrows():
        try:
            w = float(row['week'])
            weight = (row['weight_min'] + row['weight_max'])/2 if {'weight_min','weight_max'}.issubset(row.index) else float(row.get('weight',0))
            height = (row['height_min'] + row['height_max'])/2 if {'height_min','height_max'}.issubset(row.index) else float(row.get('height',0))
            hr = (row['heart_rate_min'] + row['heart_rate_max'])/2 if {'heart_rate_min','heart_rate_max'}.issubset(row.index) else float(row.get('heart_rate',0))
            samples.append([w, weight, height, hr])
        except:
            continue
    samples = np.array(samples, dtype=float)
    if samples.ndim == 1:
        samples = samples.reshape(-1,1)
    samples = samples[~np.isnan(samples).any(axis=1)]
    return samples

norm_samples = build_normative_samples(ref_df)

def anomaly_detection(week, weight, height, hr):
    iso_score, iso_pred = None, None
    if norm_samples.shape[0] >= 5:
        scaler = StandardScaler()
        X_norm = scaler.fit_transform(norm_samples)
        X_user = scaler.transform(np.array([[week, weight, height, hr]]))
        iso = IsolationForest(n_estimators=100, contamination=0.05, random_state=42)
        iso.fit(X_norm)
        iso_pred = int(iso.predict(X_user)[0])  # 1=normal, -1=anomali
        iso_score = float(-iso.decision_function(X_user)[0])
    return iso_pred, iso_score
