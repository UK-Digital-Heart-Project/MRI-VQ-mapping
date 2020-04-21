%% Clear the workspace as usual
clear all
close all
clc

fclose('all');

%% Fetch the path to the current user's Desktop
Username = getenv('Username');

StartPath = fullfile('C:', 'Users', Username, 'Desktop');

%% Prompt for the source folder
SourceFolder = uigetdir(StartPath, 'Data SOURCE folder');

if ~ischar(SourceFolder)
  h = msgbox('No source folder chosen', 'Quit', 'modal');
  uiwait(h);
  delete(h);
  return;
end

%% Prompt for the target folder
TargetFolder = uigetdir(StartPath, 'Results TARGET folder');

if ~ischar(TargetFolder)
  h = msgbox('No target folder chosen', 'Quit', 'modal');
  uiwait(h);
  delete(h);
  return;
end

%% Write out the paths to the data and results
fid = fopen('Source-Folder.txt', 'wt');
fprintf(fid, '%s', SourceFolder);
fclose(fid);

fid = fopen('Target-Folder.txt', 'wt');
fprintf(fid, '%s', TargetFolder);
fclose(fid);

%% Signal success
h = msgbox('Success !', 'Done', 'modal');
uiwait(h);
delete(h);




