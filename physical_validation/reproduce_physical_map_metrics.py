#!/usr/bin/env python3
"""Reproduce the full-grid physical map-comparison metrics reported in the paper.

The script reads the source MTR-1522 workbook already stored at repository root,
so the public GitHub branch does not need duplicate copies of the 289-point CSVs.
"""
from pathlib import Path
import math
import numpy as np
import pandas as pd

RHO = 100.0
L = 2.40
PHI_DEG = 0.0
HP = 0.03
RREF = {0.20: 44.1, 0.30: 41.6, 0.40: 40.1}
RAW_SHEET = {0.20: "Dados_Brutos", 0.30: "Dados_Brutos_D030", 0.40: "Dados_Brutos_D040"}


def z_ideal(x, y, d):
    ph = math.radians(PHI_DEG)
    s = x*np.cos(ph) + y*np.sin(ph)
    b = np.sqrt(np.maximum(x*x + y*y + (d-HP)**2 - s*s, 1e-15))
    return RHO/(2*np.pi*L) * (np.arcsinh((L-s)/b) + np.arcsinh(s/b))


def read_campaign(workbook, depth):
    q = pd.read_excel(workbook, sheet_name=RAW_SHEET[depth], header=3, engine="openpyxl")
    x = pd.to_numeric(q.iloc[:289, 4], errors="raise").to_numpy(float)
    y = pd.to_numeric(q.iloc[:289, 5], errors="raise").to_numpy(float)
    r = pd.to_numeric(q.iloc[:289, 6], errors="raise").to_numpy(float)
    if len(x) != 289 or not (np.all(np.isfinite(x)) and np.all(np.isfinite(y)) and np.all(np.isfinite(r))):
        raise RuntimeError(f"Invalid physical campaign for depth {depth}")
    return x, y, r


def metrics(depth, workbook):
    x, y, r_meas = read_campaign(workbook, depth)
    zref = z_ideal(x, y, depth)
    r_ideal = RREF[depth] - zref
    residual = r_meas - r_ideal
    mape = np.mean(np.abs(residual / r_ideal))*100.0
    mae = np.mean(np.abs(residual))
    rmse = np.sqrt(np.mean(residual**2))
    bias = np.mean(residual)
    corr = np.corrcoef(r_meas, r_ideal)[0, 1]
    sse = np.sum((r_meas-r_ideal)**2)
    sst_ref = np.sum((r_ideal-np.mean(r_ideal))**2)
    r2_ref = 1.0 - sse/sst_ref
    return dict(depth_m=depth, n=len(r_meas), MAPE_pct=mape, MAE_ohm=mae,
                RMSE_ohm=rmse, mean_bias_ohm=bias,
                pearson_correlation=corr, R2_ref=r2_ref)


def main():
    here = Path(__file__).resolve().parent
    repo = here.parent
    workbook = repo/'comparacao_real_MTR1522_D020_D030_D040_FINAL.xlsx'
    if not workbook.exists():
        raise FileNotFoundError(workbook)
    out = pd.DataFrame([metrics(d, workbook) for d in (0.20, 0.30, 0.40)])
    out.to_csv(here/'physical_map_metrics_reproduced.csv', index=False)
    print(out.to_string(index=False))


if __name__ == '__main__':
    main()
