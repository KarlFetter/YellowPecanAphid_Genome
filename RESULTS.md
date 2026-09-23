
### 2.X Results: Transposable elements and genetic diversity

All four models converged well (R-hat = 1.00 for every parameter; bulk and tail effective sample sizes exceeded 5,000 draws in all cases). Because diversity was modeled on the log scale, regression coefficients are reported below both as the raw estimate (natural-log scale) and as the corresponding multiplicative effect on π (back-transformed as *e*^estimate), together with the 95% credible interval (CrI).

**TE presence (Model 1).** Windows containing an annotated TE had lower nucleotide diversity than TE-free windows (estimate = −0.07, 95% CrI [−0.09, −0.05]), corresponding to π that was approximately 5–9% lower in TE-containing windows (fold-change 0.91–0.95; point estimate 0.93). The 95% credible interval excluded zero, indicating a credible negative association between TE presence and local diversity.

**TE order and TE fraction (Model 2).** Among TE-containing windows, diversity varied by TE order relative to DNA transposons (the reference level). Windows dominated by retrotransposons had modestly lower diversity (estimate = −0.04, 95% CrI [−0.07, −0.01]; ≈ 1–7% lower π), whereas windows containing rolling-circle elements had higher diversity (estimate = 0.08, 95% CrI [0.04, 0.13]; ≈ 4–14% higher π). The strongest effect in this model was the continuous fraction of a window occupied by TE sequence (estimate = −1.19, 95% CrI [−1.38, −0.99]), corresponding to an approximately 63–75% reduction in π across the full range of TE density (fold-change 0.25–0.37 at 100% TE coverage relative to 0% coverage). This indicates that the amount of TE sequence within a window, not merely its presence, is the dominant predictor of reduced local diversity.

**TE class (Model 2b).** At finer taxonomic resolution, LTR elements (estimate = −0.07, 95% CrI [−0.12, −0.03]; ≈ 3–11% lower π) and Penelope-like elements (PLE; estimate = −0.25, 95% CrI [−0.44, −0.05]; ≈ 5–36% lower π, with a wide interval reflecting the small number of PLE-containing windows) were associated with reduced diversity, while rolling-circle elements (estimate = 0.08, 95% CrI [0.04, 0.13]) and SINEs (estimate = 0.45, 95% CrI [0.08, 0.82]; ≈ 8–127% higher π, likewise imprecisely estimated owing to the rarity of SINE-containing windows) were associated with elevated diversity. LINE-containing windows did not differ credibly from the DNA transposon reference level (estimate = −0.03, 95% CrI [−0.06, 0.01]; interval spans zero). The TE-fraction effect was consistent with Model 2 (estimate = −1.17, 95% CrI [−1.36, −0.97]).

**TE age (Model 3).** Among TE-containing windows, mean TE age (standardized Kimura divergence) was weakly and only marginally associated with diversity (estimate = 0.01, 95% CrI [0.00, 0.02]), corresponding to approximately a 0–2% increase in π per standard deviation increase in Kimura divergence. Because the credible interval lower bound was at or near zero, this association should be interpreted as weak evidence for a small increase in diversity around older, more diverged TE insertions, rather than a strong or clearly established effect.

Across all four models, chromosome identity explained additional variation in diversity independent of TE content, with one scaffold (Chr05) showing consistently higher baseline diversity (≈ 32–41% higher than the reference chromosome) than the others.

---

