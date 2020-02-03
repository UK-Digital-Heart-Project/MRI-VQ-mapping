function pft_MultiModalCoregisterOnePickleFileInteractively

% Fetch the top-level folder
fid = fopen('Top-Level-Folder.txt', 'rt');
TopLevelFolder = fgetl(fid);
fclose(fid);

% Prompt for a pickle file - but exit if none is chosen
[FileName, PathName, FilterIndex] = uigetfile(fullfile(TopLevelFolder, '*.mat'), 'Select a pickle file', TopLevelFolder);

if (FilterIndex == 0)
  h = msgbox('No file chosen', 'Exit', 'modal');
  uiwait(h);
  delete(h);
  return;
end

SourcePicklePath = fullfile(PathName, FileName);

% Load the pickle file and extract some dimensional information
wb = waitbar(0.5, 'Loading data - please wait ... ');

Pickle = load(SourcePicklePath);

pause(1.0);
waitbar(1, wb, 'Data loading completed');
pause(1.0);
delete(wb);

DxDy = Pickle.Head.PixelSpacing;

Dy = DxDy(1);   % Sic ! - from the Dicom standard
Dx = DxDy(2);   % Sic ! - from the Dicom standard

ST = Pickle.Head.SliceThickness;

[ NR, NC, NP, NE ] = size(Pickle.CineStackX1);

Type = class(Pickle.CineStackX1);

% Load the first (static, fixed) reference image
Static = squeeze(Pickle.CineStackX1(:, :, :, 1));

% Prompt for the Last Usable Frame
LUF = pft_GetLastUsableFrame(NE);

% Co-register the Moving image to the Static
CineStackX1 = zeros([NR, NC, NP, LUF], Type);

CineStackX1(:, :, :, 1) = Static;

IsoNR = NR;
IsoNC = NC;
IsoNP = round(double(NP)*ST/Dx);

IsoStatic = imresize3(Static, [IsoNR, IsoNC, IsoNP]);

wb = waitbar(0, 'Beginning co-registration of full-resolution epochs ... ');
pause(1.0);
waitbar(double(1)/double(LUF), wb, sprintf('%1d of %1d epochs completed', 1, LUF));

for e = 2:LUF
  Moving = squeeze(Pickle.CineStackX1(:, :, :, e));     
  
  IsoMoving = imresize3(Moving, [IsoNR, IsoNC, IsoNP]);
  
  [ Displacement, IsoRegisteredMoving ] = imregdemons(IsoMoving, IsoStatic);
  
  RegisteredMoving = imresize3(IsoRegisteredMoving, [NR, NC, NP]);
  
  CineStackX1(:, :, :, e) = RegisteredMoving;
  
  waitbar(double(e)/double(LUF), wb, sprintf('%1d of %1d epochs completed', e, LUF));
end

pause(1.0);
waitbar(1, wb, 'Co-registration completed');
pause(1.0);
delete(wb);

% Create downsampled versions of the co-registered cine-stack
wb = waitbar(0.5, 'Calculating outputs - please wait ... ');

CineStackX2 = zeros([round(NR/2), round(NC/2), round(NP/2), LUF], Type);
  
for e = 1:LUF
  CineStackX2(:, :, :, e) = imresize3(CineStackX1(:, :, :, e), [round(NR/2), round(NC/2), round(NP/2)], 'Method', 'box');
end
  
CineStackX4 = zeros([round(NR/4), round(NC/4), round(NP/4), LUF], Type);
  
for e = 1:LUF
  CineStackX4(:, :, :, e) = imresize3(CineStackX2(:, :, :, e), [round(NR/4), round(NC/4), round(NP/4)], 'Method', 'box');
end
  
CineStackX8 = zeros([round(NR/8), round(NC/8), round(NP/8), LUF], Type);
  
for e = 1:LUF
  CineStackX8(:, :, :, e) = imresize3(CineStackX4(:, :, :, e), [round(NR/8), round(NC/8), round(NP/8)], 'Method', 'box');
end

pause(1.0);
waitbar(1, wb, 'Calculation completed');
pause(1.0);
delete(wb);

% Write out a pickle file
p = strfind(FileName, '.');
q = p(end);
r = q - 1;

OutputFileName = sprintf('%s-MM-Spline-Coregistered.mat', FileName(1:r));

TargetPicklePath = fullfile(PathName, OutputFileName);

wb = waitbar(0.5, 'Saving data - please wait ... ');

Head = Pickle.Head;
AT   = Pickle.AT(1:LUF);

save(TargetPicklePath, 'CineStackX1', 'CineStackX2', 'CineStackX4', 'CineStackX8', 'AT', 'Head');

pause(1.0);
waitbar(1, wb, 'Data saving complete');
pause(1.0);
delete(wb);

end
