function F = pft_GaussianFilter(Npts, Decades)

if (Decades == 0)
  F = ones(Npts, 1);
else
  D = double(Decades);
  P = double(0:Npts-1)';
  M = double(Npts-1);
  
  F = 10.0.^(-D*(P/M).^2);
end

end

