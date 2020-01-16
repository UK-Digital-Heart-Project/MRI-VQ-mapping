function [ PM, SV ] = pft_CreatePinvMatrix(AIF, ZeroFill, NSV, DT, Management)

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

% Create the convolution matrix
CM = convmtx(AIF, N);

% Perform a singular-value decomposition
[ U, S, V ] = svd(CM);

% Report the singular values for the semi-log cut-off plot
SV = diag(S);

% Treat the low singular values according to the chosen "Management" policy
switch Management
  case 'Truncate'
    T = S.';
    
    Rows = size(T, 1);
    Cols = size(T, 2);
    
    D = min(Rows, Cols);  
    
    CutOff = abs(T(NSV, NSV));
      
    for d = 1:D
      if (abs(T(d, d)) < CutOff)
        T(d, d) = 0.0;
      else
        T(d, d) = 1.0/abs(T(d, d));
      end
    end
    
  case 'Regularise'
    T = S.';
    
    Rows = size(T, 1);
    Cols = size(T, 2);
    
    D = min(Rows, Cols);  
    
    CutOff = abs(T(NSV, NSV));
      
    for d = 1:D
      if (abs(T(d, d)) < CutOff)
        T(d, d) = 1.0/(abs(T(d, d)) + CutOff);
      else
        T(d, d) = 1.0/abs(T(d, d));
      end
    end   
    
  case 'No Action'
    T = pinv(S);
end

% Divide out the time-step, on the way to any final statistical measures in real, physical units
PM = (1.0/DT) * V * T * U.';

end
