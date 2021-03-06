function varargout = pft_DceMriPerfusionSegmentGrayscaleFloodFillMacOS(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pft_DceMriPerfusionSegmentGrayscaleFloodFillMacOS_OpeningFcn, ...
                   'gui_OutputFcn',  @pft_DceMriPerfusionSegmentGrayscaleFloodFillMacOS_OutputFcn, ...
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

function pft_DceMriPerfusionSegmentGrayscaleFloodFillMacOS_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for pft_DceMriPerfusionSegmentGrayscaleFloodFillMacOS
handles.output = hObject;

% Initialise the program state
handles.ProgramState = 'Import/Review';

% Note that there is no cine-stack present to review
handles.ReviewImageIsPresent = false;

% Emphasise that no segmentation is taking place
handles.SegmentationInProgress = false;

% Also, no ROI folders have been selected
handles.RoiParentFolder = [];

% Therefore, there are no 3D segmentation masks as yet
handles.RightBinaryMask = [];
handles.LinksBinaryMask = [];
handles.TotalBinaryMask = [];

% Or 2D single-slice ROI's
handles.RightROI = [];
handles.LinksROI = [];
handles.TotalROI = [];

% Enable image labelling by default
handles.LabelImages = true;

% Centre the display
% ScreenSize = get(0, 'ScreenSize');
% FigureSize = get(hObject, 'Position');
% 
% WD = ScreenSize(3);
% HT = ScreenSize(4);
% 
% wd = FigureSize(3);
% ht = FigureSize(4);
% 
% FigureSize(1) = (WD - wd)/2;
% FigureSize(2) = (HT - ht)/2;
% 
% set(hObject, 'Position', FigureSize);

% Centre the display
MP         = get(0, 'MonitorPositions');
ScreenSize = MP(end, :);
FigureSize = ScreenSize;

FigureSize(1) = FigureSize(1) - 500;
FigureSize(2) = FigureSize(2) - 500;

set(hObject, 'Units', 'pixels', 'Position', FigureSize);

% Initialise the grayscale display
handles.GrayscaleData = zeros([176, 176], 'uint8');

handles.Lower = 0;
handles.Upper = 255.0;
handles.Range = handles.Upper - handles.Lower;

handles.Ceiling = 15.0;
handles.Floor   = 0.0;

handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

handles.hGrayscaleImage = imagesc(handles.ImageDisplayAxes, handles.GrayscaleData);
set(handles.hGrayscaleImage, 'HitTest', 'off', 'PickableParts', 'none');
caxis(handles.ImageDisplayAxes, [handles.Mini, handles.Maxi]);
colormap(handles.ImageDisplayAxes, gray(256));

handles.ImageDisplayAxes.XTick = [];
handles.ImageDisplayAxes.YTick = [];
handles.ImageDisplayAxes.XTickLabels = [];
handles.ImageDisplayAxes.YTickLabels = [];

handles.CommonAxesPosition = get(handles.ImageDisplayAxes, 'Position');

handles.GrayscaleColorbar = colorbar(handles.ImageDisplayAxes, 'EastOutside', 'FontSize', 16, 'FontWeight', 'bold');

ylabel(handles.GrayscaleColorbar, 'Arbitrary Units', 'FontSize', 16, 'FontWeight', 'bold');

set(handles.ImageDisplayAxes, 'Position', handles.CommonAxesPosition);

% Initialise the segmentation display axes
handles.SegmentationDisplayAxes.Visible = 'off';
handles.SegmentationDisplayAxes.XTick = [];
handles.SegmentationDisplayAxes.YTick = [];
handles.SegmentationDisplayAxes.XTickLabels = [];
handles.SegmentationDisplayAxes.YTickLabels = [];
linkprop([handles.ImageDisplayAxes, handles.SegmentationDisplayAxes], 'Position');

% Initialise a colormap for the segmentation, together with some useful constants
handles.SegmentationCM = [ 0 0 1; ...
                           1 0 0 ];
                       
handles.Blue = uint8(1);
handles.Red  = uint8(3);

handles.SegmentationMini = uint8(0);
handles.SegmentationMaxi = uint8(4);

% Initialise a rectangle for movies and screen captures
handles.MainFigureColor = get(handles.MainFigure, 'Color');

AP = handles.CommonAxesPosition;

x0 = AP(1);
y0 = AP(2);
wd = AP(3);
ht = AP(4);

DXL = 8;
DXU = 120;
DYL = 14;
DYU = 10;

x0 = x0 - DXL;
y0 = y0 - DYL;
wd = wd + DXL + DXU;
ht = ht + DYL + DYU;

handles.Rectangle = [ x0 y0 wd ht ];

% Initialise the data source folder and the results folder
fid = fopen('Source-Folder.txt', 'rt');
handles.SourceFolder = fgetl(fid);
fclose(fid);

fid = fopen('Target-Folder.txt', 'rt');
handles.TargetFolder = fgetl(fid);
fclose(fid);

ScreenshotsFolder = fullfile(handles.TargetFolder, 'Screenshots');

if (exist(ScreenshotsFolder, 'dir') ~= 7)
  mkdir(ScreenshotsFolder);
end

% Disable some features which apply only to a genuine data set (not the initial blank placeholder)
handles.ReviewImageIsPresent = false;

% Set limits for the cursor to find the image axes as the mouse is moved around
handles.NROWS = 176;
handles.NCOLS = 176;

handles.MinX = 0.5;
handles.MaxX = double(handles.NCOLS + 0.5);
handles.MinY = 0.5;
handles.MaxY = double(handles.NROWS + 0.5);

text(8, 8, 'No data loaded', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');

% Set the number of slices to an expected value to allow for parameter changes before any images are loaded
handles.NSLICES = 112;

% Set the image downsampling factor to control the size of text labels on the image
handles.Reduction = 1;

% Initialise some important display variables
handles.Ceiling = 15.0;
handles.Floor   = 0.0;
handles.Slice   = 56;
handles.Epoch   = 1;

% Set the slider steps
set(handles.DisplayCeilingSlider, 'SliderStep', [1.0, 9.0]/99.0);
set(handles.DisplayFloorSlider, 'SliderStep', [1.0, 9.0]/99.0);
set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 8.0]/111.0);
set(handles.DisplayEpochSlider, 'SliderStep', [1.0, 4.0]/16.0);

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
M = find(strcmpi(handles.ColormapNames, 'gray'), 1, 'first');
set(handles.ColormapListBox, 'Value', M);

handles.ColormapSizes = { '8', '16', '32', '64', '128', '256' };
set(handles.ColormapSizeListBox, 'String', handles.ColormapSizes);
N = find(strcmpi(handles.ColormapSizes, '256'), 1, 'first');
set(handles.ColormapSizeListBox, 'Value', N);

handles.CurrentColormapName = 'gray';
handles.CurrentColormapSize = '256';
handles.Colormap            = hot(256);

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

% Initialise the ROI flood-filling options
handles.Selection          = 'Auto-Detect';
handles.Tolerance          = 10.0;
handles.CloseImage         = true;
handles.ImageClosingRadius = 8;
handles.FillHoles          = true;
handles.Opacity            = 0.5;
handles.AutoAdvanceSlice   = true;

% Add listeners for a continuous slider response
hDisplayCeilingSliderListener = addlistener(handles.DisplayCeilingSlider, 'ContinuousValueChange', @CB_DisplayCeilingSlider_Listener);
setappdata(handles.DisplayCeilingSlider, 'MyListener', hDisplayCeilingSliderListener);

hDisplayFloorSliderListener = addlistener(handles.DisplayFloorSlider, 'ContinuousValueChange', @CB_DisplayFloorSlider_Listener);
setappdata(handles.DisplayFloorSlider, 'MyListener', hDisplayFloorSliderListener);

hDisplaySliceSliderListener = addlistener(handles.DisplaySliceSlider, 'ContinuousValueChange', @CB_DisplaySliceSlider_Listener);
setappdata(handles.DisplaySliceSlider, 'MyListener', hDisplaySliceSliderListener);

hDisplayEpochSliderListener = addlistener(handles.DisplayEpochSlider, 'ContinuousValueChange', @CB_DisplayEpochSlider_Listener);
setappdata(handles.DisplayEpochSlider, 'MyListener', hDisplayEpochSliderListener);

hFloodFillToleranceSliderListener = addlistener(handles.FloodFillToleranceSlider, 'ContinuousValueChange', @CB_FloodFillToleranceSlider_Listener);
setappdata(handles.FloodFillToleranceSlider, 'MyListener', hFloodFillToleranceSliderListener);

hImageClosingRadiusSliderListener = addlistener(handles.ImageClosingRadiusSlider, 'ContinuousValueChange', @CB_ImageClosingRadiusSlider_Listener);
setappdata(handles.ImageClosingRadiusSlider, 'MyListener', hImageClosingRadiusSliderListener);

hOpacitySliderListener = addlistener(handles.OpacitySlider, 'ContinuousValueChange', @CB_OpacitySlider_Listener);
setappdata(handles.OpacitySlider, 'MyListener', hOpacitySliderListener);

% Disable warnings about sheets being added to Excel files
warning('off', 'MATLAB:xlswrite:AddSheet'); 

% Update the HANDLES structure
guidata(hObject, handles);

% UIWAIT makes pft_DceMriPerfusionSegmentGrayscaleFloodFillMacOS wait for user response (see UIRESUME)
% uiwait(handles.MainFigure);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = pft_DceMriPerfusionSegmentGrayscaleFloodFillMacOS_OutputFcn(hObject, eventdata, handles) 

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

[ p, f, e ] = fileparts(fullfile(PathName, FileName));

handles.FileNameStub = f;

% Read in the CineStack, the Acquisition Times, and a common working Dicom header these are bundled in a structure called Mat, which is retained to save memory and time
wb = waitbar(0.5, 'Loading data - please wait ... ');

handles.Mat = [];
handles.Mat = load(fullfile(PathName, FileName));

pause(0.5);
waitbar(1.0, wb, 'Loading complete');
pause(0.5);
delete(wb);

% Update the read-only edit window
set(handles.GrayscaleFileEdit, 'String', sprintf('  Grayscale Pickle File: %s', FileName));
                                                  
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
handles.Range = handles.Upper - handles.Lower;

handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

handles.GrayscaleData = handles.CineStack(:, :, handles.Slice, handles.Epoch);

% Create some dummy working arrays for efficient display of the various grayscale-and-perfusion-map compositions
Dimensions = [ handles.NROWS, handles.NCOLS ];

handles.Black       = zeros(Dimensions, 'uint8');
handles.Transparent = zeros(Dimensions, 'uint8');

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Enable the screen capture button
set(handles.CaptureDisplayButton, 'Enable', 'on');

% Enable some interactivity with the displayed image
handles.ReviewImageIsPresent = true;

% Enable segmentation if a working image is present and if a set of ROI folders has been nominated
if ~isempty(handles.RoiParentFolder)
  set(handles.SegmentRadio, 'Enable', 'on');
end

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
if (handles.Ceiling - handles.Floor <= 1)
  handles.Floor = handles.Ceiling - 1.0;
  set(handles.DisplayFloorSlider, 'Value', handles.Floor);
  set(handles.DisplayFloorEdit, 'String', sprintf('  Floor:   %3d %%', handles.Floor));
end

% Display the current slice
handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
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
if (handles.Ceiling - handles.Floor <= 1)
  handles.Floor = handles.Ceiling - 1.0;
  set(handles.DisplayFloorSlider, 'Value', handles.Floor);
  set(handles.DisplayFloorEdit, 'String', sprintf('  Floor:   %3d %%', handles.Floor));
end

% Display the current slice
handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
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
if (handles.Ceiling - handles.Floor <= 1)
  handles.Ceiling = handles.Floor + 1.0;
  set(handles.DisplayCeilingSlider, 'Value', handles.Ceiling);
  set(handles.DisplayCeilingEdit, 'String', sprintf('  Ceiling: %3d %%', handles.Ceiling));
end

% Display the current slice
handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
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
if (handles.Ceiling - handles.Floor <= 1)
  handles.Ceiling = handles.Floor + 1.0;
  set(handles.DisplayCeilingSlider, 'Value', handles.Ceiling);
  set(handles.DisplayCeilingEdit, 'String', sprintf('  Ceiling: %3d %%', handles.Ceiling));
end

% Display the current slice
handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

% Update the HANDLES structure
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
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

function DisplaySliceSlider_Callback(hObject, eventdata, handles)

% Fetch the current slice
handles.Slice = round(get(hObject, 'Value'));
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

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_DisplaySliceSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the current slice
handles.Slice = round(get(hObject, 'Value'));
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

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplaySliceSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

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

function MainFigure_WindowButtonMotionFcn(hObject, eventdata, handles)

% Quit if no review image is present - avoid processing during a possible hiatus between image selections
if (handles.ReviewImageIsPresent == false)
  return;
end

% Also, do nothing if segmentation is in progress
if (handles.SegmentationInProgress == true)
  return;
end

% Fetch the current point w.r.t. the IMAGE AXES rather than the MAIN FIGURE
P = get(handles.ImageDisplayAxes, 'CurrentPoint');

cx = P(1, 1);
cy = P(1, 2);

% Quit and do nothing if the cursor is outside the currently displayed image - but be sure to set the cursor correctly
if (cx < handles.MinX) || (cx > handles.MaxX) || (cy < handles.MinY) || (cy > handles.MaxY)
  set(handles.MainFigure, 'Pointer', 'arrow');
  
  set(handles.ImageRowEdit, 'String', '  Row:');
  set(handles.ImageColumnEdit, 'String', '  Column:');
  
  set(handles.ImagePixelValueEdit, 'String', '  Pixel Value:');  
  
  guidata(hObject, handles);
  return;
end

% If the cursor is inside, change the shape from an arrow to crosshairs
set(handles.MainFigure, 'Pointer', 'crosshair');

% Report the cursor position and pixel value and update the time course plots
handles.PixelRow = ceil(cy - 0.5);
handles.PixelCol = ceil(cx - 0.5);

handles.PixelValue = handles.GrayscaleData(handles.PixelRow, handles.PixelCol);

set(handles.ImageRowEdit, 'String', sprintf('  Row:    %1d', handles.PixelRow));
set(handles.ImageColumnEdit, 'String', sprintf('  Column: %1d', handles.PixelCol));

set(handles.ImagePixelValueEdit, 'String', sprintf('  Pixel Value: %.4f', handles.PixelValue));

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CaptureDisplayButton_Callback(hObject, eventdata, handles)

% Offer the option to save the screenshot as an image
Listing = dir(fullfile(handles.TargetFolder, 'Screenshots', sprintf('%s_Screenshot_*.png', handles.FileNameStub)));
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries(Folders) = [];
Entries = sort(Entries);
Entries = Entries';

if isempty(Entries)
  Suffix = '001';  
    
  DefaultName = fullfile(handles.TargetFolder, 'Screenshots', sprintf('%s_Screenshot_001.png', handles.FileNameStub));
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
    
  DefaultName = fullfile(handles.TargetFolder, 'Screenshots', sprintf('%s_Screenshot_%s.png', handles.FileNameStub, Suffix));
end

FilterSpec  = fullfile(handles.TargetFolder, 'Screenshots', '*.png');
DialogTitle = 'Save Screenshot As';

[ FileName, PathName, FilterIndex ] = pft_uiputfile(FilterSpec, DialogTitle, DefaultName);

if (FilterIndex ~= 0)
  set(handles.MainFigure, 'Color', [1 1 1]);
      
  F = getframe(handles.MainFigure, handles.Rectangle);
  X = F.cdata;
  
  set(handles.MainFigure, 'Color', handles.MainFigureColor);  
    
  wb = waitbar(0.5, 'Exporting screenshot ... ');  
    
  imwrite(X, fullfile(PathName, FileName));
  
  pause(0.5);  
  waitbar(1.0, wb, 'Export complete');
  pause(0.5);
  delete(wb);  
end

% Update the HANDLES structure - is this really necessary here, since "handles" is used in a read-only way here ? 
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CaptureDisplayButton_CreateFcn(hObject, eventdata, handles)

set(hObject, 'BackgroundColor', [1.0 0.8 0.6]);

end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_DeleteFcn(hObject, eventdata, handles)

% Re-enable a warning that was disabled on start-up
warning('on', 'MATLAB:xlswrite:AddSheet');

% Now exit by deleting the figure
delete(hObject);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_KeyPressFcn(hObject, eventdata, handles)

% Trap either of 2 conventional exit keys to turn off the warning that was turned off when the dialog opened
switch eventdata.Key
  case { 'escape', 'return' }
    warning('on', 'MATLAB:xlswrite:AddSheet');
    delete(hObject);
  otherwise
    return;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_CloseRequestFcn(hObject, eventdata, handles)

% Re-enable a warning that was disabled on start-up
warning('on', 'MATLAB:xlswrite:AddSheet');

% Now exit by deleting the figure
delete(hObject);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleFileEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleFileEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RightLungROIFolderEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RightLungROIFolderEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LinksLungROIFolderEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LinksLungROIFolderEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DeleteRightLungROIButton_Callback(hObject, eventdata, handles)

% Set the local slice-wise binary mask to false
handles.RightBinaryMask(:, :, handles.Slice) = false;

handles.TotalBinaryMask(:, :, handles.Slice) = handles.RightBinaryMask(:, :, handles.Slice) | handles.LinksBinaryMask(:, :, handles.Slice);

% Update the display
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Delete the binary mask in the appropriate folder
OutputFileName = fullfile(handles.RoiParentFolder, 'Right Lung', sprintf('Binary-Mask-Slice-%03d.png', handles.Slice));
                      
if (exist(OutputFileName, 'file') == 2)
  delete(OutputFileName);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DeleteLeftLungROIButton_Callback(hObject, eventdata, handles)

% Set the local slice-wise binary mask to false
handles.LinksBinaryMask(:, :, handles.Slice) = false;

handles.TotalBinaryMask(:, :, handles.Slice) = handles.LinksBinaryMask(:, :, handles.Slice) | handles.RightBinaryMask(:, :, handles.Slice);

% Update the display
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Delete the binary mask in the appropriate folder
OutputFileName = fullfile(handles.RoiParentFolder, 'Left Lung', sprintf('Binary-Mask-Slice-%03d.png', handles.Slice));
                      
if (exist(OutputFileName, 'file') == 2)
  delete(OutputFileName);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to disable active controls during segmentation                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = DisableControlsDuringSegmentation(handles)

% The Program State button group
set(handles.ImportReviewRadio, 'Enable', 'off');
set(handles.SegmentRadio, 'Enable', 'off');

% The colormap controls
set(handles.ColormapListBox, 'Enable', 'off');
set(handles.ColormapSizeListBox, 'Enable', 'off');

% The windowing and slice selection sliders
set(handles.DisplayCeilingSlider, 'Enable', 'off');
set(handles.DisplayFloorSlider, 'Enable', 'off');
set(handles.DisplaySliceSlider, 'Enable', 'off');
set(handles.DisplayEpochSlider, 'Enable', 'off');

% The Display Menu controls - note that "Open Cine-Stack" will always be disabled in Segmentation mode
set(handles.SelectROIFolderButton, 'Enable', 'off');

set(handles.LabelImagesCheck, 'Enable', 'off');
set(handles.CaptureDisplayButton, 'Enable', 'off');

set(handles.DownsamplingX1Radio, 'Enable', 'off');
set(handles.DownsamplingX2Radio, 'Enable', 'off');
set(handles.DownsamplingX4Radio, 'Enable', 'off');
set(handles.DownsamplingX8Radio, 'Enable', 'off');

% And finally, the segmentation controls themselves
set(handles.RightLungRadio, 'Enable', 'off');
set(handles.AutoDetectLungRadio, 'Enable', 'off');
set(handles.LeftLungRadio, 'Enable', 'off');

set(handles.FloodFillToleranceSlider, 'Enable', 'off');

set(handles.CloseImageCheck, 'Enable', 'off');
set(handles.ImageClosingRadiusSlider, 'Enable', 'off');

set(handles.FillRoiHolesCheck, 'Enable', 'off');

set(handles.OpacitySlider, 'Enable', 'off');

set(handles.AutoAdvanceSliceCheck, 'Enable', 'off');

set(handles.SliceBackButton, 'Enable', 'off');
set(handles.SliceForwardButton, 'Enable', 'off');
set(handles.EpochBackButton, 'Enable', 'off');
set(handles.EpochForwardButton, 'Enable', 'off');

set(handles.DeleteRightLungROIButton, 'Enable', 'off');
set(handles.DeleteLeftLungROIButton, 'Enable', 'off');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to re-enable inactive controls during segmentation                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = EnableControlsAfterSegmentation(handles)

% The Program State button group
set(handles.ImportReviewRadio, 'Enable', 'on');
set(handles.SegmentRadio, 'Enable', 'on');

% The colormap controls
set(handles.ColormapListBox, 'Enable', 'on');
set(handles.ColormapSizeListBox, 'Enable', 'on');

% The windowing and slice selection sliders
set(handles.DisplayCeilingSlider, 'Enable', 'on');
set(handles.DisplayFloorSlider, 'Enable', 'on');
set(handles.DisplaySliceSlider, 'Enable', 'on');
set(handles.DisplayEpochSlider, 'Enable', 'on');

% The Display Menu controls - note that "Open Cine-Stack" will always be disabled in Segmentation mode
set(handles.SelectROIFolderButton, 'Enable', 'on');

set(handles.LabelImagesCheck, 'Enable', 'on');
set(handles.CaptureDisplayButton, 'Enable', 'on');

set(handles.DownsamplingX1Radio, 'Enable', 'on');
set(handles.DownsamplingX2Radio, 'Enable', 'on');
set(handles.DownsamplingX4Radio, 'Enable', 'on');
set(handles.DownsamplingX8Radio, 'Enable', 'on');

% And finally, the segmentation controls themselves
set(handles.RightLungRadio, 'Enable', 'on');
set(handles.AutoDetectLungRadio, 'Enable', 'on');
set(handles.LeftLungRadio, 'Enable', 'on');

set(handles.FloodFillToleranceSlider, 'Enable', 'on');

set(handles.CloseImageCheck, 'Enable', 'on');
set(handles.ImageClosingRadiusSlider, 'Enable', 'on');

set(handles.FillRoiHolesCheck, 'Enable', 'on');

set(handles.OpacitySlider, 'Enable', 'on');

set(handles.AutoAdvanceSliceCheck, 'Enable', 'on');

set(handles.SliceBackButton, 'Enable', 'on');
set(handles.SliceForwardButton, 'Enable', 'on');
set(handles.EpochBackButton, 'Enable', 'on');
set(handles.EpochForwardButton, 'Enable', 'on');

set(handles.DeleteRightLungROIButton, 'Enable', 'on');
set(handles.DeleteLeftLungROIButton, 'Enable', 'on');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to disable the segmentation controls during import/review                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = DisableSegmentationControls(handles)

% All of these controls live in the same UI panel
set(handles.RightLungRadio, 'Enable', 'off');
set(handles.AutoDetectLungRadio, 'Enable', 'off');
set(handles.LeftLungRadio, 'Enable', 'off');

set(handles.FloodFillToleranceSlider, 'Enable', 'off');

set(handles.CloseImageCheck, 'Enable', 'off');
set(handles.ImageClosingRadiusSlider, 'Enable', 'off');

set(handles.FillRoiHolesCheck, 'Enable', 'off');

set(handles.OpacitySlider, 'Enable', 'off');

set(handles.AutoAdvanceSliceCheck, 'Enable', 'off');

set(handles.SliceBackButton, 'Enable', 'off');
set(handles.SliceForwardButton, 'Enable', 'off');
set(handles.EpochBackButton, 'Enable', 'off');
set(handles.EpochForwardButton, 'Enable', 'off');

set(handles.DeleteRightLungROIButton, 'Enable', 'off');
set(handles.DeleteLeftLungROIButton, 'Enable', 'off');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to re-enable the segmentation controls segmentation                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = EnableSegmentationControls(handles)

% All of these controls live in the same UI panel
set(handles.RightLungRadio, 'Enable', 'on');
set(handles.AutoDetectLungRadio, 'Enable', 'on');
set(handles.LeftLungRadio, 'Enable', 'on');

set(handles.FloodFillToleranceSlider, 'Enable', 'on');

set(handles.CloseImageCheck, 'Enable', 'on');
set(handles.ImageClosingRadiusSlider, 'Enable', 'on');

set(handles.FillRoiHolesCheck, 'Enable', 'on');

set(handles.OpacitySlider, 'Enable', 'on');

set(handles.AutoAdvanceSliceCheck, 'Enable', 'on');

set(handles.SliceBackButton, 'Enable', 'on');
set(handles.SliceForwardButton, 'Enable', 'on');
set(handles.EpochBackButton, 'Enable', 'on');
set(handles.EpochForwardButton, 'Enable', 'on');

set(handles.DeleteRightLungROIButton, 'Enable', 'on');
set(handles.DeleteLeftLungROIButton, 'Enable', 'on');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ProgramStateButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Select the program state - Import/Review or Segment
handles.ProgramState = get(eventdata.NewValue, 'String');

% Enable and disable controls relevant to the program state
switch handles.ProgramState
  case 'Import/Review'
    guidata(hObject, handles);    
    handles = DisableSegmentationControls(handles);
    guidata(hObject, handles);
    set(handles.OpenCineStackButton, 'Enable', 'on');
  case 'Segment'
    guidata(hObject, handles);    
    handles = EnableSegmentationControls(handles);
    guidata(hObject, handles);
    set(handles.OpenCineStackButton, 'Enable', 'off');
end        
          
% Update the folder names in the read-only edit windows
switch handles.ProgramState
    
  case 'Import/Review'
    set(handles.RightLungROIFolderEdit, 'String', '  Right Lung ROI Folder:');
    set(handles.LinksLungROIFolderEdit, 'String', '  Left Lung ROI Folder: ');    
    
  case 'Segment'
    % Read in the right binary mask stack
    handles.RightLungFolder = fullfile(handles.RoiParentFolder, 'Right Lung');
  
    if (exist(handles.RightLungFolder, 'dir') ~= 7)
      mkdir(handles.RightLungFolder);
    end
  
    handles.RightBinaryMask = pft_ReadBinaryMaskStack(handles.RightLungFolder, size(handles.CineStack));
  
    p = strfind(handles.RightLungFolder, filesep);
    q = p(end-1);      
    
    set(handles.RightLungROIFolderEdit, 'String', sprintf('  Right Lung ROI Folder: ..%s', handles.RightLungFolder(q:end)));
  
    % Read in the left binary mask stack
    handles.LinksLungFolder = fullfile(handles.RoiParentFolder, 'Left Lung');
  
    if (exist(handles.LinksLungFolder, 'dir') ~= 7)
      mkdir(handles.LinksLungFolder);
    end
  
    handles.LinksBinaryMask = pft_ReadBinaryMaskStack(handles.LinksLungFolder, size(handles.CineStack));
  
    p = strfind(handles.LinksLungFolder, filesep);
    q = p(end-1);
    
    set(handles.LinksLungROIFolderEdit, 'String', sprintf('  Left Lung ROI Folder:  ..%s', handles.LinksLungFolder(q:end)));
  
    % Combine the two maps
    handles.TotalBinaryMask = handles.RightBinaryMask | handles.LinksBinaryMask;    
  
end    

% Now update the image display
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayEpochSlider_Callback(hObject, eventdata, handles)

% Fetch the current epoch
handles.Epoch = round(get(hObject, 'Value'));
set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_DisplayEpochSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the current slice
handles.Epoch = round(get(hObject, 'Value'));
set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DisplayEpochSlider_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
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

function SelectROIFolderButton_Callback(hObject, eventdata, handles)

% Prompt for the parent folder of the left and right lung directories - quit silently on Cancel
Folder = pft_uigetdir(fullfile(handles.TargetFolder, 'Regions of Interest'), 'Parent folder for right and left lung ROI''s');

if ~ischar(Folder)
  return;
end

% Point to the twin folders beneath the selected one, and create them if necessary
handles.RoiParentFolder = Folder;

handles.RightLungFolder = fullfile(handles.RoiParentFolder, 'Right Lung');

if (exist(handles.RightLungFolder, 'dir') ~= 7)
  mkdir(handles.RightLungFolder);
end

p = strfind(handles.RightLungFolder, filesep);
q = p(end-1);
    
set(handles.RightLungROIFolderEdit, 'String', sprintf('  Right Lung ROI Folder: ..%s', handles.RightLungFolder(q:end)));

handles.LinksLungFolder = fullfile(handles.RoiParentFolder, 'Left Lung');

if (exist(handles.LinksLungFolder, 'dir') ~= 7)
  mkdir(handles.LinksLungFolder);
end

p = strfind(handles.LinksLungFolder, filesep);
q = p(end-1);
    
set(handles.LinksLungROIFolderEdit, 'String', sprintf('  Left Lung ROI Folder:  ..%s', handles.LinksLungFolder(q:end)));

% Enable segmentation if a review image cine-stack is already present
if (handles.ReviewImageIsPresent == true)
  set(handles.SegmentRadio, 'Enable', 'on');
end

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

% Enable some interactivity with the displayed image
handles.ReviewImageIsPresent = true;

% Display the current slice and epoch
handles.Lower = 0;
handles.Upper = max(handles.CineStack(:));
handles.Range = handles.Upper - handles.Lower;

handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

handles.GrayscaleData = handles.CineStack(:, :, handles.Slice, handles.Epoch);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

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

function LabelImagesCheck_Callback(hObject, eventdata, handles)

% Fetch the value
handles.LabelImages = get(hObject, 'Value');

% Exit if there is no cine-stack loaded to review
if (handles.ReviewImageIsPresent == false)
  guidata(hObject, handles);
  return;
end

% Otherwise, just update the image display
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FloodFillToleranceEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FloodFillToleranceEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FloodFillToleranceSlider_Callback(hObject, eventdata, handles)

% Fetch the raw value
Value = get(hObject, 'Value');

% Round to the nearest 0.1 per cent
handles.Tolerance = 0.1*round(Value/0.1);

% Update the read-only edit window
set(handles.FloodFillToleranceEdit, 'String', sprintf('Flood-Fill Tolerance: %.1f %%', handles.Tolerance));

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_FloodFillToleranceSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the raw value
Value = get(hObject, 'Value');

% Round to the nearest 0.1 per cent
handles.Tolerance = 0.1*round(Value/0.1);

% Update the read-only edit window
set(handles.FloodFillToleranceEdit, 'String', sprintf('Flood-Fill Tolerance: %.1f %%', handles.Tolerance));

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FloodFillToleranceSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageClosingRadiusEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageClosingRadiusEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageClosingRadiusSlider_Callback(hObject, eventdata, handles)

% Fetch the value and round to an integer
handles.ImageClosingRadius = round(get(hObject, 'Value'));

% Update the read-only edit window
set(handles.ImageClosingRadiusEdit, 'String', sprintf('Image Closing Radius: %1d', handles.ImageClosingRadius));

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_ImageClosingRadiusSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the value and round to an integer
handles.ImageClosingRadius = round(get(hObject, 'Value'));

% Update the read-only edit window
set(handles.ImageClosingRadiusEdit, 'String', sprintf('Image Closing Radius: %1d', handles.ImageClosingRadius));

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageClosingRadiusSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FillRoiHolesCheck_Callback(hObject, eventdata, handles)

% Fetch a Boolean value
handles.FillHoles = get(hObject, 'Value');

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CloseImageCheck_Callback(hObject, eventdata, handles)

% Fetch a Boolean value
handles.CloseImage = get(hObject, 'Value');

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function AutoAdvanceSliceCheck_Callback(hObject, eventdata, handles)

% Fetch a Boolean value
handles.AutoAdvanceSlice = get(hObject, 'Value');

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SliceBackButton_Callback(hObject, eventdata, handles)

% Decrement the Slice
handles.Slice = handles.Slice - 1;

% Wrap round if necessary
if (handles.Slice < 1)
  handles.Slice = handles.NSLICES;
end

% Update the edit window (elsewhere)
set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));

% Update the slider (elsewhere)
set(handles.DisplaySliceSlider, 'Value', handles.Slice);

% Update the current slice location to account for downsampling
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

% Update the HANDLES structure before and after displaying the image (with any ROI's overlaid)
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SliceForwardButton_Callback(hObject, eventdata, handles)

% Increment the Slice
handles.Slice = handles.Slice + 1;

% Wrap round if necessary
if (handles.Slice > handles.NSLICES)
  handles.Slice = 1;
end

% Update the edit window (elsewhere)
set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));

% Update the slider (elsewhere)
set(handles.DisplaySliceSlider, 'Value', handles.Slice);

% Update the current slice location to account for downsampling
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

% Update the HANDLES structure before and after displaying the image (with any ROI's overlaid)
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function EpochBackButton_Callback(hObject, eventdata, handles)

% Decrement the Epoch
handles.Epoch = handles.Epoch - 1;

% Wrap round if necessary
if (handles.Epoch < 1)
  handles.Epoch = handles.NEPOCHS;
end

% Update the edit window (elsewhere)
set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));

% Update the slider (elsewhere)
set(handles.DisplayEpochSlider, 'Value', handles.Epoch);

% Update the HANDLES structure before and after displaying the image (with any ROI's overlaid)
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function EpochForwardButton_Callback(hObject, eventdata, handles)

% Increment the Epoch
handles.Epoch = handles.Epoch + 1;

% Wrap round if necessary
if (handles.Epoch > handles.NEPOCHS)
  handles.Epoch = 1;
end

% Update the edit window (elsewhere)
set(handles.DisplayEpochEdit, 'String', sprintf('  Epoch: %3d', handles.Epoch));

% Update the slider (elsewhere)
set(handles.DisplayEpochSlider, 'Value', handles.Epoch);

% Update the HANDLES structure before and after displaying the image (with any ROI's overlaid)
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);
 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SideUiButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Fetch a string indicating which lung is being selected during flood-filling
handles.Selection = get(eventdata.NewValue, 'String');

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpacityEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpacityEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpacitySlider_Callback(hObject, eventdata, handles)

% Fetch the raw value
Value = get(hObject, 'Value');

% Round to the nearest 1 per cent  
handles.Opacity = 0.01*round(Value/0.01);

% Update the read-only edit window
set(handles.OpacityEdit, 'String', sprintf('Opacity: %.2f', handles.Opacity));

% Update the HANDLES structure before and after displaying the image (with any ROI's overlaid)
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_OpacitySlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the raw value
Value = get(hObject, 'Value');

% Round to the nearest 1 per cent  
handles.Opacity = 0.01*round(Value/0.01);

% Update the read-only edit window
set(handles.OpacityEdit, 'String', sprintf('Opacity: %.2f', handles.Opacity));

% Update the HANDLES structure before and after displaying the image (with any ROI's overlaid)
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpacitySlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to update the display                                                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = UpdateImageDisplay(handles)

% Select a section of the grayscale cine-stack
handles.GrayscaleData = handles.CineStack(:, :, handles.Slice, handles.Epoch);

% Initialise the segmentation data
handles.SegmentationData = handles.Black;  

% Mask the grayscale data by the segmentation if appropriate
switch handles.ProgramState
  case 'Import/Review'
    handles.Masking = handles.Transparent;
    
  case 'Segment'
    handles.RightROI = handles.RightBinaryMask(:, :, handles.Slice);
    handles.LinksROI = handles.LinksBinaryMask(:, :, handles.Slice);
    handles.TotalROI = handles.RightROI | handles.LinksROI;
       
    handles.SegmentationData(handles.RightROI) = handles.Blue;
    handles.SegmentationData(handles.LinksROI) = handles.Red;
    
    handles.Masking = handles.Opacity*double(handles.TotalROI);
end
 
% Now show the grayscale image with its colorbar   
handles.hGrayscaleImage = imagesc(handles.ImageDisplayAxes, handles.GrayscaleData);
caxis(handles.ImageDisplayAxes, [handles.Mini, handles.Maxi]);

handles.ImageDisplayAxes.XTick = [];
handles.ImageDisplayAxes.YTick = [];
handles.ImageDisplayAxes.XTickLabels = [];
handles.ImageDisplayAxes.YTickLabels = [];

handles.GrayscaleColorbar = colorbar(handles.ImageDisplayAxes, 'EastOutside', 'FontSize', 16, 'FontWeight', 'bold');
ylabel(handles.GrayscaleColorbar, 'Grayscale Units', 'FontSize', 16, 'FontWeight', 'bold');
set(handles.ImageDisplayAxes, 'Position', handles.CommonAxesPosition);

% On top of that, the segmented regions of interest
handles.hSegmentationImage = imagesc(handles.SegmentationDisplayAxes, handles.SegmentationData, 'AlphaData', handles.Masking);
caxis(handles.SegmentationDisplayAxes, [handles.SegmentationMini, handles.SegmentationMaxi]);

handles.SegmentationDisplayAxes.Visible = 'off';
handles.SegmentationDisplayAxes.XTick = [];
handles.SegmentationDisplayAxes.YTick = [];
handles.SegmentationDisplayAxes.XTickLabels = [];
handles.SegmentationDisplayAxes.YTickLabels = [];

set(handles.SegmentationDisplayAxes, 'Position', handles.CommonAxesPosition);

% Apply the colormap to the perfusion map axes
colormap(handles.SegmentationDisplayAxes, handles.SegmentationCM);

% Add a basic annotation to the image
if (handles.LabelImages == true)
  r = handles.Reduction;
  text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.SegmentationDisplayAxes, 'Interpreter', 'none');
  text(16.0/r, 32.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.SegmentationDisplayAxes); 
  text(16.0/r, 48.0/r, sprintf('Epoch %3d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.SegmentationDisplayAxes); 
end
  
% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_WindowButtonDownFcn(hObject, eventdata, handles)

% Quit if no review image is present - avoid processing during a possible hiatus between image selections
if (handles.ReviewImageIsPresent == false)
  return;
end

% Quit if not in 'Segment' mode
if strcmpi(handles.ProgramState, 'Import/Review')
  return;
end

% Also, do nothing if an ROI is being created
if (handles.SegmentationInProgress == true)
  return;
end

% Fetch the current point w.r.t. the IMAGE AXES rather than the MAIN FIGURE
P = get(handles.ImageDisplayAxes, 'CurrentPoint');

cx = P(1, 1);
cy = P(1, 2);

% Quit and do nothing if the cursor is outside the currently displayed image
if (cx < handles.MinX) || (cx > handles.MaxX) || (cy < handles.MinY) || (cy > handles.MaxY)
  return;
end

% Initialise the segmentation and update the state variable immediately to disable motion events
handles.SegmentationInProgress = true;
guidata(hObject, handles);

% Disable controls during segmentation - notice the HANDLES update just above
handles = DisableControlsDuringSegmentation(handles);
guidata(hObject, handles);

% Fetch the seed-point for the flood-fill operations
SeedRow = ceil(cy - 0.5);
SeedCol = ceil(cx - 0.5);

% Fetch the section of the cine-stack currently displayed in the image axes
Array = handles.CineStack(:, :, handles.Slice, handles.Epoch);

% Perform the flood-fill operation and assign the resulting ROI appropriately
[ BW, Result ] = pft_Search2D(handles.Selection, ...
                              Array, SeedRow, SeedCol, ...
                              handles.Tolerance, handles.FillHoles, handles.CloseImage, handles.ImageClosingRadius);
                          
switch Result
  case 'Right Lung'
    handles.RightBinaryMask(:, :, handles.Slice) = BW;    
    OutputFileName = fullfile(handles.RoiParentFolder, 'Right Lung', sprintf('Binary-Mask-Slice-%03d.png', handles.Slice));
    imwrite(BW, OutputFileName);
    
  case 'Left Lung'
    handles.LinksBinaryMask(:, :, handles.Slice) = BW;
    OutputFileName = fullfile(handles.RoiParentFolder, 'Left Lung', sprintf('Binary-Mask-Slice-%03d.png', handles.Slice));
    imwrite(BW, OutputFileName);
end

handles.TotalBinaryMask(:, :, handles.Slice) = handles.LinksBinaryMask(:, :, handles.Slice) | handles.RightBinaryMask(:, :, handles.Slice);
    
% Exit from Segmentation mode and update the state variable to re-enable motion events immediately
handles.SegmentationInProgress = false;
guidata(hObject, handles);

% Enable controls during segmentation - notice the HANDLES update just above
handles = EnableControlsAfterSegmentation(handles);
guidata(hObject, handles);

% Update the display - notice the HANDLES update just above
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Step forward in the slice pack if required
if (handles.AutoAdvanceSlice == true)
  pause(1.0);  
  
  handles.Slice = handles.Slice + 1;

  if (handles.Slice > handles.NSLICES)
    handles.Slice = 1;
  end

  set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));

  set(handles.DisplaySliceSlider, 'Value', handles.Slice);

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
  
  guidata(hObject, handles);
  handles = UpdateImageDisplay(handles);
  guidata(hObject, handles);  
end    

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_SizeChangedFcn(hObject, eventdata, handles)

% Locate the axes w.r.t. the figure
handles.CommonAxesPosition = get(handles.ImageDisplayAxes, 'Position');  

AP = handles.CommonAxesPosition;

x0 = AP(1);
y0 = AP(2);
wd = AP(3);
ht = AP(4);

DXL = 8;
DXU = 120;
DYL = 14;
DYU = 10;

x0 = x0 - DXL;
y0 = y0 - DYL;
wd = wd + DXL + DXU;
ht = ht + DYL + DYU;

handles.Rectangle = [ x0 y0 wd ht ];

% Update the HANDLES structure and display the image
guidata(hObject, handles);

end
