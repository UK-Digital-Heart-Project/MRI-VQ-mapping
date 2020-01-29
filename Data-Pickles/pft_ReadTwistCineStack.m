function [ CineStack, AT, Head ] = pft_ReadTwistCineStack(Root)

% Initialise the return values in case of an early exit
CineStack = [];

AT = [];

Head = [];

% List the sub-folders within the Root folder
SubFolders = pft_ListTwistFolders(Root);

% Exit if there are no sub-folders
if isempty(SubFolders)
  h = msgbox('No sub-folders found', 'Exit', 'modal');
  uiwait(h);
  delete(h);
  return;
end

% Count the epochs
NEPOCHS = numel(SubFolders);

% Dimension the AT (Acquisition Time) and ST (Series Time) arrays
AT = zeros([NEPOCHS, 1], 'double');

% Create a progress bar
wb = waitbar(0, 'Reading sub-folders ...');

ScreenSize = get(0, 'ScreenSize');
HT = ScreenSize(4);
OuterPosition = get(wb, 'OuterPosition');
OuterPosition(2) = OuterPosition(2) + 0.05*HT;

set(wb, 'OuterPosition', OuterPosition);

% Dimension the 4-D cine-stack using the first sub-folder, and read in a common working Dicom header, to be modified for o/p in the perfusion mapping GUI
Path = fullfile(Root, SubFolders{1});

[ Data, AT(1) ] = pft_ReadTwistFiles(Path);

[ NROWS, NCOLS, NSLICES ] = size(Data);
Type = class(Data);

CineStack = zeros([NROWS, NCOLS, NSLICES, NEPOCHS], Type);

CineStack(:, :, :, 1) = Data;

Path = fullfile(Root, SubFolders{NEPOCHS});

Head = pft_ReadCommonWorkingHeader(Path);

waitbar(double(1)/double(NEPOCHS), wb, sprintf('Read 1 of %1d sub-folders', NEPOCHS));

% Now read in the remaining epochs
for e = 2:NEPOCHS
  Path = fullfile(Root, SubFolders{e});
    
  [ Data, AT(e) ] = pft_ReadTwistFiles(Path);
  
  CineStack(:, :, :, e) = Data;
  
  waitbar(double(e)/double(NEPOCHS), wb, sprintf('Read %1d of %1d sub-folders', e, NEPOCHS));
end

delete(wb);

% Re-sort the epochs by Acquisition Time
wb = waitbar(0.5, 'Re-sorting epochs ...');

ScreenSize = get(0, 'ScreenSize');
HT = ScreenSize(4);
OuterPosition = get(wb, 'OuterPosition');
OuterPosition(2) = OuterPosition(2) + 0.05*HT;

set(wb, 'OuterPosition', OuterPosition);

[ AT, Order ] = sort(AT);

CineStack = CineStack(:, :, :, Order);

waitbar(1, wb, 'Re-sorting completed');

pause(1.0);

delete(wb);

end


