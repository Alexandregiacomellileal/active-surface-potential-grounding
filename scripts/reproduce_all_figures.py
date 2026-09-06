#!/usr/bin/env python3
"""Regenerate paper figures from the public GitHub core tables.

The GitHub core reproduces summary/paired/noise figures without MATLAB or
COMSOL. Figures requiring the larger casewise/full-field archive are generated
when those optional files are present (the complete bundle is intended for the
Zenodo release).
"""
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/"figures_reproduced"
OUT.mkdir(exist_ok=True)

# Fig. 1: clean held-out joint success versus budget.
s = pd.read_csv(ROOT/"data/heldout_final/FINAL_HELDOUT84_summary_by_budget.csv")
fig, ax = plt.subplots(figsize=(7.2,4.6))
for label, patt in [("Active","Active"),("Space","Space")]:
    x=s[s.method.str.contains(patt)].sort_values("n")
    ax.plot(x.n, 100*x.joint_success_fraction, marker="o", label=label)
ax.set_xlabel("Measurement budget N")
ax.set_ylabel("Joint success (%)")
ax.set_xticks([6,8,10,15])
ax.set_ylim(0,105)
ax.grid(True, alpha=0.3)
ax.legend()
fig.tight_layout()
fig.savefig(OUT/"Fig1_joint_success_vs_budget.png", dpi=300)
plt.close(fig)

# Fig. 2: optional casewise N=15 geometry-error distributions.
afile=ROOT/"data/heldout_final/FINAL_HELDOUT84_ACTIVE_N15_casewise.csv"
sfile=ROOT/"data/heldout_final/FINAL_HELDOUT84_SPACE_N15_casewise.csv"
if afile.exists() and sfile.exists():
    A=pd.read_csv(afile)
    S=pd.read_csv(sfile)
    metrics=[("endpoint_error_m","Endpoint error (m)"),
             ("d_abs_error_m","Depth error (m)"),
             ("phi_abs_error_deg","Orientation error (deg)")]
    fig, axes=plt.subplots(1,3,figsize=(11,3.6))
    for ax,(col,ylab) in zip(axes,metrics):
        ax.boxplot([A[col],S[col]], tick_labels=["Active","Space"], showfliers=True)
        ax.set_ylabel(ylab)
        ax.grid(True, axis="y", alpha=0.3)
    fig.tight_layout()
    fig.savefig(OUT/"Fig2_N15_geometry_errors.png", dpi=300)
    plt.close(fig)
else:
    print("Casewise N=15 tables not found; skipping Fig. 2. They are included in the complete Zenodo-ready archive.")

# Fig. 3: paired clean N=15 depth-error difference.
P=pd.read_csv(ROOT/"data/heldout_final/FINAL_HELDOUT84_paired_N15.csv").sort_values("delta_depth_active_minus_space_m")
fig, ax=plt.subplots(figsize=(7.2,4.4))
ax.plot(np.arange(1,len(P)+1), P.delta_depth_active_minus_space_m, marker=".", linewidth=1)
ax.axhline(0, linestyle="--", linewidth=1)
ax.set_xlabel("Held-out cases ordered by paired difference")
ax.set_ylabel("Depth error: Active - Space (m)")
ax.grid(True, alpha=0.3)
fig.tight_layout()
fig.savefig(OUT/"Fig3_paired_depth_difference.png", dpi=300)
plt.close(fig)

# Fig. 4: optional full 956-point illustrative field for case 12.
fcase = ROOT/"data/example_case12/case_012_surface_potential_FROZEN_v12.csv"
if fcase.exists():
    F=pd.read_csv(fcase)
    AS=pd.read_csv(ROOT/"data/example_case12/case_012_active_selection.csv")
    SS=pd.read_csv(ROOT/"data/example_case12/case_012_space_selection.csv")
    fig, axes=plt.subplots(1,2,figsize=(10.5,4.5), sharex=True, sharey=True)
    for ax,sel,title in [(axes[0],AS,"Active"),(axes[1],SS,"Space")]:
        sc=ax.scatter(F.x_m,F.y_m,c=F.V_fem_V,s=8)
        ax.plot(sel.x_m,sel.y_m,"o-",markersize=4,linewidth=1)
        ax.set_title(title)
        ax.set_xlabel("x (m)")
        ax.set_aspect("equal","box")
    axes[0].set_ylabel("y (m)")
    fig.colorbar(sc, ax=axes.ravel().tolist(), label="FEM surface potential (V)")
    fig.savefig(OUT/"Fig4_spatial_active_vs_space_case_012.png", dpi=300, bbox_inches="tight")
    plt.close(fig)
else:
    print("Case-12 full field not found; skipping Fig. 4. It is included in the complete Zenodo-ready archive.")

# Fig. 5: post-held-out noise joint success.
N=pd.read_csv(ROOT/"data/noise_stress/NOISE_STRESS_summary_by_level.csv")
fig, ax=plt.subplots(figsize=(7.2,4.6))
for method in ["Active","Space"]:
    x=N[N.method==method].sort_values("noise_pct_RMS")
    y=100*x.joint_success_fraction
    lo=100*(x.joint_success_fraction-x.CI95_low)
    hi=100*(x.CI95_high-x.joint_success_fraction)
    ax.errorbar(x.noise_pct_RMS,y,yerr=np.vstack([lo,hi]),marker="o",capsize=3,label=method)
ax.set_xlabel("Added potential-noise standard deviation (% clean-field RMS)")
ax.set_ylabel("Joint success at N=15 (%)")
ax.set_ylim(0,105)
ax.grid(True,alpha=0.3)
ax.legend()
fig.tight_layout()
fig.savefig(OUT/"Fig5_noise_joint_success.png", dpi=300)
plt.close(fig)

# Fig. 6: post-held-out noise depth error.
fig, ax=plt.subplots(figsize=(7.2,4.6))
for method in ["Active","Space"]:
    x=N[N.method==method].sort_values("noise_pct_RMS")
    ax.plot(x.noise_pct_RMS,100*x.median_depth_m,marker="o",label=f"{method} median")
    ax.plot(x.noise_pct_RMS,100*x.P90_depth_m,marker="s",linestyle="--",label=f"{method} P90")
ax.axhline(5,linestyle="--",linewidth=1,label="Frozen depth threshold")
ax.set_yscale("log")
ax.set_xlabel("Added potential-noise standard deviation (% clean-field RMS)")
ax.set_ylabel("Depth error (cm)")
ax.grid(True,which="both",alpha=0.3)
ax.legend(fontsize=8)
fig.tight_layout()
fig.savefig(OUT/"Fig6_noise_depth_error.png", dpi=300)
plt.close(fig)

print(f"Reproduced available figures written to {OUT}")
