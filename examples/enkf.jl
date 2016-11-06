function enkf(state_ens, d_matrix, hx_matrix)

# Ensemble Kalman filter equations following (a) Mandel, J. Efficient
# implementation of the ensemble kalman filter (b) DeChant, C. Examining
# the effectiveness and robustness of sequential data assimilation
# methods for quantification of uncertainty in hydrological forecasting.

# Variables (Mandel)

X  = state_ens;
D  = d_matrix;
HX = hx_matrix;

# Subtract ensemble mean (Mandel)

(n, N) = size(X);
(m, N) = size(D);

A    = X - 1 / N * (X * ones(Float64, N, 1)) * ones(Float64, 1, N);
HA   = HX - 1 / N * (HX * ones(Float64, N, 1)) * ones(Float64, 1, N);
Dtmp = D - 1 / N * (D * ones(Float64, N, 1)) * ones(Float64, 1, N);

# Observation error variance (Mandel-theoretic, Evensen-sample)

R_sample = Dtmp * Dtmp' / (N-1);

# Variance of predicted observations (DeChant and Mandel)

C_YY = 1 / (N-1) * HA * HA';

# Covariance between states ensemble and predicted observations (DeChant and Mandel)

C_XY = 1 / (N-1) * A * HA';

# Compute kalman gain (DeChant)

K = C_XY / (C_YY + R_sample);

# Update states (DeChant and Mandel)

Xhat = X + K*(D-HX);

return(Xhat);

end
