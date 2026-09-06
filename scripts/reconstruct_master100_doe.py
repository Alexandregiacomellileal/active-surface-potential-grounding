#!/usr/bin/env python3
"""Reconstruct the frozen 100-case DOE used in the paper.

Requires scipy. The historical generator was:
    scipy.stats.qmc.LatinHypercube(d=4, seed=20260816)
with transforms documented below.
"""
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import qmc

SEED = 20260816
DEV_IDS = [2,3,5,6,9,20,25,32,38,59,66,69,92,93,94,98]

sampler = qmc.LatinHypercube(d=4, seed=SEED)
u = sampler.random(100)
df = pd.DataFrame({
    "case_id": np.arange(1, 101, dtype=int),
    "L_m": 8 + 22*u[:,0],
    "phi_deg": 360*u[:,1],
    "d_m": 0.5 + u[:,2],
    "rho_ohm_m": 10**(
        np.log10(50) +
        (np.log10(2000)-np.log10(50))*u[:,3]
    ),
})
out = Path(__file__).resolve().parents[1] / "data" / "doe"
out.mkdir(parents=True, exist_ok=True)
df.to_csv(out/"master100_reconstructed_full_precision.csv", index=False)
d6 = df.copy()
for c in ["L_m","phi_deg","d_m","rho_ohm_m"]:
    d6[c] = d6[c].round(6)
d6.to_csv(out/"master100_reconstructed_6dp.csv", index=False)
d6[d6.case_id.isin(DEV_IDS)].to_csv(out/"development16_DOE_reconstructed.csv", index=False)
d6[~d6.case_id.isin(DEV_IDS)].to_csv(out/"heldout84_DOE_reconstructed.csv", index=False)

checkpoint = out/"heldout84_FROZEN_v12_checkpoint.csv"
if checkpoint.exists():
    chk = pd.read_csv(checkpoint)
    merged = chk.merge(d6, on="case_id", suffixes=("_archived","_recon"))
    mapping = {
        "L_m_archived":"L_m_recon",
        "phi_deg_archived":"phi_deg_recon",
        "d_m_archived":"d_m_recon",
        "rho_ohm_m_archived":"rho_ohm_m_recon",
    }
    worst = 0.0
    for a,b in mapping.items():
        worst = max(worst, float((merged[a]-merged[b]).abs().max()))
    print(f"Authenticated 84-case complement; max 6-dp scalar delta = {worst:.3g}")
    if worst > 1e-12:
        raise SystemExit("DOE authentication failed.")
print("DOE reconstruction complete.")
