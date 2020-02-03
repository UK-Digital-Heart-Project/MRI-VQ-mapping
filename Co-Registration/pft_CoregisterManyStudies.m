%% Clear the workspace

clear all
close all
clc

fclose('all');

%% Read in the processing summary filenames and LUF's from the local XLSX sheet

[ Num, Txt, Raw ] = xlsread('Processing-Summary-File.xlsx', 'LUF');

Head = Raw(1, :);
Data = Raw(2:end, :);

Data = flip(Data, 1);

FileNames = Data(:, 1);
LUF       = cell2mat(Data(:, 2));

NFILES = numel(FileNames);

%% Co-register the original pickle files automatically

for n = 1:NFILES
  p = strfind(FileNames{n}, '_MAPPING');
  q = p(end);
  r = q - 1;
  
  FileNameStub = FileNames{n}(1:r);
  
  PickleFileName = sprintf('%s.mat', FileNameStub);
  
  pft_MultiModalCoregisterOnePickleFileAutomatically(PickleFileName, LUF(n));
end
