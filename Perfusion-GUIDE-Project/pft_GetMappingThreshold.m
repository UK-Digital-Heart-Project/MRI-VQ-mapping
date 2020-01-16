function PC = pft_GetMappingThreshold

Options.Resize      = 'off';
Options.WindowStyle = 'modal';
Options.Interpreter = 'tex';

Prompt = { 'Mapping threshold - per cent of maximum AIF' };

Starts = { '10.0' };

Layout = zeros(1, 2, 'int16');
Layout(:, 1) = 1;
Layout(:, 2) = 45;

Answers = inputdlg(Prompt, 'Mapping parameters', Layout, Starts, Options);

Amended = false;

if (length(Answers) == length(Starts))
  PC = str2double(Answers{1});
    
  if ~isnumeric(PC) 
    PC = int32(str2double(Starts{1}));
    Amended = true;
  elseif isnan(PC) || isinf(PC) || ~isreal(PC)
    PC = int32(str2double(Starts{1}));
    Amended = true;
  end 
else
  PC = str2double(Starts{1}); 
  Amended = true;
end

if (PC < 1.0)
  PC = 1.0;
  Amended = true;
elseif (PC > 50.0)
  PC = 50.0;
  Amended = true;
end

if (Amended == true)
  beep;  
    
  Warning = { 'Input amended:', ...
              ' ', ...
              sprintf('Masking threshold = %.2f %%', PC), ...
              ' ' };
               
  Title   =   'Error correction';
  
  h = warndlg(Warning, Title, 'modal');                
  uiwait(h);
  delete(h);
end
  
end

