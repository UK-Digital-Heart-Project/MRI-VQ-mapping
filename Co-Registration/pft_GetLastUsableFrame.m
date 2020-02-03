function LUF = pft_GetLastUsableFrame(Epochs)

Options.Resize      = 'off';
Options.WindowStyle = 'modal';
Options.Interpreter = 'tex';

Prompt = { 'Last usable frame' };

Starts = { '17' };

Layout = zeros(1, 2, 'int16');
Layout(:, 1) = 1;
Layout(:, 2) = 45;

Answers = inputdlg(Prompt, 'Processing decision', Layout, Starts, Options);

Amended = false;

if (length(Answers) == length(Starts))
  LUF = str2double(Answers{1});
    
  if ~isnumeric(LUF) 
    LUF = int32(str2double(Starts{1}));
    Amended = true;
  elseif isnan(LUF) || isinf(LUF) || ~isreal(LUF)
    LUF = int32(str2double(Starts{1}));
    Amended = true;
  end 
else
  LUF = str2double(Starts{1}); 
  Amended = true;
end

if (LUF < 5)
  LUF = 5;
  Amended = true;
elseif (LUF > Epochs)
  LUF = Epochs;
  Amended = true;
end

if (Amended == true)
  beep;  
    
  Warning = { 'Input amended:', ...
              ' ', ...
              sprintf('Last usable frame = %1d', LUF), ...
              ' ' };
               
  Title   =   'Error correction';
  
  h = warndlg(Warning, Title, 'modal');                
  uiwait(h);
  delete(h);
end
  
end



