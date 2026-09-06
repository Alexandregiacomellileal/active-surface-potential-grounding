#!/usr/bin/env python3
from pathlib import Path
import pandas as pd
import numpy as np

ROOT = Path(__file__).resolve().parents[1]

summary = pd.read_csv(ROOT/"data/heldout_final/FINAL_HELDOUT84_summary_by_budget.csv")
active = summary[summary["method"].str.contains("Active")]
space = summary[summary["method"].str.contains("Space")]
a15 = active[active.n==15].iloc[0]
s15 = space[space.n==15].iloc[0]

assert int(a15.N_cases) == 84
assert int(a15.N_joint_success) == 84
assert int(s15.N_joint_success) == 67

a10 = active[active.n==10].iloc[0]
assert int(a10.N_joint_success) == 84

noise = pd.read_csv(ROOT/"data/noise_stress/NOISE_STRESS_summary_by_level.csv")
def val(method, level):
    return noise[(noise.method==method) & (np.isclose(noise.noise_pct_RMS,level))].iloc[0]

checks = {
    ("Active",0.5): 0.9896825397,
    ("Active",1.0): 0.9376984127,
    ("Space",0.5): 0.1865079365,
    ("Space",1.0): 0.0694444444,
}
for key, expected in checks.items():
    got = float(val(*key).joint_success_fraction)
    assert abs(got-expected) < 5e-4, (key, got, expected)

paired = pd.read_csv(ROOT/"data/heldout_final/FINAL_HELDOUT84_paired_N15.csv")
assert int((paired.delta_joint_success_active_minus_space==1).sum()) == 17
assert int((paired.delta_joint_success_active_minus_space==-1).sum()) == 0

seed = pd.read_csv(ROOT/"data/seed_robustness/seed_robustness_v10_summary.csv")
sa15 = seed[(seed.method.str.contains("Active")) & (seed.n==15)]
assert len(sa15) == 7
assert (sa15.N_joint_success==16).all()

print("PASS: key paper claims reproduce from archived result tables.")
print("Held-out N=15: Active 84/84, Space 67/84.")
print("Held-out checkpoint N=10: Active 84/84 (reported as checkpoint, not frozen budget).")
print("Seed robustness: Active 16/16 at N=15 for all 7 local seed layouts.")
print("Noise stress key levels match archived summaries.")
