function [ Data, AcquisitionTime ] = pft_ReadTwistFiles(SubFolder)

% Initialise the return values in case of an early exit
Data = [];

AcquisitionTime = [];

% List the files within the nominated sub-folder
Listing   = dir(fullfile(SubFolder, '*.dcm'));
FileNames = { Listing.name };
Folders   = [ Listing.isdir ];
FileNames = FileNames(~Folders);
FileNames = sort(FileNames);
FileNames = FileNames';

% Count the slices
NSLICES = numel(FileNames);

% Return if no files are found
if isempty(FileNames)
  return;
end

% Fetch a Dicom dictionary
Dictionary = dicomdict('get');

% Create a progress bar
wb = waitbar(0, 'Reading Dicom files ...');

ScreenSize = get(0, 'ScreenSize');
HT = ScreenSize(4);
OuterPosition = get(wb, 'OuterPosition');
OuterPosition(2) = OuterPosition(2) - 0.05*HT;

set(wb, 'OuterPosition', OuterPosition);

% Dimension the data array from the first Dicom file
Path = fullfile(SubFolder, FileNames{1});
Info = dicominfo(Path, 'Dictionary', Dictionary);
Temp = dicomread(Info);

[ NROWS, NCOLS ] = size(Temp);
Type = class(Temp);
Data = zeros([NROWS, NCOLS, NSLICES], Type);

Data(:, :, 1) = Temp;

% Fetch the Acquisition Time
AT = Info.AcquisitionTime;
HH = str2double(AT(1:2));
MM = str2double(AT(3:4));
SS = str2double(AT(5:6));
FF = str2double(AT(8:end));

AcquisitionTime = 3600.0*HH + 60.0*MM + SS + 1.0e-6*FF;

waitbar(double(1)/double(NSLICES), wb, sprintf('Read 1 of %1d files', NSLICES));

% Now read in the all the headers and the data (planes in a 3-D acquisition)
for s = 2:NSLICES
  Path = fullfile(SubFolder, FileNames{s});    
  Info = dicominfo(Path, 'Dictionary', Dictionary);  
  Temp = dicomread(Info);
  
  Data(:, :, s) = Temp; 
  
  waitbar(double(s)/double(NSLICES), wb, sprintf('Read %1d of %1d files', s, NSLICES));
end

delete(wb);

end






