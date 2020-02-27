function pft_CreateOneHistogram(Map, SegmentedMask, ProcessedMask, Slope, Intercept, XMax, NMax, NBins, FaceColor, XLabel, YLabel, Title, Folder, OutputFileNameStub)

% Scale the data from uint16 to doubles
Map = Intercept + Slope*double(Map);

% Set the horizontal range
Width = XMax/NBins;
Edges = Width*(0:NBins);    

% Define the mask - include the voxels that were both processed and manually segmented
TotalMask = SegmentedMask & ProcessedMask;

% Create and format the histogram
f = figure('Name', 'Title', 'MenuBar', 'none', 'NumberTitle', 'off');
a = axes(f);

histogram(Map(TotalMask), Edges, 'EdgeColor', 'k', 'FaceColor', FaceColor);

xlim([0.0, XMax]);
ylim([0.0, NMax]);

xlabel(XLabel, 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(YLabel, 'Interpreter', 'none', 'FontWeight', 'bold');
title(Title, 'Interpreter', 'none', 'FontWeight', 'bold');

pft_FormatLandscapePrinting(f, a);

pft_ExportGraphsInSeveralFormats(f, Folder, OutputFileNameStub);

delete(a);
delete(f);

end






