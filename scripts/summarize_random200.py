#!/usr/bin/env python3
"""Aggregate the 200-layout Random benchmark from a casewise CSV.

Expected columns:
layout_seed, case_id, joint_success, endpoint_error_m, d_abs_error_m,
phi_abs_error_deg, fullfield_RMSE_pct_RMS
"""
from pathlib import Path
import argparse
import numpy as np
import pandas as pd

def pct(x, q):
    return float(np.percentile(np.asarray(x, float), q, method="linear"))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="Casewise Random CSV")
    ap.add_argument("--outdir", default="random200_summary")
    args = ap.parse_args()

    df = pd.read_csv(args.input)
    required = {
        "layout_seed","case_id","joint_success","endpoint_error_m",
        "d_abs_error_m","phi_abs_error_deg","fullfield_RMSE_pct_RMS"
    }
    missing = required.difference(df.columns)
    if missing:
        raise ValueError(f"Missing columns: {sorted(missing)}")

    seeds = sorted(df.layout_seed.unique())
    if len(seeds) != 200:
        raise ValueError(f"Expected 200 layouts, found {len(seeds)}")
    if any(len(g) != 84 for _, g in df.groupby("layout_seed")):
        raise ValueError("Each layout must contain 84 cases")

    out = Path(args.outdir)
    out.mkdir(parents=True, exist_ok=True)

    rows = []
    for seed, g in df.groupby("layout_seed", sort=True):
        r = {
            "layout_seed": int(seed),
            "N_cases": len(g),
            "joint_success_count": int(g.joint_success.sum()),
            "joint_success_fraction": float(g.joint_success.mean()),
        }
        for col, key in [
            ("endpoint_error_m","endpoint_m"),
            ("d_abs_error_m","depth_m"),
            ("phi_abs_error_deg","phi_deg"),
            ("fullfield_RMSE_pct_RMS","fullfield_RMSE_pct_RMS"),
        ]:
            a = g[col].to_numpy(float)
            r[f"median_{key}"] = float(np.median(a))
            r[f"P90_{key}"] = pct(a, 90)
            r[f"max_{key}"] = float(np.max(a))
        rows.append(r)

    layouts = pd.DataFrame(rows)
    layouts.to_csv(out / "RANDOM200_LAYOUT_SUMMARY.csv", index=False)

    jc = layouts.joint_success_count.to_numpy(float)
    jf = layouts.joint_success_fraction.to_numpy(float)
    dist = {
        "N_layouts": 200,
        "joint_success_count_mean": float(jc.mean()),
        "joint_success_count_median": float(np.median(jc)),
        "joint_success_count_P10": pct(jc,10),
        "joint_success_count_P90": pct(jc,90),
        "joint_success_count_min": int(jc.min()),
        "joint_success_count_max": int(jc.max()),
        "joint_success_fraction_mean": float(jf.mean()),
        "joint_success_fraction_median": float(np.median(jf)),
        "joint_success_fraction_P10": pct(jf,10),
        "joint_success_fraction_P90": pct(jf,90),
        "joint_success_fraction_min": float(jf.min()),
        "joint_success_fraction_max": float(jf.max()),
    }
    pd.DataFrame([dist]).to_csv(out / "RANDOM200_DISTRIBUTION_CORE.csv", index=False)

    prefixes = [10,20,50,100,150,200]
    pref = []
    for n in prefixes:
        s = layouts.iloc[:n]
        x = s.joint_success_count.to_numpy(float)
        pref.append({
            "N_layouts": n,
            "mean_joint_count": float(x.mean()),
            "median_joint_count": float(np.median(x)),
            "P10_joint_count": pct(x,10),
            "P90_joint_count": pct(x,90),
            "min_joint_count": int(x.min()),
            "max_joint_count": int(x.max()),
        })
    pd.DataFrame(pref).to_csv(out / "RANDOM200_CONVERGENCE_CORE.csv", index=False)

if __name__ == "__main__":
    main()
