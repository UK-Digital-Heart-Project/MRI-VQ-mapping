function [ LowerCC, UpperCC, NAUC ] = pft_GetIngrischMappingThresholds(LowerCCStart, UpperCCStart, NAUCStart)

Options.Resize      = 'off';
Options.WindowStyle = 'modal';
Options.Interpreter = 'tex';

Prompt = { 'Lower CC - per cent', 'Upper CC - percent', 'Normalized area - per cent' };

Starts = { sprintf('%.2f', LowerCCStart), sprintf('%.2f', UpperCCStart), sprintf('%.2f', NAUCStart) };

Layout = zeros(1, 2, 'int16');
Layout(:, 1) = 1;
Layout(:, 2) = 45;

Answers = inputdlg(Prompt, 'Mapping parameters', Layout, Starts, Options);

Amended = false;

if (length(Answers) == length(Starts))
  LowerCC = str2double(Answers{1});
    
  if ~isnumeric(LowerCC) 
    LowerCC = str2double(Starts{1});
    Amended = true;
  elseif isnan(LowerCC) || isinf(LowerCC) || ~isreal(LowerCC)
    LowerCC = str2double(Starts{1});
    Amended = true;
  end 
  
  UpperCC = str2double(Answers{2});
    
  if ~isnumeric(UpperCC) 
    UpperCC = str2double(Starts{2});
    Amended = true;
  elseif isnan(UpperCC) || isinf(UpperCC) || ~isreal(UpperCC)
    UpperCC = str2double(Starts{2});
    Amended = true;
  end 
  
  NAUC = str2double(Answers{3});
    
  if ~isnumeric(NAUC) 
    NAUC = str2double(Starts{3});
    Amended = true;
  elseif isnan(NAUC) || isinf(NAUC) || ~isreal(NAUC)
    NAUC = str2double(Starts{3});
    Amended = true;
  end   
else
  LowerCC = str2double(Starts{1}); 
 
  UpperCC = str2double(Starts{2}); 
  
  NAUC = str2double(Starts{3}); 
end

if (LowerCC < 10.0)
  LowerCC = 10.0;
  Amended = true;
elseif (LowerCC > 50.0)
  LowerCC = 50.0;
  Amended = true;
end

if (UpperCC < 60.0)
  UpperCC = 60.0;
  Amended = true;
elseif (UpperCC > 99.0)
  UpperCC = 99.0;
  Amended = true;
end

if (NAUC < 1.0)
  NAUC = 1.0;
  Amended = true;
elseif (NAUC > 20.0)
  NAUC = 20.0;
  Amended = true;
end

if (Amended == true)
  beep;  
    
  Warning = { 'Input amended:', ...
              ' ', ...
              sprintf('Lower CC = %.2f %%', LowerCC), ...
              ' ', ...
              sprintf('Upper CC = %.2f %%', UpperCC), ...
              ' ', ...
              sprintf('Normalized area = %.2f %%', NAUC), ...
              ' ' };
               
  Title   =   'Error correction';
  
  h = warndlg(Warning, Title, 'modal');                
  uiwait(h);
  delete(h);
end
  
end

