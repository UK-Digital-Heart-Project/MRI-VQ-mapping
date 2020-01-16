function CM = pft_CreateConvMatrix(AIF, ZeroFill, DT)

% Coerce the AIF to be a column vector - this should just be a precaution
AIF = AIF(:);               

% Increase the precision of the calculation
AIF = double(AIF);          

% Fetcvh the initial size of AIF and truncated TC (from epoch 2, at time "zero", to the last usable frame)
M = numel(AIF);             

% Zero-fill the AIF to double its length if requested
if (ZeroFill == true)
  N = 2*M;
  
  AIF = vertcat(AIF, zeros([M, 1], 'double'));
else
  N = M;
end

% The multiplication here becomes a division when this matrix is deployed in a left-division calculation
CM = DT*convmtx(AIF, N);    

end


  

