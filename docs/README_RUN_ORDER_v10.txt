PAPER 1 — POST-HELD-OUT MEASUREMENT-NOISE STRESS TEST v1.0
================================================================

Purpose
-------
Secondary numerical measurement-noise stress test intended to strengthen the
measurement-science framing. The original 84 held-out cases are ALREADY
CONSUMED. This is not a new independent validation.

No COMSOL rerun is required.

Frozen design
-------------
Positive noise levels: 0.10, 0.25, 0.50, 1.00, 2.00 % of each case's clean
full-field potential RMS. 30 Monte Carlo realizations per case/level.
N=15 remains the frozen primary measurement budget. Active and Space share the
same latent noise realization for each paired case/level/repetition.

Recommended Drive layout
------------------------
09_POST_HELDOUT_MEASUREMENT_NOISE_v10/
  00_PROTOCOL/
    POST_HELDOUT_NOISE_PROTOCOL_v10.json
    POST_HELDOUT_NOISE_PROTOCOL_v10.txt
    NOISE_STRESS_PREFLIGHT_PASS.txt   [created after preflight]
  01_RUN/
    paper1_v5M80_noise_task_v10.m
    verify_postheldout_noise_preflight_v10.m
    run_postheldout_noise_stress_v10.m
    summarize_postheldout_noise_stress_v10.m
  02_RESULTS/                         [created/populated by runner]
  03_PAPER_OUTPUTS/                   [created by summarizer]

Run order in MATLAB R2025b
--------------------------
1) cd to 01_RUN
2) verify_postheldout_noise_preflight_v10
3) inspect only that the console says PREFLIGHT PASS (no noise outcome exists yet)
4) run_postheldout_noise_stress_v10
   - long run; restart-safe
   - Ctrl+C is okay; rerun the same command to continue
   - do not inspect intermediate outcomes or alter the frozen protocol
5) after ALL tasks complete:
   summarize_postheldout_noise_stress_v10

Computational note
------------------
The full protocol contains 84 x 5 x 30 = 12,600 paired noisy case-level-rep
tasks. No COMSOL is involved, but the nonlinear inverse estimation and Active
sequential selection are computationally nontrivial. The runner checkpoints
after every repetition so it can be executed over multiple sessions.

Scientific guardrails
---------------------
- Do not change noise levels/repetition count based on intermediate outcomes.
- Do not retune M, seed, N, thresholds, A-optimal rule, optimizer or weights.
- sigma_design=1% RMS remains the frozen design/objective scale; it is not the
  injected noise standard deviation.
- The zero-noise point in the final plot comes from the already disclosed final
  held-out results.
- Any behavior-preserving bug/runtime fix must be documented.
