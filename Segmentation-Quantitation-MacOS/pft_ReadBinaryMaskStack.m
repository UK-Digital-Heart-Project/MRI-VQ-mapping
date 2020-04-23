function BinaryMaskStack = pft_ReadBinaryMaskStack(BinaryMaskFolder, Dims)

% Use the image dimensions to check the size of the binary masks (so, the image needs to be read in first)
NR = Dims(1);
NC = Dims(2);
NP = Dims(3);

% Initialize the stack to all-true (no masking)
BinaryMaskStack = false([NR, NC, NP]);

% Read in any saved binary masks, but check their dimensions; disregard any masks with the wrong dimensions, but issue a warning of their presence
ErrorMessage = 'OK';

wb = waitbar(0, 'Reading binary masks');

for p = 1:NP
  BinaryMaskFilePath = fullfile(BinaryMaskFolder, sprintf('Binary-Mask-Slice-%03d.png', p));
  
  if (exist(BinaryMaskFilePath, 'file') == 2)
    BW = imread(BinaryMaskFilePath);
    
    dims = size(BW);
    
    nr = dims(1);
    nc = dims(2);
    
    if isequal(nr, NR) && isequal(nc, NC)
      BinaryMaskStack(:, :, p) = logical(BW);
    else
      ErrorMessage = 'Some mis-sized masks found and disregarded';
    end
  end
  
  waitbar(double(p)/double(NP), wb, sprintf('Read %1d of %1d binary masks.', p, NP));
end

waitbar(1, wb, sprintf('Read %1d of %1d binary masks.', NP, NP));

pause(0.25);

delete(wb);
    
% Issue a warning if necessary (this is a soft failure)
if strcmpi(ErrorMessage, 'Some mis-sized masks found and disregarded')
  h = warndlg(ErrorMessage, 'Warning - i/p data', 'modal');
  uiwait(h);
  delete(h);
end

end