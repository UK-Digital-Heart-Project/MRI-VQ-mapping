function [ BW, Result ] = pft_Search2D(Selection, Array, SeedRow, SeedCol, Tolerance, FillHoles, CloseImage, ImageClosingRadius)

% Fetch the array dimensions
NR = int32(size(Array, 1));
NC = int32(size(Array, 2));

% Pre-allocate the result and initialise the seed point
BW = false(NR, NC);
BW(SeedRow, SeedCol) = true;

% Set upper and lower limits for the flood-fill
Value = Array(SeedRow, SeedCol);

Mini = min(Array(:));
Maxi = max(Array(:));

Delta = (Tolerance/100.0)*(Maxi - Mini);

Lower = Value - Delta;
Upper = Value + Delta;

Mask = (Array >= Lower) & (Array <= Upper);

% Initialise the pixel count
PrevPixels = 0;
CurrPixels = 1;

% Perform a line scan in all possible directions
while (CurrPixels > PrevPixels)
    
  PrevPixels = CurrPixels;

  % Scan by rows - 1
  for r = 1:NR
    for c = 1:NC
      if Mask(r, c) && ~BW(r, c)
        lr = int32(max(1, r - 1));
        ur = int32(min(r + 1, NR));
        lc = int32(max(1, c - 1));
        uc = int32(min(c + 1, NC));
        Block = BW(lr:ur, lc:uc);               
        if any(Block(:))
          BW(r, c) = true;
          CurrPixels = CurrPixels + 1;
        end
      end
    end
  end
  
  % Scan by rows - 2
  for r = NR:-1:1
    for c = 1:NC
      if Mask(r, c) && ~BW(r, c)
        lr = int32(max(1, r - 1));
        ur = int32(min(r + 1, NR));
        lc = int32(max(1, c - 1));
        uc = int32(min(c + 1, NC));
        Block = BW(lr:ur, lc:uc);               
        if any(Block(:))
          BW(r, c) = true;
          CurrPixels = CurrPixels + 1;
        end
      end
    end
  end
  
  % Scan by rows - 3
  for r = 1:NR
    for c = NC:-1:1
      if Mask(r, c) && ~BW(r, c)
        lr = int32(max(1, r - 1));
        ur = int32(min(r + 1, NR));
        lc = int32(max(1, c - 1));
        uc = int32(min(c + 1, NC));
        Block = BW(lr:ur, lc:uc);               
        if any(Block(:))
          BW(r, c) = true;
          CurrPixels = CurrPixels + 1;
        end
      end
    end
  end
  
  % Scan by rows - 4
  for r = NR:-1:1
    for c = NC:-1:1
      if Mask(r, c) && ~BW(r, c)
        lr = int32(max(1, r - 1));
        ur = int32(min(r + 1, NR));
        lc = int32(max(1, c - 1));
        uc = int32(min(c + 1, NC));
        Block = BW(lr:ur, lc:uc);               
        if any(Block(:))
          BW(r, c) = true;
          CurrPixels = CurrPixels + 1;
        end
      end
    end
  end
  
  % Scan by columns - 1
  for c = 1:NC
    for r = 1:NR   
      if Mask(r, c) && ~BW(r, c)
        lr = int32(max(1, r - 1));
        ur = int32(min(r + 1, NR));
        lc = int32(max(1, c - 1));
        uc = int32(min(c + 1, NC));
        Block = BW(lr:ur, lc:uc);               
        if any(Block(:))
          BW(r, c) = true;
          CurrPixels = CurrPixels + 1;
        end
      end
    end
  end
  
  % Scan by columns - 2
  for c = 1:NC
    for r = NR:-1:1
      if Mask(r, c) && ~BW(r, c)
        lr = int32(max(1, r - 1));
        ur = int32(min(r + 1, NR));
        lc = int32(max(1, c - 1));
        uc = int32(min(c + 1, NC));
        Block = BW(lr:ur, lc:uc);               
        if any(Block(:))
          BW(r, c) = true;
          CurrPixels = CurrPixels + 1;
        end
      end
    end
  end
  
  % Scan by columns - 3
  for c = NC:-1:1
    for r = 1:NR
      if Mask(r, c) && ~BW(r, c)
        lr = int32(max(1, r - 1));
        ur = int32(min(r + 1, NR));
        lc = int32(max(1, c - 1));
        uc = int32(min(c + 1, NC));
        Block = BW(lr:ur, lc:uc);               
        if any(Block(:))
          BW(r, c) = true;
          CurrPixels = CurrPixels + 1;
        end
      end
    end
  end
  
  % Scan by columns - 4
  for c = NC:-1:1
    for r = NR:-1:1
      if Mask(r, c) && ~BW(r, c)
        lr = int32(max(1, r - 1));
        ur = int32(min(r + 1, NR));
        lc = int32(max(1, c - 1));
        uc = int32(min(c + 1, NC));
        Block = BW(lr:ur, lc:uc);               
        if any(Block(:))
          BW(r, c) = true;
          CurrPixels = CurrPixels + 1;
        end
      end
    end
  end
  
end

% Fill any holes in the output BW mask if required
if (FillHoles == true)
  BW = imfill(BW, 'holes');
end

% Close the image morphologically if required
if (CloseImage == true)
  BW = imclose(BW, strel('disk', ImageClosingRadius, 0));
end

% Assign the logical ROI correctly to the left or the right lung
switch Selection
  case 'Right Lung'
    Result = 'Right Lung';
    
  case 'Left Lung'
    Result = 'Left Lung';
    
  case 'Auto-Detect'
    [ xx, yy ] = meshgrid(1:NC, 1:NR);
    
    CMX = sum(double(xx(:)).*double(BW(:)))/sum(double(BW(:)));
    
    if (CMX <= 0.5*double(1 + NC))
      Result = 'Right Lung';
    else
      Result = 'Left Lung';
    end
end      

end

