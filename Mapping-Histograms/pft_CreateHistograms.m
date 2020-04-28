%% Clear the workspace

clear all
close all
clc

fclose('all');

%% Read in the location of some top-level folders for inputs and outputs

fid = fopen('Mapping-Folder.txt', 'rt');
MappingParentFolder = fgetl(fid);
fclose(fid);

fid = fopen('Segmentation-Folder.txt', 'rt');
SegmentationParentFolder = fgetl(fid);
fclose(fid);

fid = fopen('Histograms-Folder.txt', 'rt');
HistogramsParentFolder = fgetl(fid);
fclose(fid);

%% Prompt for a pickle file of perfusion maps

[ FileName, PathName, FilterIndex ] = pft_uigetfile('*.mat', 'Select a mapped pickle file', fullfile(MappingParentFolder, '*.mat'));

if (FilterIndex == 0)
  h = msgbox('No file selected', 'Quitting', 'modal');
  uiwait(h);
  delete(h);
  return;
end

PickleFileName = fullfile(PathName, FileName);

%% Prompt for the folder of left and right lung segmentations

SegmentationFolder = pft_uigetdir(SegmentationParentFolder, 'Select the segmentation folder');

if ~ischar(SegmentationFolder)
  h = msgbox('No folder selected', 'Quitting', 'modal');
  uiwait(h);
  delete(h);
  return;
end    

%% Create the output folder - give this the same "terminal" name as the segmentations folder

p = strfind(SegmentationFolder, filesep);
q = p(end);
r = q + 1;

Leaf = SegmentationFolder(r:end);

HistogramFolder = fullfile(HistogramsParentFolder, Leaf);

if (exist(HistogramFolder, 'dir') ~= 7)
  mkdir(HistogramFolder);
end

%% Load the data from the picke file and list the filed names

s = load(PickleFileName);

Dims = size(s.AllPBV);

FieldNames = fieldnames(s);

%% Load the binary masks - distinguish between the Mark 1 mapping and Hybrid cases, on the one hand, and Ingrisch on the other

RightFolder = fullfile(SegmentationFolder, 'Right Lung');
LinksFolder = fullfile(SegmentationFolder, 'Left Lung');

if any(strcmpi(FieldNames, 'AllIngrischMask'))
  ProcessedMask = s.AllIngrischMask;
else
  ProcessedMask = (s.AllTTP > 0);
end

RightBinaryMask = pft_ReadBinaryMaskStack(RightFolder, Dims);
LinksBinaryMask = pft_ReadBinaryMaskStack(LinksFolder, Dims);

TotalBinaryMask = RightBinaryMask | LinksBinaryMask;

%% Create 3 histograms together with a common y-limit for the PBV

Slope	  = 0.01;
Intercept =	0.0;

Edges = 0.5*(0:200)';

pbv = Intercept + Slope*double(s.AllPBV(RightBinaryMask & ProcessedMask));
[ NRight, Edges ] = histcounts(pbv, Edges);

pbv = Intercept + Slope*double(s.AllPBV(LinksBinaryMask & ProcessedMask));
[ NLinks, Edges ] = histcounts(pbv, Edges);

pbv = Intercept + Slope*double(s.AllPBV(TotalBinaryMask & ProcessedMask));
[ NTotal, Edges ] = histcounts(pbv, Edges);

NMax = max([max(NRight), max(NLinks), max(NTotal)]);
NMax = 5000.0*ceil(double(NMax)/5000.0);

XLabel = 'PBV [ml/100 ml]';
YLabel = 'Voxel Count';

Title = 'PBV: Right Lung';
OutputFileNameStub = 'PBV-Right';
pft_CreateOneHistogram(s.AllPBV, RightBinaryMask, ProcessedMask, Slope, Intercept, 100.0, NMax, 200, 'b', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'PBV: Left Lung';
OutputFileNameStub = 'PBV-Left';
pft_CreateOneHistogram(s.AllPBV, LinksBinaryMask, ProcessedMask, Slope, Intercept, 100.0, NMax, 200, 'r', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'PBV: Both Lungs';
OutputFileNameStub = 'PBV-Total';
pft_CreateOneHistogram(s.AllPBV, TotalBinaryMask, ProcessedMask, Slope, Intercept, 100.0, NMax, 200, 'm', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Eins = fullfile(HistogramFolder, 'PBV-Right.pdf');
Zwei = fullfile(HistogramFolder, 'PBV-Left.pdf');
Drei = fullfile(HistogramFolder, 'PBV-Total.pdf');

Vier = fullfile(HistogramFolder, 'PBV-Histograms.pdf');

if (exist(Vier, 'file') == 2)
  delete(Vier);
  pause(1.0);
end

copyfile(Eins, Vier);
pause(1.0);

append_pdfs(Vier, Zwei, Drei);

%% Create 3 histograms together with a common y-limit for the unfiltered PBV

Slope	  = 0.01;
Intercept =	0.0;

Edges = 0.5*(0:200)';

pbv = Intercept + Slope*double(s.UnfilteredAllPBV(RightBinaryMask & ProcessedMask));
[ NRight, Edges ] = histcounts(pbv, Edges);

pbv = Intercept + Slope*double(s.UnfilteredAllPBV(LinksBinaryMask & ProcessedMask));
[ NLinks, Edges ] = histcounts(pbv, Edges);

pbv = Intercept + Slope*double(s.UnfilteredAllPBV(TotalBinaryMask & ProcessedMask));
[ NTotal, Edges ] = histcounts(pbv, Edges);

NMax = max([max(NRight), max(NLinks), max(NTotal)]);
NMax = 5000.0*ceil(double(NMax)/5000.0);

XLabel = 'Unfiltered PBV [ml/100 ml]';
YLabel = 'Voxel Count';

Title = 'Unfiltered PBV: Right Lung';
OutputFileNameStub = 'Unfiltered-PBV-Right';
pft_CreateOneHistogram(s.UnfilteredAllPBV, RightBinaryMask, ProcessedMask, Slope, Intercept, 100.0, NMax, 200, 'b', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'Unfiltered PBV: Left Lung';
OutputFileNameStub = 'Unfiltered-PBV-Left';
pft_CreateOneHistogram(s.UnfilteredAllPBV, LinksBinaryMask, ProcessedMask, Slope, Intercept, 100.0, NMax, 200, 'r', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'Unfiltered PBV: Both Lungs';
OutputFileNameStub = 'Unfiltered-PBV-Total';
pft_CreateOneHistogram(s.UnfilteredAllPBV, TotalBinaryMask, ProcessedMask, Slope, Intercept, 100.0, NMax, 200, 'm', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Eins = fullfile(HistogramFolder, 'Unfiltered-PBV-Right.pdf');
Zwei = fullfile(HistogramFolder, 'Unfiltered-PBV-Left.pdf');
Drei = fullfile(HistogramFolder, 'Unfiltered-PBV-Total.pdf');

Vier = fullfile(HistogramFolder, 'Unfiltered-PBV-Histograms.pdf');

if (exist(Vier, 'file') == 2)
  delete(Vier);
  pause(1.0);
end

copyfile(Eins, Vier);
pause(1.0);

append_pdfs(Vier, Zwei, Drei);

%% Create 3 histograms together with a common y-limit for the PBF

Slope	  = 1.0;
Intercept =	0.0;

Edges = 5.0*(0:200)';

pbf = Intercept + Slope*double(s.AllPBF(RightBinaryMask & ProcessedMask));
[ NRight, Edges ] = histcounts(pbf, Edges);

pbf = Intercept + Slope*double(s.AllPBF(LinksBinaryMask & ProcessedMask));
[ NLinks, Edges ] = histcounts(pbf, Edges);

pbf = Intercept + Slope*double(s.AllPBF(TotalBinaryMask & ProcessedMask));
[ NTotal, Edges ] = histcounts(pbf, Edges);

NMax = max([max(NRight), max(NLinks), max(NTotal)]);
NMax = 5000.0*ceil(double(NMax)/5000.0);

XLabel = 'PBF [(ml/min)/100 ml]';
YLabel = 'Voxel Count';

Title = 'PBF: Right Lung';
OutputFileNameStub = 'PBF-Right';
pft_CreateOneHistogram(s.AllPBF, RightBinaryMask, ProcessedMask, Slope, Intercept, 1000.0, NMax, 200, 'b', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'PBF: Left Lung';
OutputFileNameStub = 'PBF-Left';
pft_CreateOneHistogram(s.AllPBF, LinksBinaryMask, ProcessedMask, Slope, Intercept, 1000.0, NMax, 200, 'r', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'PBF: Both Lungs';
OutputFileNameStub = 'PBF-Total';
pft_CreateOneHistogram(s.AllPBF, TotalBinaryMask, ProcessedMask, Slope, Intercept, 1000.0, NMax, 200, 'm', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Eins = fullfile(HistogramFolder, 'PBF-Right.pdf');
Zwei = fullfile(HistogramFolder, 'PBF-Left.pdf');
Drei = fullfile(HistogramFolder, 'PBF-Total.pdf');

Vier = fullfile(HistogramFolder, 'PBF-Histograms.pdf');

if (exist(Vier, 'file') == 2)
  delete(Vier);
  pause(1.0);
end

copyfile(Eins, Vier);
pause(1.0);

append_pdfs(Vier, Zwei, Drei);

%% Create 3 histograms together with a common y-limit for the unfiltered PBF - if it exists

if any(strcmpi(FieldNames, 'UnfilteredAllPBF'))
  Slope	  = 1.0;
  Intercept =	0.0;

  Edges = 5.0*(0:200)';

  pbf = Intercept + Slope*double(s.UnfilteredAllPBF(RightBinaryMask & ProcessedMask));
  [ NRight, Edges ] = histcounts(pbf, Edges);

  pbf = Intercept + Slope*double(s.UnfilteredAllPBF(LinksBinaryMask & ProcessedMask));
  [ NLinks, Edges ] = histcounts(pbf, Edges);

  pbf = Intercept + Slope*double(s.UnfilteredAllPBF(TotalBinaryMask & ProcessedMask));
  [ NTotal, Edges ] = histcounts(pbf, Edges);

  NMax = max([max(NRight), max(NLinks), max(NTotal)]);
  NMax = 5000.0*ceil(double(NMax)/5000.0);

  XLabel = 'Unfiltered PBF [(ml/min)/100 ml]';
  YLabel = 'Voxel Count';

  Title = 'Unfiltered PBF: Right Lung';
  OutputFileNameStub = 'Unfiltered-PBF-Right';
  pft_CreateOneHistogram(s.UnfilteredAllPBF, RightBinaryMask, ProcessedMask, Slope, Intercept, 1000.0, NMax, 200, 'b', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

  Title = 'Unfiltered PBF: Left Lung';
  OutputFileNameStub = 'Unfiltered-PBF-Left';
  pft_CreateOneHistogram(s.UnfilteredAllPBF, LinksBinaryMask, ProcessedMask, Slope, Intercept, 1000.0, NMax, 200, 'r', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

  Title = 'Unfiltered PBF: Both Lungs';
  OutputFileNameStub = 'Unfiltered-PBF-Total';
  pft_CreateOneHistogram(s.UnfilteredAllPBF, TotalBinaryMask, ProcessedMask, Slope, Intercept, 1000.0, NMax, 200, 'm', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

  Eins = fullfile(HistogramFolder, 'Unfiltered-PBF-Right.pdf');
  Zwei = fullfile(HistogramFolder, 'Unfiltered-PBF-Left.pdf');
  Drei = fullfile(HistogramFolder, 'Unfiltered-PBF-Total.pdf');

  Vier = fullfile(HistogramFolder, 'Unfiltered-PBF-Histograms.pdf');

  if (exist(Vier, 'file') == 2)
    delete(Vier);
    pause(1.0);
  end

  copyfile(Eins, Vier);
  pause(1.0);

  append_pdfs(Vier, Zwei, Drei);
end

%% Create 3 histograms together with a common y-limit for the MTT

Slope	  = 0.001;
Intercept =	- 10.0;

Edges = 0.1*(0:200)';

mtt = Intercept + Slope*double(s.AllMTT(RightBinaryMask & ProcessedMask));
[ NRight, Edges ] = histcounts(mtt, Edges);

mtt = Intercept + Slope*double(s.AllMTT(LinksBinaryMask & ProcessedMask));
[ NLinks, Edges ] = histcounts(mtt, Edges);

mtt = Intercept + Slope*double(s.AllMTT(TotalBinaryMask & ProcessedMask));
[ NTotal, Edges ] = histcounts(mtt, Edges);

NMax = max([max(NRight), max(NLinks), max(NTotal)]);
NMax = 5000.0*ceil(double(NMax)/5000.0);

XLabel = 'MTT [sec]';
YLabel = 'Voxel Count';

Title = 'MTT: Right Lung';
OutputFileNameStub = 'MTT-Right';
pft_CreateOneHistogram(s.AllMTT, RightBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 200, 'b', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'MTT: Left Lung';
OutputFileNameStub = 'MTT-Left';
pft_CreateOneHistogram(s.AllMTT, LinksBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 200, 'r', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'MTT: Both Lungs';
OutputFileNameStub = 'MTT-Total';
pft_CreateOneHistogram(s.AllMTT, TotalBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 200, 'm', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Eins = fullfile(HistogramFolder, 'MTT-Right.pdf');
Zwei = fullfile(HistogramFolder, 'MTT-Left.pdf');
Drei = fullfile(HistogramFolder, 'MTT-Total.pdf');

Vier = fullfile(HistogramFolder, 'MTT-Histograms.pdf');

if (exist(Vier, 'file') == 2)
  delete(Vier);
  pause(1.0);
end

copyfile(Eins, Vier);
pause(1.0);

append_pdfs(Vier, Zwei, Drei);

%% Create 3 histograms together with a common y-limit for the unfilteredd MTT - if it exists

if any(strcmpi(FieldNames, 'UnfilteredAllMTT'))
  Slope	    = 0.001;
  Intercept = - 10.0;

  Edges = 0.1*(0:200)';

  mtt = Intercept + Slope*double(s.UnfilteredAllMTT(RightBinaryMask & ProcessedMask));
  [ NRight, Edges ] = histcounts(mtt, Edges);

  mtt = Intercept + Slope*double(s.UnfilteredAllMTT(LinksBinaryMask & ProcessedMask));
  [ NLinks, Edges ] = histcounts(mtt, Edges);

  mtt = Intercept + Slope*double(s.UnfilteredAllMTT(TotalBinaryMask & ProcessedMask));
  [ NTotal, Edges ] = histcounts(mtt, Edges);

  NMax = max([max(NRight), max(NLinks), max(NTotal)]);
  NMax = 5000.0*ceil(double(NMax)/5000.0);

  XLabel = 'Unfiltered MTT [sec]';
  YLabel = 'Voxel Count';

  Title = 'Unfiltered MTT: Right Lung';
  OutputFileNameStub = 'Unfiltered-MTT-Right';
  pft_CreateOneHistogram(s.UnfilteredAllMTT, RightBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 200, 'b', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

  Title = 'Unfiltered MTT: Left Lung';
  OutputFileNameStub = 'Unfiltered-MTT-Left';
  pft_CreateOneHistogram(s.UnfilteredAllMTT, LinksBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 200, 'r', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

  Title = 'Unfiltered MTT: Both Lungs';
  OutputFileNameStub = 'Unfiltered-MTT-Total';
  pft_CreateOneHistogram(s.UnfilteredAllMTT, TotalBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 200, 'm', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

  Eins = fullfile(HistogramFolder, 'Unfiltered-MTT-Right.pdf');
  Zwei = fullfile(HistogramFolder, 'Unfiltered-MTT-Left.pdf');
  Drei = fullfile(HistogramFolder, 'Unfiltered-MTT-Total.pdf');

  Vier = fullfile(HistogramFolder, 'Unfiltered-MTT-Histograms.pdf');

  if (exist(Vier, 'file') == 2)
    delete(Vier);
    pause(1.0);
  end

  copyfile(Eins, Vier);
  pause(1.0);

  append_pdfs(Vier, Zwei, Drei);
end

%% Create 3 histograms together with a common y-limit for the TTP

Slope	  = 0.001;
Intercept =	- 10.0;

Edges = 0.2*(0:100)';

ttp = Intercept + Slope*double(s.AllTTP(RightBinaryMask & ProcessedMask));
[ NRight, Edges ] = histcounts(ttp, Edges);

ttp = Intercept + Slope*double(s.AllTTP(LinksBinaryMask & ProcessedMask));
[ NLinks, Edges ] = histcounts(ttp, Edges);

ttp = Intercept + Slope*double(s.AllTTP(TotalBinaryMask & ProcessedMask));
[ NTotal, Edges ] = histcounts(ttp, Edges);

NMax = max([max(NRight), max(NLinks), max(NTotal)]);
NMax = 5000.0*ceil(double(NMax)/5000.0);

XLabel = 'TTP [sec]';
YLabel = 'Voxel Count';

Title = 'TTP: Right Lung';
OutputFileNameStub = 'TTP-Right';
pft_CreateOneHistogram(s.AllTTP, RightBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 100, 'b', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'TTP: Left Lung';
OutputFileNameStub = 'TTP-Left';
pft_CreateOneHistogram(s.AllTTP, LinksBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 100, 'r', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Title = 'TTP: Both Lungs';
OutputFileNameStub = 'TTP-Total';
pft_CreateOneHistogram(s.AllTTP, TotalBinaryMask, ProcessedMask, Slope, Intercept, 20.0, NMax, 100, 'm', XLabel, YLabel, Title, HistogramFolder, OutputFileNameStub);

Eins = fullfile(HistogramFolder, 'TTP-Right.pdf');
Zwei = fullfile(HistogramFolder, 'TTP-Left.pdf');
Drei = fullfile(HistogramFolder, 'TTP-Total.pdf');

Vier = fullfile(HistogramFolder, 'TTP-Histograms.pdf');

if (exist(Vier, 'file') == 2)
  delete(Vier);
  pause(1.0);
end

copyfile(Eins, Vier);
pause(1.0);

append_pdfs(Vier, Zwei, Drei);

%% Combine the summary PDF files into one compilation

A = fullfile(HistogramFolder, 'PBV-Histograms.pdf');
B = fullfile(HistogramFolder, 'Unfiltered-PBV-Histograms.pdf');
C = fullfile(HistogramFolder, 'PBF-Histograms.pdf');
D = fullfile(HistogramFolder, 'Unfiltered-PBF-Histograms.pdf');
E = fullfile(HistogramFolder, 'MTT-Histograms.pdf');
F = fullfile(HistogramFolder, 'Unfiltered-MTT-Histograms.pdf');
G = fullfile(HistogramFolder, 'TTP-Histograms.pdf');

X = fullfile(HistogramFolder, 'All-Histograms.pdf');

if (exist(X, 'file') == 2)
  delete(X);
  pause(1.0);
end

copyfile(A, X);
pause(0.25);

append_pdfs(X, B, C);
pause(0.25);

if (exist(D, 'file') == 2)
  append_pdfs(X, D);
  pause(0.25);
end

append_pdfs(X, E);
pause(0.25);

if (exist(F, 'file') == 2)
  append_pdfs(X, F);
  pause(0.25);
end

append_pdfs(X, G);
pause(0.25);

Z = fullfile(HistogramFolder, sprintf('%s-All-Histograms.pdf', Leaf));

if (exist(Z, 'file') == 2)
  delete(Z);
  pause(1.0);
end

copyfile(X, Z);

%% Signal completion

h = msgbox('All done !', 'Success', 'modal');
uiwait(h);
delete(h);

