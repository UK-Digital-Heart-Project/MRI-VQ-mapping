%% Clear the workspace

clear all
close all
clc

fclose('all');

%% Fetch the location of the Histograms folder

fid = fopen('Histograms-Folder.txt');
HistogramsFolder = fgetl(fid);
fclose(fid);

%% Point to the images to be combined and create a montage, to be saved in a file with an informative name

SourceFolder = pft_uigetdir(HistogramsFolder, 'Select a histograms folder');

if ~ischar(SourceFolder)
  h = msgbox('No folder chosen', 'Quitting', 'modal');
  uiwait(h);
  delete(h);
  return;
end

p = strfind(SourceFolder, filesep);
q = p(end);
r = q + 1;

Leaf = SourceFolder(r:end);
A = imread(fullfile(SourceFolder, 'MTT-Right.png'));
B = imread(fullfile(SourceFolder, 'MTT-Left.png'));
C = imread(fullfile(SourceFolder, 'MTT-Total.png'));

A = rot90(A, 3);
B = rot90(B, 3);
C = rot90(C, 3);

W = cat(1, A, B, C);

D = imread(fullfile(SourceFolder, 'PBV-Right.png'));
E = imread(fullfile(SourceFolder, 'PBV-Left.png'));
F = imread(fullfile(SourceFolder, 'PBV-Total.png'));

D = rot90(D, 3);
E = rot90(E, 3);
F = rot90(F, 3);

X = cat(1, D, E, F);

P = imread(fullfile(SourceFolder, 'PBF-Right.png'));
Q = imread(fullfile(SourceFolder, 'PBF-Left.png'));
R = imread(fullfile(SourceFolder, 'PBF-Total.png'));

P = rot90(P, 3);
Q = rot90(Q, 3);
R = rot90(R, 3);

Y = cat(1, P, Q, R);

S = imread(fullfile(SourceFolder, 'TTP-Right.png'));
T = imread(fullfile(SourceFolder, 'TTP-Left.png'));
U = imread(fullfile(SourceFolder, 'TTP-Total.png'));

S = rot90(S, 3);
T = rot90(T, 3);
U = rot90(U, 3);

Z = cat(1, S, T, U);

Montage = cat(2, W, X, Y, Z);

%% Show the result and save it

iptsetpref('ImshowBorder', 'tight');

f = figure('Name', 'Montage - Transposed', 'MenuBar', 'none', 'NumberTitle', 'off');
a = axes(f);

imshow(Montage);

OutputFileName = sprintf('Histograms-Montage-Transposed-%s.png', Leaf);

imwrite(Montage, OutputFileName);

pause(2.0);

delete(a);
delete(f);





