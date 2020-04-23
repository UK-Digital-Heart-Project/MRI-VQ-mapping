function Info = pft_ReadCommonDicomHeader(SubFolder)

% Initialise the return values in case of an early exit
Info = [];

% List the files within the nominated sub-folder
Listing   = dir(fullfile(SubFolder, '*.dcm'));
FileNames = { Listing.name };
Folders   = [ Listing.isdir ];
FileNames = FileNames(~Folders);
FileNames = sort(FileNames);
FileNames = FileNames';

% Return if no files are found
if isempty(FileNames)
  return;
end

% Fetch a Dicom dictionary
Dictionary = dicomdict('get');

% Create a progress bar
wb = waitbar(0.5, 'Reading DICOM header ...');

ScreenSize = get(0, 'ScreenSize');
HT = ScreenSize(4);
OuterPosition = get(wb, 'OuterPosition');
OuterPosition(2) = OuterPosition(2) - 0.05*HT;

set(wb, 'OuterPosition', OuterPosition);

% Read the common working header from the first file
Path = fullfile(SubFolder, FileNames{1});
Info = dicominfo(Path, 'Dictionary', Dictionary);

waitbar(1.0, wb, 'DICOM header aqcuired');

delete(wb);

end






