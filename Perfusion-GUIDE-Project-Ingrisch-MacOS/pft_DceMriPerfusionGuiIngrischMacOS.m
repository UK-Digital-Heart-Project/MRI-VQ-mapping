function varargout = pft_DceMriPerfusionGuiIngrischMacOS(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pft_DceMriPerfusionGuiIngrischMacOS_OpeningFcn, ...
                   'gui_OutputFcn',  @pft_DceMriPerfusionGuiIngrischMacOS_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pft_DceMriPerfusionGuiIngrischMacOS_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for pft_DceMriPerfusionGuiIngrischMacOS
handles.output = hObject;

% Initialise the image display
handles.Data = zeros([176, 176], 'uint8');

handles.Lower = 0;
handles.Upper = 255.0;

handles.Ceiling = 15.0;
handles.Floor   = 0.0;

handles.Mini = handles.Upper*(handles.Floor/100.0);
handles.Maxi = handles.Upper*(handles.Ceiling/100.0);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);
set(handles.hImage, 'HitTest', 'off', 'PickableParts', 'none');
colormap(handles.ImageDisplayAxes, gray(256));

% Initialise the data source folder and the results folder
fid = fopen('Source-Folder.txt', 'rt');
handles.SourceFolder = fgetl(fid);
fclose(fid);

fid = fopen('Target-Folder.txt', 'rt');
handles.TargetFolder = fgetl(fid);
fclose(fid);

MacOSIngrischMappingFolder = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Mapping');

if (exist(MacOSIngrischMappingFolder, 'dir') ~= 7)
  mkdir(MacOSIngrischMappingFolder);
end

MacOSScreenshotsFolder = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots');

if (exist(MacOSScreenshotsFolder, 'dir') ~= 7)
  mkdir(MacOSScreenshotsFolder);
end

% Disable some features which apply only to a genuine data set (not the initial blank placeholder)
handles.ReviewImageIsPresent = false;

% Set the downsampling factor to x1 to read in images at their original size by default
handles.Reduction = 1;

% Set limits for the cursor to find the image axes as the mouse is moved around
handles.NROWS = 176;
handles.NCOLS = 176;

handles.MinX = 0.5;
handles.MaxX = double(handles.NCOLS + 0.5);
handles.MinY = 0.5;
handles.MaxY = double(handles.NROWS + 0.5);

text(8, 8, 'No data loaded', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');

% Set the number of Slices and Epochs to expected values to allow for parameter changes before any images are loaded
handles.NSLICES = 112;
handles.NEPOCHS = 17;

% Initialise some important display variables
handles.Ceiling = 15.0;
handles.Floor   = 0.0;
handles.Epoch   = 1;
handles.Slice   = 56;

handles.RoiSlice = handles.Slice;

handles.FirstUsableFrame = 2;
handles.LastUsableFrame  = 17;

% Set the slider steps
set(handles.DisplayCeilingSlider, 'SliderStep', [1.0, 10.0]/95.0);
set(handles.DisplayFloorSlider, 'SliderStep', [1.0, 10.0]/95.0);
set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 8.0]/111.0);
set(handles.DisplayEpochSlider, 'SliderStep', [1.0, 4.0]/16.0);

set(handles.LastUsableFrameSlider, 'SliderStep', [1.0, 2.0]/12.0);

% Calculate slice locations from typical expected values, anticipating the import of the first real data set (with unknown downsampling)
NP = 112;

handles.ZOx1 = - 96.5;
handles.DZx1 = 1.5;
handles.SLx1 = handles.ZOx1 + handles.DZx1*double(0:NP-1);

NP = 56;

handles.ZOx2 = handles.ZOx1 + 0.5*handles.DZx1;
handles.DZx2 = 2.0*handles.DZx1;
handles.SLx2 = handles.ZOx2 + handles.DZx2*double(0:NP-1);

NP = 28;

handles.ZOx4 = handles.ZOx1 + 1.5*handles.DZx1;
handles.DZx4 = 4.0*handles.DZx1;
handles.SLx4 = handles.ZOx4 + handles.DZx4*double(0:NP-1);

NP = 14;

handles.ZOx8 = handles.ZOx1 + 3.5*handles.DZx1;
handles.DZx8 = 8.0*handles.DZx1;
handles.SLx8 = handles.ZOx8 + handles.DZx8*double(0:NP-1);

% Initialise a notional "current" slice location
handles.CurrentSliceLocation = handles.SLx1(handles.Slice);

% Initialize the choice and size of colormap
fid = fopen('Colormaps.txt', 'rt');
Strings = textscan(fid, '%s');
fclose(fid);

handles.MatlabLutNames = Strings{1};

S = load('FijiLuts.mat');

handles.FijiLutNames = cellfun(@(c) c.FijiLutName, S.Pickle, 'UniformOutput', false);
handles.FijiLuts     = cellfun(@(c) c.CM, S.Pickle, 'UniformOutput', false);

handles.ColormapNames = vertcat(handles.MatlabLutNames, handles.FijiLutNames);
set(handles.ColormapListBox, 'String', handles.ColormapNames);
M = find(strcmpi(handles.ColormapNames, 'hot'), 1, 'first');
set(handles.ColormapListBox, 'Value', M);

handles.ColormapSizes = { '8', '16', '32', '64', '128', '256' };
set(handles.ColormapSizeListBox, 'String', handles.ColormapSizes);
N = find(strcmpi(handles.ColormapSizes, '256'), 1, 'first');
set(handles.ColormapSizeListBox, 'Value', N);

handles.CurrentColormapName = 'hot';
handles.CurrentColormapSize = '256';
handles.Colormap            = hot(256);

% Centre the display
ScreenSize = get(0, 'ScreenSize');
FigureSize = get(hObject, 'Position');

WD = ScreenSize(3);
HT = ScreenSize(4);

wd = FigureSize(3);
ht = FigureSize(4);

FigureSize(1) = (WD - wd)/2;
FigureSize(2) = (HT - ht)/2;

set(hObject, 'Position', FigureSize);

% Add listeners for a continuous slider response
hDisplayCeilingSliderListener = addlistener(handles.DisplayCeilingSlider, 'ContinuousValueChange', @CB_DisplayCeilingSlider_Listener);
setappdata(handles.DisplayCeilingSlider, 'MyListener', hDisplayCeilingSliderListener);

hDisplayFloorSliderListener = addlistener(handles.DisplayFloorSlider, 'ContinuousValueChange', @CB_DisplayFloorSlider_Listener);
setappdata(handles.DisplayFloorSlider, 'MyListener', hDisplayFloorSliderListener);

hDisplayEpochSliderListener = addlistener(handles.DisplayEpochSlider, 'ContinuousValueChange', @CB_DisplayEpochSlider_Listener);
setappdata(handles.DisplayEpochSlider, 'MyListener', hDisplayEpochSliderListener);

hDisplaySliceSliderListener = addlistener(handles.DisplaySliceSlider, 'ContinuousValueChange', @CB_DisplaySliceSlider_Listener);
setappdata(handles.DisplaySliceSlider, 'MyListener', hDisplaySliceSliderListener);

hLastUsableFrameSliderListener = addlistener(handles.LastUsableFrameSlider, 'ContinuousValueChange', @CB_LastUsableFrameSlider_Listener);
setappdata(handles.LastUsableFrameSlider, 'MyListener', hLastUsableFrameSliderListener);

hRetainSvsSliderListener = addlistener(handles.RetainSvsSlider, 'ContinuousValueChange', @CB_RetainSvsSlider_Listener);
setappdata(handles.RetainSvsSlider, 'MyListener', hRetainSvsSliderListener);

hApodisationSliderListener = addlistener(handles.ApodisationSlider, 'ContinuousValueChange', @CB_ApodisationSlider_Listener);
setappdata(handles.ApodisationSlider, 'MyListener', hApodisationSliderListener);

% Initialise some plots in the time-course and SVD axes - then use the XData and YData properties to update the graphs
DummyX = (1:17)';
DummyY = zeros([17, 1], 'double');
DummyZ = DummyY + 150.0;
DummyA = DummyY + 300.0;
DummyB = DummyY + 450.0;

hold(handles.AifAxes, 'on');
hold(handles.TimeCourseAxes, 'on');
hold(handles.DeconvolvedTimeCourseAxes, 'on');

handles.hPlotAifFirstUsableFrame = plot(handles.AifAxes, [DummyX(2), DummyX(2)], [-2048, 2048], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);
handles.hPlotAifLastUsableFrame  = plot(handles.AifAxes, [DummyX(end), DummyX(end)], [-2048, 2048], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);
handles.hPlotAifXAxis            = plot(handles.AifAxes, [-100.0, 100.0], [0.0, 0.0], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);

handles.hPlotAifPeak = plot(handles.AifAxes, DummyX, DummyB, '-go', 'LineWidth', 1.0);
handles.hPlotFilteredAifPeak = plot(handles.AifAxes, DummyX, DummyA, '-o', 'Color', [0.0 1.0 1.0], 'LineWidth', 1.0);
handles.hPlotAifMean = plot(handles.AifAxes, DummyX, DummyZ, '-ro', 'LineWidth', 1.0);
handles.hPlotFilteredAifMean = plot(handles.AifAxes, DummyX, DummyY, '-o', 'Color', [1.0 0.5 0.0], 'LineWidth', 1.0);

pl = legend([handles.hPlotAifPeak, handles.hPlotFilteredAifPeak, handles.hPlotAifMean, handles.hPlotFilteredAifMean], ...
             { 'AIF Peak', 'Truncated/Filtered', 'AIF Mean', 'Truncated/Filtered' }, 'Location', 'NorthWest', 'FontSize', 12, 'Orientation', 'vertical');
set(pl, 'Box', 'off');

handles.hPlotTimeCourseFirstUsableFrame = plot(handles.TimeCourseAxes, [DummyX(2), DummyX(2)], [-2048, 2048], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);
handles.hPlotTimeCourseLastUsableFrame  = plot(handles.TimeCourseAxes, [DummyX(end), DummyX(end)], [-2048, 2048], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);
handles.hPlotTimeCourseXAxis            = plot(handles.TimeCourseAxes, [-100.0, 100.0], [0.0, 0.0], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);

handles.hPlotTimeCourse = plot(handles.TimeCourseAxes, DummyX, DummyZ, '-mo', 'LineWidth', 1.0);
handles.hPlotFilteredTimeCourse = plot(handles.TimeCourseAxes, DummyX, DummyY, '-o', 'Color', [150.0 75.0 0.0]/256.0, 'LineWidth', 1.0);

pl = legend([handles.hPlotTimeCourse, handles.hPlotFilteredTimeCourse], { 'Signal Time-Course', 'Truncated/Filtered' }, 'Location', 'NorthWest', 'FontSize', 12);
set(pl, 'Box', 'off');

handles.hPlotDeconvolvedTimeCourseFirstUsableFrame = plot(handles.DeconvolvedTimeCourseAxes, [DummyX(2), DummyX(2)], [-1.0, 1.0], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);
handles.hPlotDeconvolvedTimeCourseLastUsableFrame  = plot(handles.DeconvolvedTimeCourseAxes, [DummyX(end), DummyX(end)], [-1.0, 1.0], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);
handles.hPlotDeconvolvedTimeCourseXAxis            = plot(handles.DeconvolvedTimeCourseAxes, [-100.0, 100.0], [0.0, 0.0], '-', 'Color', [0.625 0.625 0.625], 'LineWidth', 1.0);

handles.hPlotDeconvolvedTimeCourse = plot(handles.DeconvolvedTimeCourseAxes, DummyX, DummyY, '-bo', 'LineWidth', 1.0);

pl = legend(handles.hPlotDeconvolvedTimeCourse, { 'Residue Function' }, 'Location', 'NorthWest', 'FontSize', 12);
set(pl, 'Box', 'off');

xlabel(handles.AifAxes, 'Sample');
xlabel(handles.TimeCourseAxes, 'Sample');
xlabel(handles.DeconvolvedTimeCourseAxes, 'Sample');

ylabel(handles.AifAxes, 'Grayscale');
ylabel(handles.TimeCourseAxes, 'Grayscale');
ylabel(handles.DeconvolvedTimeCourseAxes, 'Fraction');

set(handles.AifAxes, 'YLim', [-500, 2000]);
set(handles.TimeCourseAxes, 'YLim', [-500, 2000]);
set(handles.DeconvolvedTimeCourseAxes, 'YLim', [-0.25, 1.0]);

set(handles.AifAxes, 'XLim', [-6, 18]);
set(handles.TimeCourseAxes, 'XLim', [-6, 18]);
set(handles.DeconvolvedTimeCourseAxes, 'XLim', [-6, 18]);

handles.SvdCounts = (1:16)';
handles.SvdValues = repmat(1.0, [16, 1]);

handles.hPlotSV = semilogx(handles.SvdAxes, handles.SvdValues, handles.SvdCounts, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
set(handles.SvdAxes, 'XDir', 'reverse');
set(handles.SvdAxes, 'YDir', 'reverse');
set(handles.SvdAxes, 'YLim', [0.0, 20.0]);
xlabel(handles.SvdAxes, 'Value');
ylabel(handles.SvdAxes, 'Index');
hold(handles.SvdAxes, 'on');

% Initialise the singular-value display (and cut-off)
handles.RetainSvs = 16;
handles.SVCutoff  = 0.5;

xx = handles.SVCutoff;
yy = 20;

handles.hPlotSVCutoff = semilogx(handles.SvdAxes, [xx, xx], [0, yy], '-k', 'LineWidth', 1.0);

pl = legend([handles.hPlotSV, handles.hPlotSVCutoff], { 'Singular Values', 'Cut-Off' }, 'Location', 'SouthWest', 'FontSize', 12);
set(pl, 'Box', 'off');

% Initialise some parameters for the deconvolution
handles.Normalisation    = 'AIF Mean';
handles.MatrixAlgebra    = 'Explicit PINV (SVD)';
handles.Management       = 'Truncate';
handles.ZeroFill         = true;
handles.PlotFullSolution = true;

handles.CM = [];
handles.PM = [];

handles.DeconvolvedTimeCourse = [];

handles.Decades = 1.0;
handles.Filter  = pft_GaussianFilter(handles.LastUsableFrame - 1, handles.Decades);

% Set some parameters to control the on-the-fly image masking
handles.LowerCCThreshold = 30.00;
handles.UpperCCThreshold = 95.00;
handles.NAUCThreshold    = 5.00;

handles.InterpolationPrompt = 'Yes';

% Subtract the initial signal from the time-course by default
handles.SubtractInitialSignal = true;

% Enable data freezing
handles.FreezeDisplayOnClick = true;

% But the display is not frozen at present
handles.DisplayIsFrozen = false;

% Note that no MPA ROI has been created, and that none is being created at the moment
handles.MpaRoi       = [];
handles.MpaRoiExists = false;

handles.MpaRoiCreationInProgress = false;

% Also, that mapping isn't currently in progress
handles.MappingInProgress = false;

% Disable warnings about sheets being added to Excel files
warning('off', 'MATLAB:xlswrite:AddSheet'); 

% Update the HANDLES structure
guidata(hObject, handles);

% UIWAIT makes pft_DceMriPerfusionGuiIngrischMacOS wait for user response (see UIRESUME)
% uiwait(handles.DceMriPerfusionGuiMainFigure);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = pft_DceMriPerfusionGuiIngrischMacOS_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpenCineStackButton_Callback(hObject, eventdata, handles)

% Prompt for a MAT file - do nothing if none is chosen
[ FileName, PathName, FilterIndex ] = pft_uigetfile('*.mat', 'Select a perfusion MAT file', fullfile(handles.SourceFolder, '*mat'));

if (FilterIndex == 0)
  return;
end

handles.SourceFolder   = PathName;
handles.SourceFileName = FileName;

p = strfind(FileName, '.');
q = p(end);
r = q - 1;

handles.FileNameStub = FileName(1:r);

% Read in the CineStack, the Acquisition Times, and a common working Dicom header these are bundled in a structure called Mat, which is retained to save memory and time
wb = waitbar(0.5, 'Loading data - please wait ... ');

handles.Mat = [];
handles.Mat = load(fullfile(PathName, FileName));

pause(0.5);
waitbar(1.0, wb, 'Loading complete');
pause(0.5);
delete(wb);

% Select the cine-stack at the correct downsampling factor
switch handles.Reduction
  case 1
    handles.CineStack = handles.Mat.CineStackX1;
  case 2
    handles.CineStack = handles.Mat.CineStackX2;
  case 4
    handles.CineStack = handles.Mat.CineStackX4;
  case 8
    handles.CineStack = handles.Mat.CineStackX8;
end  

% Display the image size
Dims = size(handles.CineStack);

handles.NROWS   = Dims(1);
handles.NCOLS   = Dims(2);
handles.NSLICES = Dims(3);
handles.NEPOCHS = Dims(4);

set(handles.ImageSizeEdit, 'String', sprintf('  Size:   %1d / %1d / %1d', Dims(1), Dims(2), Dims(3)));
set(handles.ImageEpochsEdit, 'String', sprintf('  Epochs: %1d', Dims(4)));

handles.MinX = 0.5;
handles.MaxX = double(handles.NCOLS + 0.5);
handles.MinY = 0.5;
handles.MaxY = double(handles.NROWS + 0.5);

% Calculate slice locations from the common working header
[ NR, NC, NP, NE ] = size(handles.Mat.CineStackX1);

handles.ZOx1 = handles.Mat.Head.SliceLocation;
handles.DZx1 = handles.Mat.Head.SliceThickness;
handles.SLx1 = handles.ZOx1 + handles.DZx1*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.Mat.CineStackX2);

handles.ZOx2 = handles.ZOx1 + 0.5*handles.DZx1;
handles.DZx2 = 2.0*handles.DZx1;
handles.SLx2 = handles.ZOx2 + handles.DZx2*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.Mat.CineStackX4);

handles.ZOx4 = handles.ZOx1 + 1.5*handles.DZx1;
handles.DZx4 = 4.0*handles.DZx1;
handles.SLx4 = handles.ZOx4 + handles.DZx4*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.Mat.CineStackX8);

handles.ZOx8 = handles.ZOx1 + 3.5*handles.DZx1;
handles.DZx8 = 8.0*handles.DZx1;
handles.SLx8 = handles.ZOx8 + handles.DZx8*double(0:NP-1);

% Update the current slice to allow for possible downsampling
switch handles.Reduction
  case 1
    [ Value, Place ] = min(abs(handles.SLx1 - handles.CurrentSliceLocation));
  case 2
    [ Value, Place ] = min(abs(handles.SLx2 - handles.CurrentSliceLocation)); 
  case 4
    [ Value, Place ] = min(abs(handles.SLx4 - handles.CurrentSliceLocation));
  case 8
    [ Value, Place ] = min(abs(handles.SLx8 - handles.CurrentSliceLocation));
end

handles.Slice = Place;

switch handles.Reduction
  case 1
    handles.CurrentSliceLocation = handles.SLx1(handles.Slice);
  case 2
    handles.CurrentSliceLocation = handles.SLx2(handles.Slice); 
  case 4
    handles.CurrentSliceLocation = handles.SLx4(handles.Slice);
  case 8
    handles.CurrentSliceLocation = handles.SLx8(handles.Slice);
end    
    
% Update the slider settings if necessary
set(handles.DisplayCeilingSlider, 'Enable', 'on');
set(handles.DisplayFloorSlider, 'Enable', 'on');

set(handles.DisplaySliceSlider, 'Enable', 'on');
set(handles.DisplaySliceSlider, 'Max', handles.NSLICES);

% This shouldn't happen - given the code immediately preceding - but it shouldn't do any harm
set(handles.DisplaySliceSlider, 'Enable', 'on');
set(handles.DisplaySliceSlider, 'Max', handles.NSLICES);

switch handles.Reduction
  case 1
    set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 8.0]/double(handles.NSLICES - 1));
  case 2
    set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 4.0]/double(handles.NSLICES - 1));
  case 4
    set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 2.0]/double(handles.NSLICES - 1));
  case 8
    set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 1.0]/double(handles.NSLICES - 1));
end

if (handles.Slice > handles.NSLICES)
  handles.Slice = handles.NSLICES; 
  set(handles.DisplaySliceSlider, 'Value', handles.NSLICES);
  set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));
  
  switch handles.Reduction
    case 1
      handles.CurrentSliceLocation = handles.SLx1(handles.Slice);
    case 2
      handles.CurrentSliceLocation = handles.SLx2(handles.Slice); 
    case 4
      handles.CurrentSliceLocation = handles.SLx4(handles.Slice);
    case 8
      handles.CurrentSliceLocation = handles.SLx8(handles.Slice);
  end   
end

% This is a necessary precaution between different data sets
set(handles.DisplayEpochSlider, 'Enable', 'on');
set(handles.DisplayEpochSlider, 'Max', handles.NEPOCHS);
set(handles.DisplayEpochSlider, 'SliderStep', [1.0, 4.0]/double(handles.NEPOCHS - 1));

if (handles.Epoch > handles.NEPOCHS)
  handles.Epoch = handles.NEPOCHS; 
  set(handles.DisplayEpochSlider, 'Value', handles.NEPOCHS);
  set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));
end

% Update the Slice and Epoch edit windows and their corresponding sliders
set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));
set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));

set(handles.DisplaySliceSlider, 'Value', handles.Slice);
set(handles.DisplayEpochSlider, 'Value', handles.Epoch);

% Display the current slice and epoch
handles.Lower = 0;
handles.Upper = max(handles.CineStack(:));

handles.Mini = handles.Upper*(handles.Floor/100.0);
handles.Maxi = handles.Upper*(handles.Ceiling/100.0);

handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch: %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Enable the screen capture button
set(handles.CaptureDisplayButton, 'Enable', 'on');

% Update the time axes on the 3 time-course graphs - the first image is the "baseline" acquisition, the second precedes the contrast injection
handles.Mat.AT = handles.Mat.AT - handles.Mat.AT(2);
handles.Mat.AT = handles.Mat.AT(:);

DT = handles.Mat.AT(3) - handles.Mat.AT(2);

handles.MiniAT = 5.0*floor(min(handles.Mat.AT)/5.0);
handles.MaxiAT = 5.0*ceil((2.0*handles.NEPOCHS - 1)*DT/5.0);

set(handles.AifAxes, 'XLim', [handles.MiniAT, handles.MaxiAT]);
set(handles.TimeCourseAxes, 'XLim', [handles.MiniAT, handles.MaxiAT]);
set(handles.DeconvolvedTimeCourseAxes, 'XLim', [handles.MiniAT, handles.MaxiAT]);

xlabel(handles.AifAxes, 'Time / Sec');
xlabel(handles.TimeCourseAxes, 'Time / Sec');
xlabel(handles.DeconvolvedTimeCourseAxes, 'Time / Sec');

set(handles.hPlotAifPeak, 'XData', handles.Mat.AT);
set(handles.hPlotFilteredAifPeak, 'XData', handles.Mat.AT);
set(handles.hPlotAifMean, 'XData', handles.Mat.AT);
set(handles.hPlotFilteredAifMean, 'XData', handles.Mat.AT);
set(handles.hPlotTimeCourse, 'XData', handles.Mat.AT);
set(handles.hPlotFilteredTimeCourse, 'XData', handles.Mat.AT);
set(handles.hPlotDeconvolvedTimeCourse, 'XData', handles.Mat.AT);

Deck = 100.0*floor(handles.Lower/100.0);
Roof = 500.0*ceil(handles.Upper/500.0);

set(handles.AifAxes, 'YLim', [Deck, Roof]);
set(handles.TimeCourseAxes, 'YLim', [Deck, Roof]);
set(handles.DeconvolvedTimeCourseAxes, 'YLim', [-0.25, 1.0]);

DummyY = zeros(size(handles.Mat.AT), 'double');
DummyY = DummyY(:);
DummyZ = DummyY + 150.0;
DummyA = DummyY + 300.0;
DummyB = DummyY + 450.0;

set(handles.hPlotAifPeak, 'YData', DummyB);
set(handles.hPlotFilteredAifPeak, 'YData', DummyA);
set(handles.hPlotAifMean, 'YData', DummyZ);
set(handles.hPlotFilteredAifMean, 'YData', DummyY);
set(handles.hPlotTimeCourse, 'YData', DummyZ);
set(handles.hPlotFilteredTimeCourse, 'YData', DummyY);
set(handles.hPlotDeconvolvedTimeCourse, 'YData', DummyY);

% Update the slider and edit window for the Last Usable Frame
set(handles.LastUsableFrameSlider, 'Enable', 'on');
set(handles.LastUsableFrameSlider, 'Max', handles.NEPOCHS);
set(handles.LastUsableFrameSlider, 'SliderStep', [1.0, 2.0]/double(handles.NEPOCHS - 5.0));

if (handles.LastUsableFrame > handles.NEPOCHS)
  handles.LastUsableFrame = handles.NEPOCHS;
  set(handles.LastUsableFrameEdit, 'String', sprintf('  Last Usable Frame: %1d', handles.LastUsableFrame));
  set(handles.LastUsableFrameSlider, 'Value', handles.LastUsableFrame); 
  
  handles.Filter = pft_GaussianFilter(handles.LastUsableFrame - 1, handles.Decades);
end  

set(handles.hPlotAifFirstUsableFrame, 'XData', [handles.Mat.AT(2), handles.Mat.AT(2)], 'YData', [-2048, 2048]);
set(handles.hPlotAifLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);
  
set(handles.hPlotTimeCourseFirstUsableFrame, 'XData', [handles.Mat.AT(2), handles.Mat.AT(2)], 'YData', [-2048, 2048]);
set(handles.hPlotTimeCourseLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);
  
set(handles.hPlotDeconvolvedTimeCourseFirstUsableFrame, 'XData', [handles.Mat.AT(2), handles.Mat.AT(2)], 'YData', [-1.0, 1.0]);
set(handles.hPlotDeconvolvedTimeCourseLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);

% Enable some interactivity with the displayed image
handles.ReviewImageIsPresent = true;

% Allow the image display axes to be captured
set(handles.CaptureDisplayButton, 'Enable', 'on');

% Enable initial signal subtraction in the time-couse plot
set(handles.SubtractInitialSignalCheck, 'Enable', 'on');

% Allow an ROI to be created within the MPA
set(handles.CreateMpaRoiButton, 'Enable', 'on');

% But note that no MPA ROI has been created
handles.MpaRoi       = [];
handles.MpaRoiExists = false;

% Enable zero-filling of the time-course, with or without prior creation of an MPA ROI
set(handles.ZeroFillCheck, 'Enable', 'on');

% Enable plotting of the "full" deconvolved solution in the case of extra zero-filling of the AIF
set(handles.PlotFullSolutionCheck, 'Enable', 'on');

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end  

% Re-set the convolution/deconvolution matrices to null and indicate the change in the SVD plot
handles.CM = [];
handles.PM = [];

handles.DeconvolvedTimeCourse = [];

if (handles.ZeroFill == true)
  samples = 2*(handles.LastUsableFrame - 1);
else
  samples = handles.LastUsableFrame - 1;
end
    
yy = (1:samples)';
xx = repmat(1.0, [samples, 1]);
        
set(handles.hPlotSV, 'XData', xx);
set(handles.hPlotSV, 'YData', yy);  
set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);  

% Disable the button to CREATE MAPS
set(handles.CreateMapsButton, 'Enable', 'off');

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpenCineStackButton_CreateFcn(hObject, eventdata, handles)

set(hObject, 'BackgroundColor', [0.6 1.0 0.6]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayCeilingSlider_Callback(hObject, eventdata, handles)

% Fetch the upper window value, rounded to 1 p.c.
handles.Ceiling = round(get(hObject, 'Value'));
set(handles.DisplayCeilingEdit, 'String', sprintf('  Ceiling: %3d %%', handles.Ceiling));

% Keep the lower window value under control
if (handles.Ceiling - handles.Floor <= 5)
  handles.Floor = handles.Ceiling - 5.0;
  set(handles.DisplayFloorSlider, 'Value', handles.Floor);
  set(handles.DisplayFloorEdit, 'String', sprintf('  Floor:   %3d %%', handles.Floor));
end

% Display the current slice and epoch
handles.Mini = handles.Upper*(handles.Floor/100.0);
handles.Maxi = handles.Upper*(handles.Ceiling/100.0);

handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_DisplayCeilingSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the upper window value, rounded to 1 p.c.
handles.Ceiling = round(get(hObject, 'Value'));
set(handles.DisplayCeilingEdit, 'String', sprintf('  Ceiling: %3d %%', handles.Ceiling));

% Keep the lower window value under control
if (handles.Ceiling - handles.Floor <= 5)
  handles.Floor = handles.Ceiling - 5.0;
  set(handles.DisplayFloorSlider, 'Value', handles.Floor);
  set(handles.DisplayFloorEdit, 'String', sprintf('  Floor:   %3d %%', handles.Floor));
end

% Display the current slice and epoch
handles.Mini = handles.Upper*(handles.Floor/100.0);
handles.Maxi = handles.Upper*(handles.Ceiling/100.0);

handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayCeilingSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayFloorSlider_Callback(hObject, eventdata, handles)

% Fetch the lower window value, rounded to 1 p.c.
handles.Floor = round(get(hObject, 'Value'));
set(handles.DisplayFloorEdit, 'String', sprintf('  Floor:   %3d %%', handles.Floor));

% Keep the upper window value under control
if (handles.Ceiling - handles.Floor <= 5)
  handles.Ceiling = handles.Floor + 5.0;
  set(handles.DisplayCeilingSlider, 'Value', handles.Ceiling);
  set(handles.DisplayCeilingEdit, 'String', sprintf('  Ceiling: %3d %%', handles.Ceiling));
end

% Display the current slice and epoch
handles.Mini = handles.Upper*(handles.Floor/100.0);
handles.Maxi = handles.Upper*(handles.Ceiling/100.0);

handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_DisplayFloorSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the lower window value, rounded to 1 p.c.
handles.Floor = round(get(hObject, 'Value'));
set(handles.DisplayFloorEdit, 'String', sprintf('  Floor:   %3d %%', handles.Floor));

% Keep the upper window value under control
if (handles.Ceiling - handles.Floor <= 5)
  handles.Ceiling = handles.Floor + 5.0;
  set(handles.DisplayCeilingSlider, 'Value', handles.Ceiling);
  set(handles.DisplayCeilingEdit, 'String', sprintf('  Ceiling: %3d %%', handles.Ceiling));
end

% Display the current slice and epoch
handles.Mini = handles.Upper*(handles.Floor/100.0);
handles.Maxi = handles.Upper*(handles.Ceiling/100.0);

handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayFloorSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayCeilingEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayCeilingEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayFloorEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayFloorEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayEpochEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayEpochEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplaySliceEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplaySliceEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageSizeEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageSizeEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayEpochSlider_Callback(hObject, eventdata, handles)

% Fetch the current epoch
handles.Epoch = round(get(hObject, 'Value'));
set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));

% Display the current slice and epoch
handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_DisplayEpochSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the current epoch
handles.Epoch = round(get(hObject, 'Value'));
set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));

% Display the current slice and epoch
handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayEpochSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageEpochsEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageEpochsEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplaySliceSlider_Callback(hObject, eventdata, handles)

% Fetch the current slice
handles.Slice = round(get(hObject, 'Value'));
set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));

% Display the current slice and epoch
handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Update the current slice location for a possible change of downsampling or the import of a new data set
switch handles.Reduction
  case 1
    handles.CurrentSliceLocation = handles.SLx1(handles.Slice);
  case 2
    handles.CurrentSliceLocation = handles.SLx2(handles.Slice); 
  case 4
    handles.CurrentSliceLocation = handles.SLx4(handles.Slice);
  case 8
    handles.CurrentSliceLocation = handles.SLx8(handles.Slice);
end   

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_DisplaySliceSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the current Epoch
handles.Slice = round(get(hObject, 'Value'));
set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));

% Display the current slice and epoch
handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Update the current slice location for a possible change of downsampling or the import of a new data set
switch handles.Reduction
  case 1
    handles.CurrentSliceLocation = handles.SLx1(handles.Slice);
  case 2
    handles.CurrentSliceLocation = handles.SLx2(handles.Slice); 
  case 4
    handles.CurrentSliceLocation = handles.SLx4(handles.Slice);
  case 8
    handles.CurrentSliceLocation = handles.SLx8(handles.Slice);
end   

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplaySliceSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FreezeDisplayOnClickCheck_Callback(hObject, eventdata, handles)

handles.FreezeDisplayOnClick = get(hObject, 'Value');

% Update the handles structure
guidata(hObject, handles);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

function UnfreezeDisplayButton_Callback(hObject, eventdata, handles)

handles.DisplayIsFrozen = false;

% Update the handles structure
guidata(hObject, handles);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageRowEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageRowEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageColumnEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageColumnEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImagePixelValueEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImagePixelValueEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ColormapListBox_Callback(hObject, eventdata, handles)

% Find the position of the colormap name in the list
V = get(hObject, 'Value');

handles.CurrentColormapName = handles.ColormapNames{V};

% Divide the search between the MATLAB standard and Fili colormaps - treat the VGA case specially
M = find(strcmpi(handles.MatlabLutNames, handles.CurrentColormapName), 1, 'first');

if ~isempty(M)
  if strcmpi(handles.CurrentColormapName, 'vga')
    handles.Colormap = vga; 
  else
    handles.Colormap = eval(sprintf('%s(%s)', handles.CurrentColormapName, handles.CurrentColormapSize));
  end
else
  N = find(strcmpi(handles.FijiLutNames, handles.CurrentColormapName), 1, 'first');
  handles.Colormap = handles.FijiLuts{N};
end

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Update the handles structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ColormapListBox_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ColormapSizeListBox_Callback(hObject, eventdata, handles)

% Find the position of the colormap size in the list
V = get(hObject, 'Value');

handles.CurrentColormapSize = handles.ColormapSizes{V};

% Divide the search between the MATLAB standard and Fili colormaps - treat the VGA case specially
M = find(strcmpi(handles.MatlabLutNames, handles.CurrentColormapName), 1, 'first');

if ~isempty(M)
  if strcmpi(handles.CurrentColormapName, 'vga')
    handles.Colormap = vga; 
  else
    handles.Colormap = eval(sprintf('%s(%s)', handles.CurrentColormapName, handles.CurrentColormapSize));
  end
else
  N = find(strcmpi(handles.FijiLutNames, handles.CurrentColormapName), 1, 'first');
  handles.Colormap = handles.FijiLuts{N};
end

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Update the handles structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ColormapSizeListBox_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note that for the mouse-move capture function below, asking for the current cursor position w.r.t. the image axes rather than the main figure %
% is the safest option, and avoids (a) image interpolation ("fit to size") and (b) tricky arithmetic to locate the cursor as being either in or %
% out.                                                                                                                                          %
% Co-ordinates returned are in the "metric" (x, y) convention, with y increasing from top to bottom; for an image with M rows and N columns,    %
% the top-left corner is at (0.5, 0.5), the centre of the first pixel is at (1.0, 1.0), whereas the bottom-right pixel is centred at (x, y) =   %
% (N, M), with its outermost corner at (x, y) = (N + 0.5, M + 0.5).                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DceMriPerfusionGuiMainFigure_WindowButtonMotionFcn(hObject, eventdata, handles)

% Do nothing if the display has been frozen
if (handles.DisplayIsFrozen == true)
  return;
end

% Quit if no review image is present - avoid processing during a possible hiatus between image selections
if (handles.ReviewImageIsPresent == false)
  return;
end

% Also, do nothing if an ROI is being created or if mapping is in progress
if (handles.MpaRoiCreationInProgress == true) || (handles.MappingInProgress == true);
  return;
end

% Fetch the current point w.r.t. the IMAGE AXES rather than the MAIN FIGURE
P = get(handles.ImageDisplayAxes, 'CurrentPoint');

cx = P(1, 1);
cy = P(1, 2);

% Quit and do nothing if the cursor is outside the currently displayed image - but be sure to set the cursor correctly
if (cx < handles.MinX) || (cx > handles.MaxX) || (cy < handles.MinY) || (cy > handles.MaxY)
  set(handles.DceMriPerfusionGuiMainFigure, 'Pointer', 'arrow');
  
  set(handles.ImageRowEdit, 'String', '  Row:');
  set(handles.ImageColumnEdit, 'String', '  Column:');
  
  set(handles.ImagePixelValueEdit, 'String', '  Pixel Value:');  
  
  handles.TC = zeros(size(handles.Mat.AT), 'double');
  
  set(handles.hPlotTimeCourse, 'YData', handles.TC);
  
  set(handles.TimeCourseAxes, 'YLim', [-25.0, 100.0]);
    
  guidata(hObject, handles);
  return;
end

% If the cursor is inside, change the shape from an arrow to crosshairs
set(handles.DceMriPerfusionGuiMainFigure, 'Pointer', 'crosshair');

% Report the cursor position and pixel value and update the time course plots
handles.PixelRow = ceil(cy - 0.5);
handles.PixelCol = ceil(cx - 0.5);

handles.PixelValue = handles.Data(handles.PixelRow, handles.PixelCol);

set(handles.ImageRowEdit, 'String', sprintf('  Row:    %1d', handles.PixelRow));
set(handles.ImageColumnEdit, 'String', sprintf('  Column: %1d', handles.PixelCol));

set(handles.ImagePixelValueEdit, 'String', sprintf('  Pixel Value: %.4f', handles.PixelValue));

% Plot the signal time-course at the current voxel
handles.TC = squeeze(handles.CineStack(handles.PixelRow, handles.PixelCol, handles.Slice, :));
handles.TC = handles.TC(:);

if (handles.SubtractInitialSignal == true)
  set(handles.hPlotTimeCourse, 'YData', handles.TC - handles.TC(1));
  
  MiniY = min(handles.TC - handles.TC(1));
  MaxiY = max(handles.TC - handles.TC(1));
else
  set(handles.hPlotTimeCourse, 'YData', handles.TC);
  
  MiniY = min(handles.TC);
  MaxiY = max(handles.TC);
end

MiniY = 25.0*floor(MiniY/25.0);
MaxiY = 100.0*ceil(MaxiY/100.0) + 25.0;

set(handles.TimeCourseAxes, 'YLim', [MiniY, MaxiY]);

% Also, the base-line subtracted, truncated and filtered version
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

set(handles.hPlotFilteredTimeCourse, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', tc);

% Exit if there is no AIF defined because no MPA ROI has been created
if (handles.MpaRoiExists == false)  
  guidata(hObject, handles);
  return;
end

% A time-course will have been created by the last mouse movement before the button press, so proceed to the deconvolution
M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DceMriPerfusionGuiMainFigure_WindowButtonDownFcn(hObject, eventdata, handles)

% Do nothing if the display has already been frozen, or if freezing has been disabled
if (handles.DisplayIsFrozen == true) || (handles.FreezeDisplayOnClick == false)
  return;
end

% Quit if no review image is present - avoid processing during a possible hiatus between image selections
if (handles.ReviewImageIsPresent == false)
  return;
end

% Also, do nothing if an ROI is being created or if mapping is in progress
if (handles.MpaRoiCreationInProgress == true) || (handles.MappingInProgress == true);
  return;
end

% Fetch the current point w.r.t. the IMAGE AXES rather than the MAIN FIGURE
P = get(handles.ImageDisplayAxes, 'CurrentPoint');

cx = P(1, 1);
cy = P(1, 2);

% Quit and do nothing if the cursor is outside the currently displayed image - but be sure to set the cursor correctly
if (cx < handles.MinX) || (cx > handles.MaxX) || (cy < handles.MinY) || (cy > handles.MaxY)
  set(handles.DceMriPerfusionGuiMainFigure, 'Pointer', 'arrow');  % Because the click is outside the image axes
  
  set(handles.ImageRowEdit, 'String', '  Row:');
  set(handles.ImageColumnEdit, 'String', '  Column:');
  
  set(handles.ImagePixelValueEdit, 'String', '  Pixel Value:');  
  
  handles.TC = zeros(size(handles.Mat.AT), 'double');
  
  set(handles.hPlotTimeCourse, 'YData', handles.TC);
  
  set(handles.TimeCourseAxes, 'YLim', [-25.0, 100.0]);
    
  guidata(hObject, handles);
  return;
else   
  handles.DisplayIsFrozen = true;
  set(handles.DceMriPerfusionGuiMainFigure, 'Pointer', 'arrow');  % Sic ! Because the display is being frozen and the crosshairs are not needed
end

% Report the cursor position and pixel value and update the time course plots
handles.PixelRow = ceil(cy - 0.5);
handles.PixelCol = ceil(cx - 0.5);

handles.PixelValue = handles.Data(handles.PixelRow, handles.PixelCol);

set(handles.ImageRowEdit, 'String', sprintf('  Row:    %1d', handles.PixelRow));
set(handles.ImageColumnEdit, 'String', sprintf('  Column: %1d', handles.PixelCol));

set(handles.ImagePixelValueEdit, 'String', sprintf('  Pixel Value: %.4f', handles.PixelValue));

% Plot the signal time-course at the current voxel
handles.TC = squeeze(handles.CineStack(handles.PixelRow, handles.PixelCol, handles.Slice, :));
handles.TC = handles.TC(:);

if (handles.SubtractInitialSignal == true)
  set(handles.hPlotTimeCourse, 'YData', handles.TC - handles.TC(1));
  
  MiniY = min(handles.TC - handles.TC(1));
  MaxiY = max(handles.TC - handles.TC(1));
else
  set(handles.hPlotTimeCourse, 'YData', handles.TC);
  
  MiniY = min(handles.TC);
  MaxiY = max(handles.TC);
end

MiniY = 25.0*floor(MiniY/25.0);
MaxiY = 100.0*ceil(MaxiY/100.0) + 25.0;

set(handles.TimeCourseAxes, 'YLim', [MiniY, MaxiY]);

% Also, the base-line subtracted, truncated and filtered version
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

set(handles.hPlotFilteredTimeCourse, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', tc);

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end 

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2);
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end        
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);         
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;   
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% A time-course will have been created by the last mouse movement before the button press, so proceed to the deconvolution
% LUF = handles.LastUsableFrame;
% 
% tc = handles.TC - handles.TC(1);
% tc = tc(2:LUF);
% tc = double(tc);
% tc = tc(:);
% tc = tc .* handles.Filter;

% A time-course will have been created by the last mouse movement before the button press, so proceed to the deconvolution
M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CreateMpaRoiButton_Callback(hObject, eventdata, handles)

% Disable graph updates while the ROI is being created
handles.MpaRoiCreationInProgress = true;

% Also, disable the downsampling options
set(handles.DownsamplingX1Radio, 'Enable', 'off');
set(handles.DownsamplingX2Radio, 'Enable', 'off');
set(handles.DownsamplingX4Radio, 'Enable', 'off');
set(handles.DownsamplingX8Radio, 'Enable', 'off');

% And the sliders
set(handles.DisplayCeilingSlider, 'Enable', 'off');
set(handles.DisplayFloorSlider, 'Enable', 'off');
set(handles.DisplaySliceSlider, 'Enable', 'off');
set(handles.DisplayEpochSlider, 'Enable', 'off');

set(handles.LastUsableFrameSlider, 'Enable', 'off');

% Next, the colormap controls
set(handles.ColormapListBox, 'Enable', 'off');
set(handles.ColormapSizeListBox, 'Enable', 'off');

% And some buttons and checkboxes
set(handles.OpenCineStackButton, 'Enable', 'off');
set(handles.FreezeDisplayOnClickCheck, 'Enable', 'off');
set(handles.UnfreezeDisplayButton, 'Enable', 'off');

set(handles.ZeroFillCheck, 'Enable', 'off');

set(handles.CreateMpaRoiButton, 'Enable', 'off');

set(handles.SubtractInitialSignalCheck, 'Enable', 'off');

set(handles.CaptureDisplayButton, 'Enable', 'off');

set(handles.PlotFullSolutionCheck, 'Enable', 'off');

% Also, the deconvolution controls
set(handles.PeakAIFRadio, 'Enable', 'off');
set(handles.MeanAIFRadio, 'Enable', 'off');

set(handles.LeftDivideRadio, 'Enable', 'off');
set(handles.ExplicitPseudoInverseRadio, 'Enable', 'off');

set(handles.TruncateRadio, 'Enable', 'off');
set(handles.RegulariseRadio, 'Enable', 'off');
set(handles.NoActionRadio, 'Enable', 'off');

set(handles.RetainSvsSlider, 'Enable', 'off');
set(handles.ApodisationSlider, 'Enable', 'off');

% Update the HANDLES structure to make the changes take effect, so that no action will be triggered in the Window-Motion callback
guidata(hObject, handles);

% Set an initial position for the circular ROI
WD = double(handles.NCOLS);
HT = double(handles.NROWS);

x0 = round(0.55*WD);
y0 = round(0.35*HT);

wd = round(0.06*WD);
ht = wd;

% Place the ellipse
Start = [ x0, y0, wd, ht ];

HE = imellipse(handles.ImageDisplayAxes, Start);

setResizable(HE, true);
setFixedAspectRatioMode(HE, true);
HE.Deletable = false;

Venue = wait(HE);

handles.MpaRoi       = createMask(HE);
handles.MpaRoiExists = true;

delete(HE);

% Calculate the "mean" and "peak" AIF and plot them
Section = handles.CineStack(:, :, handles.Slice, :);
Section = squeeze(Section);

Initial = handles.CineStack(:, :, handles.Slice, 1);
Initial = squeeze(Initial);

NE = handles.NEPOCHS;

for e = 1:NE
  Section(:, :, e) = Section(:, :, e) - Initial;
end

handles.AIFPeak = zeros([NE, 1], 'double');
handles.AIFMean = zeros([NE, 1], 'double');

for e = 1:NE
  Extract = Section(:, :, e); 
  Extract = squeeze(Extract);
  
  Partial = Extract(handles.MpaRoi);
  
  handles.AIFPeak(e) = max(Partial);
  handles.AIFMean(e) = mean(Partial);
end

set(handles.hPlotAifPeak, 'YData', handles.AIFPeak);
set(handles.hPlotAifMean, 'YData', handles.AIFMean);

FilteredAifPeak = handles.AIFPeak(2:handles.LastUsableFrame) .* handles.Filter;
set(handles.hPlotFilteredAifPeak, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifPeak);
FilteredAifMean = handles.AIFMean(2:handles.LastUsableFrame) .* handles.Filter;
set(handles.hPlotFilteredAifMean, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifMean);

MiniY = min(min(handles.AIFPeak), min(handles.AIFMean));
MaxiY = max(max(handles.AIFPeak), max(handles.AIFMean));

MiniY = 25.0*floor(MiniY/25.0);
MaxiY = 100.0*ceil(MaxiY/100.0) + 25.0;

set(handles.AifAxes, 'YLim', [MiniY, MaxiY]);

% Save the chosen slice to the HANDLES structure, since it may be needed elsewhere
handles.RoiSlice = handles.Slice;

% Re-enable graph updates
handles.MpaRoiCreationInProgress = false;

% Also, re-enable the downsampling options
set(handles.DownsamplingX1Radio, 'Enable', 'on');
set(handles.DownsamplingX2Radio, 'Enable', 'on');
set(handles.DownsamplingX4Radio, 'Enable', 'on');
set(handles.DownsamplingX8Radio, 'Enable', 'on');

% And the sliders
set(handles.DisplayCeilingSlider, 'Enable', 'on');
set(handles.DisplayFloorSlider, 'Enable', 'on');
set(handles.DisplaySliceSlider, 'Enable', 'on');
set(handles.DisplayEpochSlider, 'Enable', 'on');

set(handles.LastUsableFrameSlider, 'Enable', 'on');

% Next, the colormap controls
set(handles.ColormapListBox, 'Enable', 'on');
set(handles.ColormapSizeListBox, 'Enable', 'on');

% And some buttons and checkboxes
set(handles.OpenCineStackButton, 'Enable', 'on');
set(handles.FreezeDisplayOnClickCheck, 'Enable', 'on');
set(handles.UnfreezeDisplayButton, 'Enable', 'on');

set(handles.ZeroFillCheck, 'Enable', 'on');

set(handles.CreateMpaRoiButton, 'Enable', 'on');

set(handles.SubtractInitialSignalCheck, 'Enable', 'on');

set(handles.CaptureDisplayButton, 'Enable', 'on');

set(handles.PlotFullSolutionCheck, 'Enable', 'on');

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end        
      
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;    
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end   

% Re-enable the deconvolution controls (radio-buttons); the SVD cut-off slider has been treated separately
set(handles.PeakAIFRadio, 'Enable', 'on');
set(handles.MeanAIFRadio, 'Enable', 'on');

set(handles.LeftDivideRadio, 'Enable', 'on');
set(handles.ExplicitPseudoInverseRadio, 'Enable', 'on');

set(handles.TruncateRadio, 'Enable', 'on');
set(handles.RegulariseRadio, 'Enable', 'on');
set(handles.NoActionRadio, 'Enable', 'on');

set(handles.ApodisationSlider, 'Enable', 'on');

% Enable the button to CREATE MAPS
set(handles.CreateMapsButton, 'Enable', 'on');

% Quit if there is no time-course available to be de-convolved
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
end

% Otherwise, perform the de-convolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LastUsableFrameSlider_Callback(hObject, eventdata, handles)

% Fetch the value of the last usable frame from the slider and report it to the edit window
handles.LastUsableFrame = round(get(hObject, 'Value'));

set(handles.LastUsableFrameEdit, 'String', sprintf('  Last Usable Frame: %1d', handles.LastUsableFrame));

% Re-calculate the data filter
handles.Filter  = pft_GaussianFilter(handles.LastUsableFrame - 1, handles.Decades);

% Apply the delimiter in 3 sets of axes
set(handles.hPlotAifLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);
  
set(handles.hPlotTimeCourseLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);
  
set(handles.hPlotDeconvolvedTimeCourseLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end

% Update the truncated and filtered section of the AIF data
if (handles.MpaRoiExists == true)
  FilteredAifPeak = handles.AIFPeak(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredAifPeak, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifPeak);
  FilteredAifMean = handles.AIFMean(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredAifMean, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifMean);
end

% Update the truncated and filtered section of the time-course
if (handles.DisplayIsFrozen == true)
  tc = handles.TC - handles.TC(1);
  tc = tc(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredTimeCourse, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', tc);
end

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end 

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2);
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end        
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);         
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;   
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% Gather some data dimensions
LUF = handles.LastUsableFrame;
  M = LUF - 1;

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;  
else
  N = M;
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_LastUsableFrameSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the value of the last usable frame from the slider and report it to the edit window
handles.LastUsableFrame = round(get(hObject, 'Value'));

set(handles.LastUsableFrameEdit, 'String', sprintf('  Last Usable Frame: %1d', handles.LastUsableFrame));

% Re-calculate the data filter
handles.Filter  = pft_GaussianFilter(handles.LastUsableFrame - 1, handles.Decades);

% Apply the delimiter in 3 sets of axes
set(handles.hPlotAifLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);
  
set(handles.hPlotTimeCourseLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);
  
set(handles.hPlotDeconvolvedTimeCourseLastUsableFrame, 'XData', [handles.Mat.AT(handles.LastUsableFrame), handles.Mat.AT(handles.LastUsableFrame)], 'YData', [-2048, 2048]);

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end

% Update the truncated and filtered section of the AIF data
if (handles.MpaRoiExists == true)
  FilteredAifPeak = handles.AIFPeak(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredAifPeak, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifPeak);
  FilteredAifMean = handles.AIFMean(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredAifMean, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifMean);
end

% Update the truncated and filtered section of the time-course
if (handles.DisplayIsFrozen == true)
  tc = handles.TC - handles.TC(1);
  tc = tc(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredTimeCourse, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', tc);
end

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end 

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end 

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2);
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end        
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);         
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;   
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LastUsableFrameSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LastUsableFrameEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LastUsableFrameEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SubtractInitialSignalCheck_Callback(hObject, eventdata, handles)

handles.SubtractInitialSignal = get(hObject, 'Value');

% Quit if there is no image to display
if (handles.ReviewImageIsPresent == false)
  guidata(hObject, handles);
  return;
end

% Update the time-course plot if the display is frozen
if (handles.SubtractInitialSignal == true)
  set(handles.hPlotTimeCourse, 'YData', handles.TC - handles.TC(1));
  
  MiniY = min(handles.TC - handles.TC(1));
  MaxiY = max(handles.TC - handles.TC(1));
else
  set(handles.hPlotTimeCourse, 'YData', handles.TC);
  
  MiniY = min(handles.TC);
  MaxiY = max(handles.TC);
end

MiniY = 25.0*floor(MiniY/25.0);
MaxiY = 100.0*ceil(MaxiY/100.0) + 25.0;

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CaptureDisplayButton_Callback(hObject, eventdata, handles)

F = getframe(handles.ImageDisplayAxes);
X = F.cdata;

% Offer the option to save the screenshot as an image
Listing = dir(fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots', sprintf('%s_Cine-Stack_*.png', handles.FileNameStub)));
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries(Folders) = [];
Entries = sort(Entries);
Entries = Entries';

if isempty(Entries)
  Suffix = '001';  
    
  DefaultName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots', sprintf('%s_Cine-Stack_001.png', handles.FileNameStub));
else
  LastName = Entries{end};
  p = strfind(LastName, '_');
  q = p(end) + 1;
  r = strfind(LastName, '.');
  s = r(end) - 1;
  String = LastName(q:s);
  Number = str2num(String);
  Number = Number + 1;
  Suffix = sprintf('%03d', Number);
    
  DefaultName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots', sprintf('%s_Cine-Stack_%s.png', handles.FileNameStub, Suffix));
end

FilterSpec  = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots', '*.png');
DialogTitle = 'Save Screenshot As';

[ FileName, PathName, FilterIndex ] = pft_uiputfile(FilterSpec, DialogTitle, DefaultName);

if (FilterIndex ~= 0)
  wb = waitbar(0, 'Exporting axes ... ');  
    
  imwrite(X, fullfile(PathName, FileName));
  
  waitbar(0.16, wb, 'Exported 1 of 5 axes ... ');

  OldColor = get(handles.DceMriPerfusionGuiMainFigure, 'Color');
  NewColor = [1 1 1];

  set(handles.DceMriPerfusionGuiMainFigure, 'Color', NewColor);

  GraphFileName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots', sprintf('%s_AIF_%s.png', handles.FileNameStub, Suffix));
  export_fig(handles.AifAxes, GraphFileName, '-png');
  
  waitbar(0.32, wb, 'Exported 2 of 5 axes ... ');

  GraphFileName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots', sprintf('%s_Time-Course_%s.png', handles.FileNameStub, Suffix));
  export_fig(handles.TimeCourseAxes, GraphFileName, '-png');
  
  waitbar(0.48, wb, 'Exported 3 of 5 axes ... ');

  GraphFileName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots', sprintf('%s_Residue-Function_%s.png', handles.FileNameStub, Suffix));
  export_fig(handles.DeconvolvedTimeCourseAxes, GraphFileName, '-png');
  
  waitbar(0.64, wb, 'Exported 4 of 5 axes ... ');

  GraphFileName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Screenshots', sprintf('%s_SVD_%s.png', handles.FileNameStub, Suffix));
  export_fig(handles.SvdAxes, GraphFileName, '-png');
  
  waitbar(0.80, wb, 'Exported 5 of 5 axes ... ');
  
  pause(0.5);  
  waitbar(1.0, wb, 'Export complete');
  pause(0.5);
  delete(wb);  

  set(handles.DceMriPerfusionGuiMainFigure, 'Color', OldColor);

end

% Update the HANDLES structure - is this really necessary here, since "handles" is used in a read-only way here ? 
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ZeroFillCheck_Callback(hObject, eventdata, handles)

% Fetch the toggle value
handles.ZeroFill = get(hObject, 'Value');

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end 

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2);
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end        
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);         
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;   
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CreateMapsButton_Callback(hObject, eventdata, handles)

% First, offer to save the processing parameters in an XLSX file
Listing = dir(fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Mapping', sprintf('%s_INGRISCH_*.csv', handles.FileNameStub)));
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries(Folders) = [];
Entries = sort(Entries);
Entries = Entries';

if isempty(Entries)
  Suffix = '001';  
    
  DefaultName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Mapping', sprintf('%s_INGRISCH_001.csv', handles.FileNameStub));
else
  LastName = Entries{end};
  p = strfind(LastName, '_');
  q = p(end) + 1;
  r = strfind(LastName, '.');
  s = r(end) - 1;
  String = LastName(q:s);
  Number = str2num(String);
  Number = Number + 1;
  Suffix = sprintf('%03d', Number);
    
  DefaultName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Mapping', sprintf('%s_INGRISCH_%s.csv', handles.FileNameStub, Suffix));
end

FilterSpec  = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Mapping', '*.csv');
DialogTitle = 'Save Parameters In File';

[ FileName, PathName, FilterIndex ] = pft_uiputfile(FilterSpec, DialogTitle, DefaultName);

% Quit if no file has been selected
if (FilterIndex == 0)
  h = msgbox('No file selected', 'Quit', 'modal');
  uiwait(h);
  delete(h);
  
  guidata(hObject, handles);
  return;
end

% Prompt for the Ingrisch mapping thresholds
LowerCC = handles.LowerCCThreshold;
UpperCC = handles.UpperCCThreshold;
NAUC    = handles.NAUCThreshold;

[ LowerCC, UpperCC, NAUC ] = pft_GetIngrischMappingThresholds(LowerCC, UpperCC, NAUC);

handles.LowerCCThreshold = LowerCC;
handles.UpperCCThreshold = UpperCC;
handles.NAUCThreshold    = NAUC;

% Decide whether to interpolate around the Residue function peak for the PBF and TTP
Prompt = handles.InterpolationPrompt;

Answer = questdlg('Interpolate PBF and TTP values ?', 'Processing decision', 'Yes', 'No', Prompt);

switch Answer
  case 'Yes'
    Interpolate = true;
    handles.InterpolationPrompt = 'Yes';
  case { 'No', '' }
    Interpolate = false;
    handles.InterpolationPrompt = 'No';
end

% Save the processing parameters to a CSV file with multiple paragraphs
CsvSummaryFile = fopen(fullfile(PathName, FileName), 'wt');

% Save the processing parameters to an XLSX file with multiple sheets
wb = waitbar(0, 'Saving parameters - please wait ... ');  
    
Head = { 'Slice', 'Downsampling factor', 'Last usable frame' };
Data = [handles.RoiSlice, handles.Reduction, handles.LastUsableFrame];

fprintf(CsvSummaryFile, 'ROI\n\n');
fprintf(CsvSummaryFile, '%s,', Head{1:end-1});
fprintf(CsvSummaryFile, '%s\n', Head{end});
fprintf(CsvSummaryFile, '%2d,%2d,%2d\n', Data');
fprintf(CsvSummaryFile, '\n');

waitbar(0.2, wb, 'Saved section 1 of 4 ... ');
  
Head = { 'Epoch', 'Acquisition time /sec', 'Mean AIF', 'Peak AIF' };
Data = [(1:handles.NEPOCHS)', handles.Mat.AT, handles.AIFMean, handles.AIFPeak];

fprintf(CsvSummaryFile, 'AIF\n\n');
fprintf(CsvSummaryFile, '%s,', Head{1:end-1});
fprintf(CsvSummaryFile, '%s\n', Head{end});
fprintf(CsvSummaryFile, '%2d,%.4f,%.9f,%.9f\n', Data');
fprintf(CsvSummaryFile, '\n');

waitbar(0.4, wb, 'Saved section 2 of 4 ... ');
  
Head = { 'Normalisation', 'Matrix Algebra', 'SVD Management', 'Retained Singular Values', 'Zero-Fill Truncated AIF', ...
         'Lower CC Threshold: PC', 'Upper CC Threshold: PC', 'Normalized Area Threshold: PC', ...
         'PBF and TTP Interpolated', ...
         'Gaussian filter (decades)' };
  
if (handles.ZeroFill == true)
  ZF = 'Yes';
else
  ZF = 'No';
end
  
switch handles.MatrixAlgebra
  case 'Left-Division'
    RSV = sprintf('%1d (not relevant)', handles.RetainSvs);
  case 'Explicit PINV (SVD)'
    RSV = handles.RetainSvs;
end

if (Interpolate == true)
  UsePolyFit = 'Yes';
else
  UsePolyFit = 'No';
end
  
fprintf(CsvSummaryFile, 'Deconvolution\n\n');
fprintf(CsvSummaryFile, '%s,', Head{1:end-1});
fprintf(CsvSummaryFile, '%s\n', Head{end});
fprintf(CsvSummaryFile, '%s,%s,%s,%2d,%s,%.2f,%.2f,%.2f,%s,%.2f\n', handles.Normalisation, handles.MatrixAlgebra, handles.Management, RSV, ZF, LowerCC, UpperCC, NAUC, UsePolyFit, handles.Decades); 
fprintf(CsvSummaryFile, '\n');

waitbar(0.6, wb, 'Saved section 3 of 4 ... ');

Head = { 'Epoch', 'Acquisition time / sec', 'Filter' };
Data = [(2:handles.LastUsableFrame)', handles.Mat.AT(2:handles.LastUsableFrame), handles.Filter];

fprintf(CsvSummaryFile, 'Filtering\n\n');
fprintf(CsvSummaryFile, '%s,', Head{1:end-1});
fprintf(CsvSummaryFile, '%s\n', Head{end});
fprintf(CsvSummaryFile, '%2d,%.9f,%.9f\n', Data');
fprintf(CsvSummaryFile, '\n');

waitbar(0.8, wb, 'Saved section 4 of 4 ... ');

pause(0.5);  
waitbar(1.0, wb, 'Saving complete');
pause(0.5);
delete(wb);

fclose(CsvSummaryFile);

% Save the MPA ROI as a separate image
wb = waitbar(0.5, 'Saving MPA ROI - please wait ... ');

MpaRoiFileName = sprintf('%s_INGRISCH-MPA-ROI_%s.png', handles.FileNameStub, Suffix);
MpaRoiPathName = fullfile(handles.TargetFolder, 'MacOS-Ingrisch-Mapping', MpaRoiFileName);

imwrite(handles.MpaRoi, MpaRoiPathName);

pause(0.5);  
waitbar(1.0, wb, 'Saving complete');
pause(0.5);
delete(wb);

% Disable graph updates while the maps are being created
handles.MappingInProgress = true;

% Disable the downsampling options
set(handles.DownsamplingX1Radio, 'Enable', 'off');
set(handles.DownsamplingX2Radio, 'Enable', 'off');
set(handles.DownsamplingX4Radio, 'Enable', 'off');
set(handles.DownsamplingX8Radio, 'Enable', 'off');

% And the sliders
set(handles.DisplayCeilingSlider, 'Enable', 'off');
set(handles.DisplayFloorSlider, 'Enable', 'off');
set(handles.DisplaySliceSlider, 'Enable', 'off');
set(handles.DisplayEpochSlider, 'Enable', 'off');

set(handles.LastUsableFrameSlider, 'Enable', 'off');

% Next, the colormap controls
set(handles.ColormapListBox, 'Enable', 'off');
set(handles.ColormapSizeListBox, 'Enable', 'off');

% And some buttons and checkboxes
set(handles.OpenCineStackButton, 'Enable', 'off');
set(handles.FreezeDisplayOnClickCheck, 'Enable', 'off');
set(handles.UnfreezeDisplayButton, 'Enable', 'off');

set(handles.ZeroFillCheck, 'Enable', 'off');

set(handles.CreateMpaRoiButton, 'Enable', 'off');

set(handles.SubtractInitialSignalCheck, 'Enable', 'off');

set(handles.CaptureDisplayButton, 'Enable', 'off');

set(handles.PlotFullSolutionCheck, 'Enable', 'off');

set(handles.CreateMapsButton, 'Enable', 'off');

% Also, the deconvolution controls
set(handles.PeakAIFRadio, 'Enable', 'off');
set(handles.MeanAIFRadio, 'Enable', 'off');

set(handles.LeftDivideRadio, 'Enable', 'off');
set(handles.ExplicitPseudoInverseRadio, 'Enable', 'off');

set(handles.TruncateRadio, 'Enable', 'off');
set(handles.RegulariseRadio, 'Enable', 'off');
set(handles.NoActionRadio, 'Enable', 'off');

set(handles.RetainSvsSlider, 'Enable', 'off');

set(handles.ApodisationSlider, 'Enable', 'off');

% Update the HANDLES structure immediately to prevent mouse motion events from updating the graphs during the lengthy parameter mapping
guidata(hObject, handles);

% Create some folders (and further sub-folders) for the results
p = strfind(FileName, '.');
q = p(end);
r = q - 1;

ResultFolder = FileName(1:r);
mkdir(PathName, ResultFolder);

Container = fullfile(PathName, ResultFolder);
mkdir(Container, 'CC');
mkdir(Container, 'Unfiltered-CC');
mkdir(Container, 'PBV');
mkdir(Container, 'MTT');
mkdir(Container, 'PBF');
mkdir(Container, 'TTP'); 
mkdir(Container, 'Unfiltered-PBV');
mkdir(Container, 'Unfiltered-MTT');

% We need to know the slice locations
switch handles.Reduction
  case 1
    MappingSL = handles.SLx1;
    MappingST = handles.DZx1;
  case 2
    MappingSL = handles.SLx2;
    MappingST = handles.DZx2;
  case 4
    MappingSL = handles.SLx4;
    MappingST = handles.DZx4;
  case 8
    MappingSL = handles.SLx8;
    MappingST = handles.DZx8;
end     

% Initialise some useful constants outside of any loops - the appropriate matrices will already exist
LUF = handles.LastUsableFrame;
 DT = handles.Mat.AT(3) - handles.Mat.AT(2);
  M = LUF - 1;

% Approximate the acquisition times as being evenly sampled - which simplifies the calculations and is a good approximation to the truth
Times = DT*(0:M-1)';

% Use a local variable for the time-course to be deconvolved, avoiding the need for constant initialisation and zero-filling
MappingTC = zeros([M, 1], 'double');

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;     
  LargePads = zeros([M + N - 1, 1], 'double');
  MappingTC = vertcat(MappingTC, LargePads);
else
  SmallPads = zeros([M - 1, 1], 'double');
  MappingTC = vertcat(MappingTC, SmallPads);
end

% We need the AIF for some of the calculations
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

% Create a copy of the unfiltered AIF for later use in creating the Ingrisch mask
UnfilteredAIF = aif;

% Set the Ingrisch thresholds for the mapping in real units (rather than per cent)
LowerCC = 0.01*LowerCC;
UpperCC = 0.01*UpperCC;
NAUC    = 0.01*NAUC;

% Calculate the integral of the AIF using the trapezium rule (the factor of DT can be inserted later as needed) before filtering
UnfilteredAifIntegral = 0.5*(aif(1) + aif(M)) + sum(aif(2:M-1));

% Apply the apodisation
aif = aif .* handles.Filter;

% Calculate the integral of the AIF using the trapezium rule (the factor of DT can be inserted later as needed) after filtering
AifIntegral = 0.5*(aif(1) + aif(M)) + sum(aif(2:M-1));

% We will need a DICOM dictionary
Dictionary = dicomdict('get');

% Calculate the maps one slice at a time
wb = waitbar(0, 'Creating maps ... ');

AllCC  = zeros([handles.NROWS, handles.NCOLS, handles.NSLICES], 'uint16');

AllPBV = zeros([handles.NROWS, handles.NCOLS, handles.NSLICES], 'uint16');
AllPBF = zeros([handles.NROWS, handles.NCOLS, handles.NSLICES], 'uint16');
AllMTT = zeros([handles.NROWS, handles.NCOLS, handles.NSLICES], 'uint16');
AllTTP = zeros([handles.NROWS, handles.NCOLS, handles.NSLICES], 'uint16');

UnfilteredAllCC  = zeros([handles.NROWS, handles.NCOLS, handles.NSLICES], 'uint16');

UnfilteredAllPBV = zeros([handles.NROWS, handles.NCOLS, handles.NSLICES], 'uint16');
UnfilteredAllMTT = zeros([handles.NROWS, handles.NCOLS, handles.NSLICES], 'uint16');

AllIngrischMask = true([handles.NROWS, handles.NCOLS, handles.NSLICES]);

for s = 1:handles.NSLICES    
  CC  = zeros([handles.NROWS, handles.NCOLS], 'double');
    
  PBV = zeros([handles.NROWS, handles.NCOLS], 'double');
  PBF = zeros([handles.NROWS, handles.NCOLS], 'double');
  MTT = zeros([handles.NROWS, handles.NCOLS], 'double');
  TTP = zeros([handles.NROWS, handles.NCOLS], 'double');
  
  UnfilteredCC  = zeros([handles.NROWS, handles.NCOLS], 'double');
  
  UnfilteredPBV = zeros([handles.NROWS, handles.NCOLS], 'double');
  UnfilteredMTT = zeros([handles.NROWS, handles.NCOLS], 'double');
  
  IngrischMask = true([handles.NROWS, handles.NCOLS]);
  
  KeepMTT = true(handles.NROWS, handles.NCOLS);
  KeepTTP = true(handles.NROWS, handles.NCOLS);
  
  KeepUnfilteredMTT = true(handles.NROWS, handles.NCOLS);
    
  for c = 1:handles.NCOLS
      
    for r = 1:handles.NROWS
        
      tc = squeeze(handles.CineStack(r, c, s, :));
      tc = tc - tc(1);
      tc = tc(2:LUF);
      tc = double(tc);
      tc = tc(:);  
      
      UnfilteredCC(r, c) = corr(UnfilteredAIF, tc); 
      UnfilteredTCIntegral = 0.5*(tc(1) + tc(M)) + sum(tc(2:M-1));
      
      tc = tc .* handles.Filter;
      
      CC(r, c) = corr(aif, tc);
      TCIntegral = 0.5*(tc(1) + tc(M)) + sum(tc(2:M-1));
      
      NormalizedAreaUnderCurve = UnfilteredTCIntegral/UnfilteredAifIntegral;
      
      if (UnfilteredCC(r, c) < LowerCC) || (UnfilteredCC(r, c) > UpperCC) || (NormalizedAreaUnderCurve < NAUC)
        KeepMTT(r, c) = false;
        KeepTTP(r, c) = false;        
        KeepUnfilteredMTT(r, c) = false;
        IngrischMask(r, c) = false;
        continue;
      end
      
      UnfilteredPBV(r, c) = min(UnfilteredTCIntegral/UnfilteredAifIntegral, 1.0);       % Censor unrealistic (excessive, uncausal) values - e.g., at the injection point
      
      PBV(r, c) = min(TCIntegral/AifIntegral, 1.0);                                     % Censor unrealistic (excessive, uncausal) values - e.g., at the injection point
      
      MappingTC(:)   = 0.0;
      MappingTC(1:M) = tc;

      switch handles.MatrixAlgebra
        case 'Left-Division'
          try  
            Residue = handles.CM \ MappingTC;
          catch
            Residue = [];
            KeepMTT(r, c) = false;
            KeepTTP(r, c) = false;
            KeepUnfilteredMTT(r, c) = false;
          end
        case 'Explicit PINV (SVD)'
          try
            Residue = handles.PM * MappingTC;
          catch
            Residue = [];
            KeepMTT(r, c) = false;
            KeepTTP(r, c) = false;
            KeepUnfilteredMTT(r, c) = false;
          end
      end

      if ~isempty(Residue)
        [ Value, Place ] = max(Residue(1:M));
        
        if (Place == 1) || (Place == M)
          PBF(r, c) = Value;
          TTP(r, c) = Times(Place);
        else
          if (Interpolate == true)
            tt = [ -1.0, 0.0, 1.0 ];
            yy = [ Residue(Place-1), Residue(Place), Residue(Place+1) ];
            
            pp = polyfit(tt, yy, 2);
            
            dt = - 0.5*pp(2)/pp(1);
            ht = polyval(pp, dt);
            
            PBF(r, c) = ht;
            TTP(r, c) = Times(Place) + dt*DT;
          else
            PBF(r, c) = Value;
            TTP(r, c) = Times(Place);
          end
        end
        
        MTT(r, c) = PBV(r, c)/PBF(r, c);
        
        UnfilteredMTT(r, c) = UnfilteredPBV(r, c)/PBF(r, c);
      end
      
    end
    
  end
  
  CC = uint16(10000.0*CC);                          % Normalized units from 0 to 1, scaled to 0:10000 binary
  
  UnfilteredCC = uint16(10000.0*UnfilteredCC);      % Normalized units from 0 to 1, scaled to 0:10000 binary
  
  PBV = uint16(10000.0*PBV);                        % Units of 0.01 ml / 100 ml  
  PBF = uint16(6000.0*PBF);                         % Units of ml / min / 100 ml  
  
  UnfilteredPBV = uint16(10000.0*UnfilteredPBV);    % Units of 0.01 ml / 100 ml  
      
  MTT(KeepMTT) = 1.0e4 + 1.0e3*MTT(KeepMTT);        % Offset true physical values (MTT = 0) from the unprocessed (below-threshold) background
  MTT = uint16(MTT);                                % Units of 0.001 s - the unprocessed background is rendered as black
  
  UnfilteredMTT(KeepUnfilteredMTT) = 1.0e4 + 1.0e3*UnfilteredMTT(KeepUnfilteredMTT);        % Offset true physical values (MTT = 0) from the unprocessed (below-threshold) background
  UnfilteredMTT = uint16(UnfilteredMTT);                                                    % Units of 0.001 s - the unprocessed background is rendered as black
  
  TTP(KeepTTP) = 1.0e4 + 1.0e3*TTP(KeepTTP);        % Offset true physical values (TTP = 0) from the unprocessed (below-threshold) background
  TTP = uint16(TTP);                                % Units of 0.001 s - the unprocessed background is rendered as black
  
  AllCC(:, :, s) = CC;
  UnfilteredAllCC(:, :, s) = UnfilteredCC;
  
  AllPBV(:, :, s) = PBV;
  AllPBF(:, :, s) = PBF;
  AllMTT(:, :, s) = MTT;
  AllTTP(:, :, s) = TTP;
  
  UnfilteredAllPBV(:, :, s) = UnfilteredPBV;
  UnfilteredAllMTT(:, :, s) = UnfilteredMTT;
  
  AllIngrischMask(:, :, s) = IngrischMask;
  
  Info = handles.Mat.Head;
  
  Info.SliceThickness = MappingST;
  Info.SliceLocation  = MappingSL(s);
  Info.Rows           = handles.NROWS;
  Info.Columns        = handles.NCOLS;
  Info.PixelSpacing   = Info.PixelSpacing * handles.Reduction;
  Info.BitsAllocated  = 16;
  Info.BitsStored     = 16;
  Info.HighBit        = 15;
  
  Info.SeriesDescription = 'RSS parameter map';
  Info.ImageComments     = 'Cross-correlation';
  Info.RescaleIntercept  = 0.0;
  Info.RescaleSlope      = 1.0e-4;
  Info.RescaleType       = '';
  
  CCFileName = fullfile(Container, 'CC', sprintf('CC-%04d.dcm', s));
  dicomwrite(CC, CCFileName, Info, 'Dictionary', Dictionary, 'CreateMode', 'copy', 'WritePrivate', true, 'UseMetadataBitDepths', true);
  
  Info.SeriesDescription = 'RSS parameter map';
  Info.ImageComments     = 'Unfiltered cross-correlation';
  Info.RescaleIntercept  = 0.0;
  Info.RescaleSlope      = 1.0e-4;
  Info.RescaleType       = '';
  
  UnfilteredCCFileName = fullfile(Container, 'Unfiltered-CC', sprintf('Unfiltered-CC-%04d.dcm', s));
  dicomwrite(UnfilteredCC, UnfilteredCCFileName, Info, 'Dictionary', Dictionary, 'CreateMode', 'copy', 'WritePrivate', true, 'UseMetadataBitDepths', true);
  
  Info.SeriesDescription = 'RSS parameter map';
  Info.ImageComments     = 'Pulmonary blood volume';
  Info.RescaleIntercept  = 0.0;
  Info.RescaleSlope      = 0.01;
  Info.RescaleType       = 'ml/100.0 ml';
  
  PbvFileName = fullfile(Container, 'PBV', sprintf('PBV-%04d.dcm', s));
  dicomwrite(PBV, PbvFileName, Info, 'Dictionary', Dictionary, 'CreateMode', 'copy', 'WritePrivate', true, 'UseMetadataBitDepths', true);
  
  Info.SeriesDescription = 'RSS parameter map';
  Info.ImageComments     = 'Pulmonary blood flow';
  Info.RescaleIntercept  = 0.0;
  Info.RescaleSlope      = 1.0;
  Info.RescaleType       = '(ml/min)/100.0 ml';
  
  PbfFileName = fullfile(Container, 'PBF', sprintf('PBF-%04d.dcm', s));
  dicomwrite(PBF, PbfFileName, Info, 'Dictionary', Dictionary, 'CreateMode', 'copy', 'WritePrivate', true, 'UseMetadataBitDepths', true);
  
  Info.SeriesDescription = 'RSS parameter map';
  Info.ImageComments     = 'Mean transit time';
  Info.RescaleIntercept  = - 10.0;
  Info.RescaleSlope      = 0.001;
  Info.RescaleType       = 'sec';
  
  MttFileName = fullfile(Container, 'MTT', sprintf('MTT-%04d.dcm', s));
  dicomwrite(MTT, MttFileName, Info, 'Dictionary', Dictionary, 'CreateMode', 'copy', 'WritePrivate', true, 'UseMetadataBitDepths', true);
   
  Info.SeriesDescription = 'RSS parameter map';
  Info.ImageComments     = 'Unfiltered mean transit time';
  Info.RescaleIntercept  = - 10.0;
  Info.RescaleSlope      = 0.001;
  Info.RescaleType       = 'sec';
  
  UnfilteredMttFileName = fullfile(Container, 'Unfiltered-MTT', sprintf('Unfiltered-MTT-%04d.dcm', s));
  dicomwrite(UnfilteredMTT, UnfilteredMttFileName, Info, 'Dictionary', Dictionary, 'CreateMode', 'copy', 'WritePrivate', true, 'UseMetadataBitDepths', true);
  
  Info.SeriesDescription = 'RSS parameter map';
  Info.ImageComments     = 'Time to peak';
  Info.RescaleIntercept  = - 10.0;
  Info.RescaleSlope      = 0.001;
  Info.RescaleType       = 'sec';
  
  TtpFileName = fullfile(Container, 'TTP', sprintf('TTP-%04d.dcm', s));
  dicomwrite(TTP, TtpFileName, Info, 'Dictionary', Dictionary, 'CreateMode', 'copy', 'WritePrivate', true, 'UseMetadataBitDepths', true);  
  
  Info.SeriesDescription = 'RSS parameter map';
  Info.ImageComments     = 'Unfiltered pulmonary blood volume';
  Info.RescaleIntercept  = 0.0;
  Info.RescaleSlope      = 0.01;
  Info.RescaleType       = 'ml/100.0 ml';
  
  UnfilteredPbvFileName = fullfile(Container, 'Unfiltered-PBV', sprintf('Unfiltered-PBV-%04d.dcm', s));
  dicomwrite(UnfilteredPBV, UnfilteredPbvFileName, Info, 'Dictionary', Dictionary, 'CreateMode', 'copy', 'WritePrivate', true, 'UseMetadataBitDepths', true);
  
  waitbar(double(s)/double(handles.NSLICES), wb, sprintf('Processed %1d of %1d slices', s, handles.NSLICES));
end

pause(0.5);
waitbar(1.0, wb, 'Mapping completed');
pause(0.5);
delete(wb);

% Write out a pickle file of the results for quicker import into downstream software
p = strfind(FileName, '.');
q = p(end);
r = q - 1;

PickleFileName = sprintf('%s.mat', FileName(1:r));
PicklePathName = fullfile(PathName, PickleFileName);

wb = waitbar(0.5, 'Writing MAT file - please wait ... ');

ROI = handles.MpaRoi;

save(PicklePathName, 'AllCC', 'UnfilteredAllCC', 'AllPBV', 'AllPBF', 'AllMTT', 'AllTTP', 'UnfilteredAllPBV', 'UnfilteredAllMTT', ...
                     'AllIngrischMask', ...
                     'ROI');

pause(0.5);
waitbar(1.0, wb, 'Writing completed');
pause(0.5);
delete(wb);

% Re-enable graph updates
handles.MappingInProgress = false;

% Also, re-enable the downsampling options
set(handles.DownsamplingX1Radio, 'Enable', 'on');
set(handles.DownsamplingX2Radio, 'Enable', 'on');
set(handles.DownsamplingX4Radio, 'Enable', 'on');
set(handles.DownsamplingX8Radio, 'Enable', 'on');

% And the sliders
set(handles.DisplayCeilingSlider, 'Enable', 'on');
set(handles.DisplayFloorSlider, 'Enable', 'on');
set(handles.DisplaySliceSlider, 'Enable', 'on');
set(handles.DisplayEpochSlider, 'Enable', 'on');

set(handles.LastUsableFrameSlider, 'Enable', 'on');

% Next, the colormap controls
set(handles.ColormapListBox, 'Enable', 'on');
set(handles.ColormapSizeListBox, 'Enable', 'on');

% And some buttons and checkboxes
set(handles.OpenCineStackButton, 'Enable', 'on');
set(handles.FreezeDisplayOnClickCheck, 'Enable', 'on');
set(handles.UnfreezeDisplayButton, 'Enable', 'on');

set(handles.ZeroFillCheck, 'Enable', 'on');

set(handles.CreateMpaRoiButton, 'Enable', 'on');

set(handles.SubtractInitialSignalCheck, 'Enable', 'on');

set(handles.CaptureDisplayButton, 'Enable', 'on');

set(handles.PlotFullSolutionCheck, 'Enable', 'on');

set(handles.CreateMapsButton, 'Enable', 'on');

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end   

% Re-enable the deconvolution controls (radio-buttons); the SVD cut-off slider has been treated separately
set(handles.PeakAIFRadio, 'Enable', 'on');
set(handles.MeanAIFRadio, 'Enable', 'on');

set(handles.LeftDivideRadio, 'Enable', 'on');
set(handles.ExplicitPseudoInverseRadio, 'Enable', 'on');

set(handles.TruncateRadio, 'Enable', 'on');
set(handles.RegulariseRadio, 'Enable', 'on');
set(handles.NoActionRadio, 'Enable', 'on');

set(handles.ApodisationSlider, 'Enable', 'on');

% Enable the button to CREATE MAPS
set(handles.CreateMapsButton, 'Enable', 'on');

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CreateMapsButton_CreateFcn(hObject, eventdata, handles)

set(hObject, 'BackgroundColor', [1.0 0.6 0.6]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function UnfreezeDisplayButton_CreateFcn(hObject, eventdata, handles)

set(hObject, 'BackgroundColor', [0.6 0.6 1.0]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CreateMpaRoiButton_CreateFcn(hObject, eventdata, handles)

set(hObject, 'BackgroundColor', [1.0 1.0 0.6]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CaptureDisplayButton_CreateFcn(hObject, eventdata, handles)

set(hObject, 'BackgroundColor', [1.0 0.8 0.6]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RetainSvsSlider_Callback(hObject, eventdata, handles)

% Fetch the slider value, rounded to an integer
handles.RetainSvs = round(get(hObject, 'Value'));

% Report the value in the edit window
set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));

% Quit if the slider is visible but no AIF is available
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end  

% Set the cut-off limits - treat the general case and the end case separately
MM = handles.RetainSvs;
NN = numel(handles.SvdValues);

if (MM < NN)
  Upper = log10(handles.SvdValues(MM));
  Lower = log10(handles.SvdValues(MM + 1));
  Mean = 0.5*(Upper + Lower);
  handles.SVCutoff = 10.0^Mean;
else
  XLims = get(handles.SvdAxes, 'XLim');  
  Upper = log10(handles.SvdValues(NN));
  Lower = log10(XLims(1));  
  Mean = 0.5*(Upper + Lower);
  handles.SVCutoff = 10.0^Mean;
end

set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(NN/5.0)]);
set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;
                
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_RetainSvsSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the slider value, rounded to an integer
handles.RetainSvs = round(get(hObject, 'Value'));

% Report the value in the edit window
set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));

% Quit if the slider is visible but no AIF is available
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end  

% Set the cut-off limits - treat the general case and the end case separately
MM = handles.RetainSvs;
NN = numel(handles.SvdValues);

if (MM < NN)
  Upper = log10(handles.SvdValues(MM));
  Lower = log10(handles.SvdValues(MM + 1));
  Mean = 0.5*(Upper + Lower);
  handles.SVCutoff = 10.0^Mean;
else
  XLims = get(handles.SvdAxes, 'XLim');  
  Upper = log10(handles.SvdValues(NN));
  Lower = log10(XLims(1));  
  Mean = 0.5*(Upper + Lower);
  handles.SVCutoff = 10.0^Mean;
end

set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(NN/5.0)]);
set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;
                
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RetainSvsSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RetainSvsEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RetainSvsEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function NormalisationButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Establish the choice of normalisation, using the peak AIF or the mean (at each epoch, within the MPA ROI)
handles.Normalisation = get(eventdata.NewValue, 'String');

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end  

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;
                
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MatrixAlgebraButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Determine whether the deconvolution will be done implicitly (by left-division) or explicitly (by controlled SVD)
handles.MatrixAlgebra = get(eventdata.NewValue, 'String');

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  
    
aif = aif .* handles.Filter;

zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end
  
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SVDButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Control the management of the SVD for the explicit deconvolution
handles.Management = get(eventdata.NewValue, 'String');

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end 

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2);
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end        
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);         
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;   
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DownsamplingButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Fetch the label of the selected radio button
Code = get(eventdata.NewValue, 'String');

switch Code
  case 'x1 - Original Size'
    handles.Reduction = 1;
  case 'x2'
    handles.Reduction = 2;
  case 'x4'
    handles.Reduction = 4;
  case 'x8'
    handles.Reduction = 8;
end

% Quit if no review image is present
if (handles.ReviewImageIsPresent == false)
  guidata(hObject, handles);
  return;
end

% Select the cine-stack at the correct downsampling factor
switch Code
  case 'x1 - Original Size'
    handles.CineStack = handles.Mat.CineStackX1;
  case 'x2'
    handles.CineStack = handles.Mat.CineStackX2;
  case 'x4'
    handles.CineStack = handles.Mat.CineStackX4;
  case 'x8'
    handles.CineStack = handles.Mat.CineStackX8;
end

% Display the image size
Dims = size(handles.CineStack);

handles.NROWS   = Dims(1);
handles.NCOLS   = Dims(2);
handles.NSLICES = Dims(3);
handles.NEPOCHS = Dims(4);

set(handles.ImageSizeEdit, 'String', sprintf('  Size:   %1d / %1d / %1d', Dims(1), Dims(2), Dims(3)));
set(handles.ImageEpochsEdit, 'String', sprintf('  Epochs: %1d', Dims(4)));

handles.MinX = 0.5;
handles.MaxX = double(handles.NCOLS + 0.5);
handles.MinY = 0.5;
handles.MaxY = double(handles.NROWS + 0.5);

% Update the current slice to allow for possible downsampling
switch Code
  case 'x1 - Original Size'
    [ Value, Place ] = min(abs(handles.SLx1 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx1(handles.Slice);
  case 'x2'
    [ Value, Place ] = min(abs(handles.SLx2 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx2(handles.Slice);
  case 'x4'
    [ Value, Place ] = min(abs(handles.SLx4 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx4(handles.Slice);
  case 'x8'
    [ Value, Place ] = min(abs(handles.SLx8 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx8(handles.Slice);
end

% Update the slider settings if necessary
set(handles.DisplayCeilingSlider, 'Enable', 'on');
set(handles.DisplayFloorSlider, 'Enable', 'on');

set(handles.DisplaySliceSlider, 'Enable', 'on');
set(handles.DisplaySliceSlider, 'Max', handles.NSLICES);

% This shouldn't happen - given the code immediately preceding - but it shouldn't do any harm
set(handles.DisplaySliceSlider, 'Enable', 'on');
set(handles.DisplaySliceSlider, 'Max', handles.NSLICES);

switch Code
  case 'x1 - Original Size'
    set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 8.0]/double(handles.NSLICES - 1));
  case 'x2'
    set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 4.0]/double(handles.NSLICES - 1));
  case 'x4'
    set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 2.0]/double(handles.NSLICES - 1));
  case 'x8'
    set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 1.0]/double(handles.NSLICES - 1));
end

if (handles.Slice > handles.NSLICES)
  handles.Slice = handles.NSLICES; 
  set(handles.DisplaySliceSlider, 'Value', handles.NSLICES);
  set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));
  
  switch Code
  case 'x1 - Original Size'
    handles.CurrentSliceLocation = handles.SLx1(handles.Slice);
  case 'x2'
    handles.CurrentSliceLocation = handles.SLx2(handles.Slice);
  case 'x4'
    handles.CurrentSliceLocation = handles.SLx4(handles.Slice);
  case 'x8'
    handles.CurrentSliceLocation = handles.SLx8(handles.Slice);
  end
end

% This is a necessary precaution between different data sets
set(handles.DisplayEpochSlider, 'Enable', 'on');
set(handles.DisplayEpochSlider, 'Max', handles.NEPOCHS);
set(handles.DisplayEpochSlider, 'SliderStep', [1.0, 4.0]/double(handles.NEPOCHS - 1));

if (handles.Epoch > handles.NEPOCHS)
  handles.Epoch = handles.NEPOCHS; 
  set(handles.DisplayEpochSlider, 'Value', handles.NEPOCHS);
  set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Slice));
end

% Update the Slice and Epoch edit windows and their corresponding sliders
set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));
set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));

set(handles.DisplaySliceSlider, 'Value', handles.Slice);
set(handles.DisplayEpochSlider, 'Value', handles.Epoch);

% Display the current slice and epoch
handles.Lower = 0;
handles.Upper = max(handles.CineStack(:));

handles.Mini = handles.Upper*(handles.Floor/100.0);
handles.Maxi = handles.Upper*(handles.Ceiling/100.0);

handles.Data = handles.CineStack(:, :, handles.Slice, handles.Epoch);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 
text(16.0/r, 64.0/r, sprintf('Epoch: %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

% Enable some interactivity with the displayed image
handles.ReviewImageIsPresent = true;

% Update the HANDLES structure
guidata(hObject, handles);

end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DceMriPerfusionGuiMainFigure_DeleteFcn(hObject, eventdata, handles)

% Re-enable a warning that was disabled on start-up
warning('on', 'MATLAB:xlswrite:AddSheet');

% Now exit by deleting the figure
delete(handles.DceMriPerfusionGuiMainFigure);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DceMriPerfusionGuiMainFigure_KeyPressFcn(hObject, eventdata, handles)

% Trap either of 2 conventional exit keys to turn off the warning that was turned off when the dialog opened
switch eventdata.Key
  case { 'escape', 'return' }
    warning('on', 'MATLAB:xlswrite:AddSheet');
    delete(handles.DceMriPerfusionGuiMainFigure);
  otherwise
    return;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function PlotFullSolutionCheck_Callback(hObject, eventdata, handles)

% Decide whether to plot the full deconvolved time course (residue function) when zero-filling of the AIF is being used
handles.PlotFullSolution = get(hObject, 'Value');

% Gather some data dimensions
LUF = handles.LastUsableFrame;
  M = LUF - 1;

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;  
else
  N = M;
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ApodisationEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ApodisationEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ApodisationSlider_Callback(hObject, eventdata, handles)

% Fetch the filter strength in decades and create a vector of the truncated length
D = get(hObject, 'Value');

handles.Decades = 0.5*round(D/0.5);
handles.Filter  = pft_GaussianFilter(handles.LastUsableFrame - 1, handles.Decades);

% Display the result
set(handles.ApodisationEdit, 'String', sprintf(' Filter (decades): %.1f', handles.Decades));

% Exit if there is no image to review
if (handles.ReviewImageIsPresent == true)
  guidata(hObject, handles);
  return;
end 

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end

% Update the truncated and filtered section of the AIF data
if (handles.MpaRoiExists == true)
  FilteredAifPeak = handles.AIFPeak(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredAifPeak, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifPeak);
  FilteredAifMean = handles.AIFMean(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredAifMean, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifMean);
end

% Update the truncated and filtered section of the time-course
if (handles.DisplayIsFrozen == true)
  tc = handles.TC - handles.TC(1);
  tc = tc(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredTimeCourse, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', tc);
end

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end 

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2);
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end        
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);         
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;   
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% Gather some data dimensions
LUF = handles.LastUsableFrame;
  M = LUF - 1;

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;  
else
  N = M;
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_ApodisationSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the filter strength in decades and create a vector of the truncated length
D = get(hObject, 'Value');

handles.Decades = 0.5*round(D/0.5);
handles.Filter  = pft_GaussianFilter(handles.LastUsableFrame - 1, handles.Decades);

% Display the result
set(handles.ApodisationEdit, 'String', sprintf(' Filter (decades): %.1f', handles.Decades));

% Enable movement of the slider to control the management of the SVD (if appropriate)
switch handles.MatrixAlgebra
  case 'Left-Division'
    set(handles.RetainSvsSlider, 'Enable', 'off');
    set(handles.RetainSvsEdit, 'Visible', 'off');
    
  case 'Explicit PINV (SVD)'
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.RetainSvsSlider, 'Enable', 'on'); 
        set(handles.RetainSvsEdit, 'Visible', 'on');
      case 'No Action'
        set(handles.RetainSvsSlider, 'Enable', 'off');
        set(handles.RetainSvsEdit, 'Visible', 'off');
    end  
end

% Update the truncated and filtered section of the AIF data
if (handles.MpaRoiExists == true)
  FilteredAifPeak = handles.AIFPeak(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredAifPeak, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifPeak);
  FilteredAifMean = handles.AIFMean(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredAifMean, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', FilteredAifMean);
end

% Update the truncated and filtered section of the time-course
if (handles.DisplayIsFrozen == true)
  tc = handles.TC - handles.TC(1);
  tc = tc(2:handles.LastUsableFrame) .* handles.Filter;
  set(handles.hPlotFilteredTimeCourse, 'XData', handles.Mat.AT(2:handles.LastUsableFrame), 'YData', tc);
end

% Quit if there is no AIF available to create a convolution matrix
if (handles.MpaRoiExists == false)
  guidata(hObject, handles);
  return;
end 

% Create a "forward" or "inverse" convolution matrix and update the singular value plot
switch handles.Normalisation
  case 'AIF Peak'
    aif = handles.AIFPeak(2:handles.LastUsableFrame);
    aif = double(aif);
  case 'AIF Mean'
    aif = handles.AIFMean(2:handles.LastUsableFrame);
    aif = double(aif);
end  

aif = aif .* handles.Filter;
    
zf = handles.ZeroFill;
dt = handles.Mat.AT(3) - handles.Mat.AT(2);
    
switch handles.MatrixAlgebra
  case 'Left-Division'      
    handles.CM = pft_CreateConvMatrix(aif, zf, dt);
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    yy = (1:samples)';
    xx = repmat(1.0, [samples, 1]);
        
    set(handles.hPlotSV, 'XData', xx);
    set(handles.hPlotSV, 'YData', yy);  
    set(handles.SvdAxes, 'XLim', [0.1, 10.0]);
    set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(samples/5.0)]);
        
    set(handles.hPlotSVCutoff, 'XData', [0.5, 0.5]);
    set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(samples/5.0)]);     
  
  case 'Explicit PINV (SVD)'
    npts       = handles.RetainSvs;
    management = handles.Management;
    
    if (handles.ZeroFill == true)
      samples = 2*numel(aif);
    else
      samples = numel(aif);
    end
    
    if (npts > samples)
      npts = samples;
      handles.RetainSvs = npts;
      set(handles.RetainSvsSlider, 'Value', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'Max', handles.RetainSvs);
      set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(samples - 1));
      set(handles.RetainSvsEdit, 'String', sprintf(' Retain SV''s: %1d', handles.RetainSvs));
    end   
    
    [ handles.PM, handles.SvdValues ] = pft_CreatePinvMatrix(aif, zf, npts, dt, management);  
    
    M = handles.RetainSvs;
    N = numel(handles.SvdValues);    
    
    set(handles.RetainSvsSlider, 'Max', N);
    set(handles.RetainSvsSlider, 'SliderStep', [1.0 5.0]/double(N - 1));
   
    handles.SvdCounts = (1:N)';    
   
    switch handles.Management
      case { 'Truncate', 'Regularise' }
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2);
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        if (M < N)
          Upper = log10(handles.SvdValues(M));
          Lower = log10(handles.SvdValues(M + 1));
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        else
          XLims = get(handles.SvdAxes, 'XLim');  
          Upper = log10(handles.SvdValues(N));
          Lower = log10(XLims(1));  
          Mean = 0.5*(Upper + Lower);
          handles.SVCutoff = 10.0^Mean;
        end        
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);
           
      case 'No Action'
        set(handles.hPlotSV, 'XData', handles.SvdValues);
        set(handles.hPlotSV, 'YData', handles.SvdCounts);
        
        Unit = floor(log10(handles.SvdValues(N))) - 1;
        Step = 10^Unit;
        Mini = Step*(floor(handles.SvdValues(N)/Step) - 5);         
        
        Unit = ceil(log10(handles.SvdValues(1))) - 1;
        Step = 10^Unit;
        Maxi = Step*(ceil(handles.SvdValues(1)/Step) + 2); 
        
        set(handles.SvdAxes, 'XLim', [Mini, Maxi]);
        set(handles.SvdAxes, 'YLim', [0, 5.0*ceil(N/5.0)]); 
        
        XLims = get(handles.SvdAxes, 'XLim');  
        Upper = log10(handles.SvdValues(N));
        Lower = log10(XLims(1));  
        Mean = 0.5*(Upper + Lower);
        handles.SVCutoff = 10.0^Mean;   
        
        set(handles.hPlotSVCutoff, 'YData', [0, 5.0*ceil(N/5.0)]);
        set(handles.hPlotSVCutoff, 'XData', [handles.SVCutoff, handles.SVCutoff]);   
    end
end

% Exit if there is no measured time-course to deconvolve
if (handles.DisplayIsFrozen == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, perform and display the deconvolution
LUF = handles.LastUsableFrame;

tc = handles.TC - handles.TC(1);
tc = tc(2:LUF);
tc = double(tc);
tc = tc(:);
tc = tc .* handles.Filter;

M = numel(tc);

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;   
  
  tc = vertcat(tc, zeros([M + N - 1, 1], 'double'));
else
  N = M;
  
  tc = vertcat(tc, zeros([M - 1, 1], 'double'));
end

switch handles.MatrixAlgebra
  case 'Left-Division'
    try  
      handles.DeconvolvedTimeCourse = handles.CM \ tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
  case 'Explicit PINV (SVD)'
    try
      handles.DeconvolvedTimeCourse = handles.PM * tc;
    catch
      handles.DeconvolvedTimeCourse = [];
    end
end

% Gather some data dimensions
LUF = handles.LastUsableFrame;
  M = LUF - 1;

% The time-course needs to be padded in either case, to bring the deconvolved time-course down to the correct size
if (handles.ZeroFill == true)
  N = 2*M;  
else
  N = M;
end

% The default XData for the deconvolved time-course plot will only change in the single case below (zero-filling and full-solution plotting)
NewXData = handles.Mat.AT(2:LUF);

if (handles.PlotFullSolution == true)
  if ~isempty(handles.DeconvolvedTimeCourse)
    if (handles.ZeroFill == true) 
      DT = handles.Mat.AT(3) - handles.Mat.AT(2);
      NewXData = vertcat(handles.Mat.AT(2:LUF), DT*(LUF-1:N-1)');
    end
    
    NewYData = handles.DeconvolvedTimeCourse(1:N);  
  else
    NewYData = zeros([M, 1], 'double');
  end
else
  if ~isempty(handles.DeconvolvedTimeCourse)
    NewYData = handles.DeconvolvedTimeCourse(1:M);
  else
    NewYData = zeros([M, 1], 'double');
  end
end

NewMinY = 0.025*floor(min(NewYData)/0.025);
NewMaxY = 0.1*ceil(max(NewYData)/0.1) + 0.025;

set(handles.hPlotDeconvolvedTimeCourse, 'XData', NewXData, 'YData', NewYData);

set(handles.DeconvolvedTimeCourseAxes, 'YLim', [NewMinY, NewMaxY]);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ApodisationSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end
