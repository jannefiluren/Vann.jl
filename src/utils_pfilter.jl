
# Perturb input data for snow model

function perturb_input(st_snow::SnowType, prec, tair, itime)

  n = Uniform(0.5, 1.5);
  prec_noise = rand(n, 1);

  n = Normal(0.0, 2);
  tair_noise = rand(n, 1);

  # Assign inputs to snow model

  for izone in eachindex(st_snow.prec)

    st_snow.prec[izone] = prec[izone, itime] * prec_noise[1];
    st_snow.tair[izone] = tair[izone, itime] + tair_noise[1];

  end

end


# Resampling

function resample(wk)

  Ns = length(wk);
  Q  = cumsum(wk);
  Q[Ns] = 1.0;

  indx = zeros(Int64,Ns);

  i = 1;
  while i <= Ns
    sampl = rand();
    j = 1;
    while Q[j] < sampl
      j = j + 1;
    end
    indx[i] = j;
    i = i + 1;
  end

  return(indx);

end
