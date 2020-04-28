%% Clear the workspace as usual

clear all
close all
clc

fclose('all');

%% Point to the quantitation folder

Fptr = fopen('Quantitation-Folder.txt', 'rt');
Root = fscanf(Fptr, '%s');
fclose(Fptr);

%% List all the summary files present

Listing = dir(fullfile(Root, 'HH*INGRISCH*QUANTIFICATION*.xlsx'));
Present = { Listing.name };
Folders = [ Listing.isdir ];
Present(Folders) = [];
Present = sort(Present);
Present = Present';

%% Point to the compilation file and make an immediate backup

Target = fullfile(Root, 'INGRISCH-QUANTIFICATION-COMPILATION.xlsx');
Backup = fullfile(Root, 'INGRISCH-QUANTIFICATION-COMPILATION-BACKUP.xlsx');

copyfile(Target, Backup);

%% List the tabs to be processed - this line is only a placeholder, and included for clarity

Tabs = { 'Resolution', 'Deficits', 'PBV', 'Unfiltered PBV', 'PBF', 'MTT', 'Unfiltered MTT', 'TTP', 'Censorship'};

%% Extract a list of already audited summary files from the compilation

[ Num, Txt, Raw ] = xlsread(Target, 'Resolution');

if (size(Raw, 1) == 1)
  Audited = {};
else
  Head = Raw(1, :);
  Data = Raw(2:end, :);
  ColA = find(strcmpi(Head, 'Quantitation summary filename'), 1, 'first');
  
  Audited = Data(:, ColA);
end

%% Create a list of files waiting to be processed - and exit if the list is empty (i.e., the compilation is up-to-date)

Waiting = setdiff(Present, Audited);

if isempty(Waiting)
  h = msgbox('Compilation is up-to-date', 'Exit', 'modal');
  uiwait(h);
  delete(h);
  return;
end

%% Process any files which are waiting

NFILES = size(Waiting, 1);

wb = waitbar(0, 'Collating recent files');

for n = 1:NFILES
  Source = fullfile(Root, Waiting{n});
  
  pft_AppendOneXlsxIngrischQuantificationFile(Source, Target);
  
  waitbar(double(n)/double(NFILES), wb, sprintf('%1d of %1d files collated', n, NFILES));
end

pause(1.0);
waitbar(double(n)/double(NFILES), wb, 'Collation complete !');
pause(1.0);

delete(wb);

%% Signal completion

h = msgbox('All done !', 'Success', 'modal');
uiwait(h);
delete(h);


  
  
  
  