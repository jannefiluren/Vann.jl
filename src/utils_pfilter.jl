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
