# Additional benchmark chronology — 2026-09-21

The original held-out comparison was completed with A-optimal Active versus deterministic maximin Space. The 84-case held-out population was then considered consumed.

After those results were available, additional comparisons were added in response to the need for broader acquisition baselines:

1. D-optimal sequential design at the same N=15 budget and with the same estimator.
2. Random sparse acquisition, ultimately summarized over 200 layouts.
3. Full-grid inversion with all 956 admissible locations as a dense-data reference.

These analyses did not modify the original A-optimal method. Because they reuse the consumed 84-case population, they are reported as post-hoc comparative benchmarks and not as an independent validation.

The 200-layout Random extension retained the previously executed first 50 seeds and froze 150 additional seeds before executing those additional realizations. The final 200-layout distribution had median joint success 70/84, P10-P90 64/84-78/84, and range 61/84-82/84. No Random layout reached 84/84.

D-optimal achieved 84/84 joint success with errors very close to A-optimal. This changes the interpretation from 'A-optimal is uniquely superior' to the broader conclusion that information-driven OED improves consistency, particularly for burial-depth identifiability.
