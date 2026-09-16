#!/usr/bin/env python3
"""Reproduce the full-grid physical map-comparison metrics reported in the paper."""
from pathlib import Path
import math
import numpy as np
import pandas as pd

RHO = 100.0
L = 2.40
PHI_DEG = 0.0
HP = 0.03
RREF = {0.20: 44.1, 0.30: 41.6, 0.40: 40.1}


def z_ideal(x, y, d):
    ph = math.radians(PHI_DEG)
    s = x*np.cos(ph) + y*np.sin(ph)
    b = np.sqrt(np.maximum(x*x + y*y + (d-HP)**2 - s*s, 1e-15))
    return RHO/(2*np.pi*L) * (np.arcsinh((L-s)/b) + np.arcsinh(s/b))


def metrics(depth, csv_path):
    q = pd.read_csv(csv_path)
    x = q['x_m'].to_numpy(float)
    y = q['y_m'].to_numpy(float)
    r_meas = q['R_MTR_ohm'].to_numpy(float)
    zref = z_ideal(x, y, depth)
    r_ideal = RREF[depth] - zref
    residual = r_meas - r_ideal
    mape = np.mean(np.abs(residual / r_ideal))*100.0
    mae = np.mean(np.abs(residual))
    rmse = np.sqrt(np.mean(residual**2))
    bias = np.mean(residual)
    corr = np.corrcoef(r_meas, r_ideal)[0,1]
    sse = np.sum((r_meas-r_ideal)**2)
    sst_ref = np.sum((r_ideal-np.mean(r_ideal))**2)
    r2 = 1.0 - sse/sst_ref
    return dict(depth_m=depth, n=len(q), MAPE_pct=mape, MAE_ohm=mae,
                RMSE_ohm=rmse, mean_bias_ohm=bias,
                pearson_correlation=corr, R2=r2)


def main():
    root = Path(__file__).resolve().parent
    data = root/'locked_replay'
    rows=[]
    for d in (0.20,0.30,0.40):
        rows.append(metrics(d, data/f'physical_D{int(d*100):03d}.csv'))
    out = pd.DataFrame(rows)
    out.to_csv(root/'physical_map_metrics_reproduced.csv', index=False)
    print(out.to_string(index=False))

if __name__ == '__main__':
    main()
