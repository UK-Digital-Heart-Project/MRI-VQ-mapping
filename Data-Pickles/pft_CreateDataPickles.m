%% Clear the workspace

clear all
close all
clc

fclose('all');

%% Point to the project data folder

fid = fopen('Top-Level-Folder.txt', 'rt');
TopLevelFolder = fgetl(fid);
fclose(fid);

%% Select one or more study folders from underneath

SubFolders = uigetfile_n_dir(TopLevelFolder, 'Select study folders to pickle');

if isempty(SubFolders)
  h = msgbox('No folders selected', 'Exit', 'modal');
  uiwait(h);
  delete(h);
  return;
end

NFOLDERS = numel(SubFolders);

%% Create data pickles for each study

for n = 1:NFOLDERS
  Path = SubFolders{n};
  
  [ CineStack, AT, Head ] = pft_ReadTwistCineStack(Path);
  
  if isempty(CineStack) || isempty(AT) || isempty(Head)
    continue;
  end
  
  [ NR, NC, NP, NE ] = size(CineStack);
  
  CineStackX1 = single(CineStack);
  
  CineStackX2 = zeros([round(NR/2), round(NC/2), round(NP/2), NE], 'single');
  
  for e = 1:NE
    CineStackX2(:, :, :, e) = imresize3(CineStackX1(:, :, :, e), [round(NR/2), round(NC/2), round(NP/2)], 'Method', 'box');
  end
  
  CineStackX4 = zeros([round(NR/4), round(NC/4), round(NP/4), NE], 'single');
  
  for e = 1:NE
    CineStackX4(:, :, :, e) = imresize3(CineStackX2(:, :, :, e), [round(NR/4), round(NC/4), round(NP/4)], 'Method', 'box');
  end
  
  CineStackX8 = zeros([round(NR/8), round(NC/8), round(NP/8), NE], 'single');
  
  for e = 1:NE
    CineStackX8(:, :, :, e) = imresize3(CineStackX4(:, :, :, e), [round(NR/8), round(NC/8), round(NP/8)], 'Method', 'box');
  end
  
  p = strfind(SubFolders{n}, filesep);
  q = p(end);
  r = q + 1;
  
  Leaf = SubFolders{n}(r:end);
  
  p = strfind(Leaf, '_');
  
  PickleFileName = sprintf('%sTWIST.mat', Leaf(1:p));
  PicklePathName = fullfile(TopLevelFolder, PickleFileName);
  
  wb = waitbar(0.5, 'Saving pickle file - please wait ... ');
  
  save(PicklePathName, 'CineStackX1', 'CineStackX2', 'CineStackX4', 'CineStackX8', 'AT', 'Head');
  
  pause(0.5);
  waitbar(1.0, wb, 'Saving complete');
  pause(0.5);
  delete(wb);  
end  
  
  

