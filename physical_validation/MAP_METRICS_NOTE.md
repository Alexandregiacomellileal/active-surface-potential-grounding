# Physical map-comparison metric convention

The physical full-grid map comparison uses the known installed geometry and the finite-line analytical reference with `rho=100 ohm m`, `L=2.40 m`, `phi=0 deg`, and 30-mm probe insertion.

Residuals are `R_measured - R_ideal`. MAPE, MAE, RMSE, mean bias, and Pearson correlation are computed directly from the 289 retained measurements.

The archived workbook/paper `R^2` convention is

`R2 = 1 - sum((R_measured - R_ideal)^2) / sum((R_ideal - mean(R_ideal))^2)`.

This is a reference-normalized coefficient of determination rather than the usual observed-response SST convention. The companion script reproduces the archived values exactly.
