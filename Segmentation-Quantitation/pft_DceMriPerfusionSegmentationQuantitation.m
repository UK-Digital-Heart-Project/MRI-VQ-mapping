function varargout = pft_DceMriPerfusionSegmentationQuantitation(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pft_DceMriPerfusionSegmentationQuantitation_OpeningFcn, ...
                   'gui_OutputFcn',  @pft_DceMriPerfusionSegmentationQuantitation_OutputFcn, ...
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

function pft_DceMriPerfusionSegmentationQuantitation_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for pft_DceMriPerfusionSegmentationQuantitation
handles.output = hObject;

% Initialise the program state
handles.ProgramState = 'Import/Review';

% Emphasise that no segmentation is taking place
handles.SegmentationInProgress = false;

% Therefore, there are no 3D segmentation masks as yet
handles.RightBinaryMask = [];
handles.LinksBinaryMask = [];
handles.TotalBinaryMask = [];

% Or 2D single-slice ROI's
handles.RightROI = [];
handles.LinksROI = [];
handles.TotalROI = [];

% Also, there are no polygons available to be re-used
handles.RightPolygon = [];
handles.LinksPolygon = [];

handles.ReuseLastROI = true;

% Also, we have no DICOM header information for the quantitative o/p - this will be read in on entering Segmentation mode
handles.Info = [];

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

% Initialise the image display
handles.Data = zeros([176, 176], 'uint8');

handles.Lower = 0;
handles.Upper = 255.0;
handles.Range = handles.Upper - handles.Lower;

handles.Ceiling = 15.0;
handles.Floor   = 0.0;

handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);
set(handles.hImage, 'HitTest', 'off', 'PickableParts', 'none');
colormap(handles.ImageDisplayAxes, gray(256));

handles.ImageDisplayAxesPosition = get(handles.ImageDisplayAxes, 'Position');

handles.Colorbar = colorbar(handles.ImageDisplayAxes, 'EastOutside', 'FontSize', 16, 'FontWeight', 'bold');

ylabel(handles.Colorbar, 'Arbitrary Units', 'FontSize', 16, 'FontWeight', 'bold');

set(handles.ImageDisplayAxes, 'Position', handles.ImageDisplayAxesPosition);

% Initialise the data source folder and the results folder
fid = fopen('Source-Folder.txt', 'rt');
handles.SourceFolder = fgetl(fid);
fclose(fid);

fid = fopen('Target-Folder.txt', 'rt');
handles.TargetFolder = fgetl(fid);
fclose(fid);

QuantitationFolder = fullfile(handles.TargetFolder, 'Quantitation');

if (exist(QuantitationFolder, 'dir') ~= 7)
  mkdir(QuantitationFolder);
end

ScreenshotsFolder = fullfile(handles.TargetFolder, 'Screenshots');

if (exist(ScreenshotsFolder, 'dir') ~= 7)
  mkdir(ScreenshotsFolder);
end

% Disable some features which apply only to a genuine data set (not the initial blank placeholder)
handles.ReviewMapIsPresent = false;

% Select the map to be imported next (not yet present)
handles.ViewMap = 'PBV';

% Enable censorship of high (and noisy) background values
handles.CensorHighValues = true;

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

% Set the slider steps
set(handles.DisplayCeilingSlider, 'SliderStep', [1.0, 9.0]/99.0);
set(handles.DisplayFloorSlider, 'SliderStep', [1.0, 9.0]/99.0);
set(handles.DisplaySliceSlider, 'SliderStep', [1.0, 8.0]/111.0);

% Initialize the choice and size of colormap
fid = fopen('Colormaps.txt', 'rt');
Strings = textscan(fid, '%s');
fclose(fid);

handles.ColormapNames = Strings{1};
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

% Add listeners for a continuous slider response
hDisplayCeilingSliderListener = addlistener(handles.DisplayCeilingSlider, 'ContinuousValueChange', @CB_DisplayCeilingSlider_Listener);
setappdata(handles.DisplayCeilingSlider, 'MyListener', hDisplayCeilingSliderListener);

hDisplayFloorSliderListener = addlistener(handles.DisplayFloorSlider, 'ContinuousValueChange', @CB_DisplayFloorSlider_Listener);
setappdata(handles.DisplayFloorSlider, 'MyListener', hDisplayFloorSliderListener);

hDisplaySliceSliderListener = addlistener(handles.DisplaySliceSlider, 'ContinuousValueChange', @CB_DisplaySliceSlider_Listener);
setappdata(handles.DisplaySliceSlider, 'MyListener', hDisplaySliceSliderListener);

% Disable warnings about sheets being added to Excel files
warning('off', 'MATLAB:xlswrite:AddSheet'); 

% Update the HANDLES structure
guidata(hObject, handles);

% UIWAIT makes pft_DceMriPerfusionSegmentationQuantitation wait for user response (see UIRESUME)
% uiwait(handles.MainFigure);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = pft_DceMriPerfusionSegmentationQuantitation_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImportMapsButton_Callback(hObject, eventdata, handles)

% Prompt for a MAT file - do nothing if none is chosen
[ FileName, PathName, FilterIndex ] = uigetfile('*.m', 'Select a perfusion MAT file', fullfile(handles.SourceFolder, '*mat'));

if (FilterIndex == 0)
  guidata(hObject, handles);
  return;
end

handles.SourceFolder   = PathName;
handles.SourceFileName = FileName;

p = strfind(FileName, '.');
q = p(end);
r = q - 1;

handles.FileNameStub = FileName(1:r);

% Read in the maps, which are bundled in a structure called Mat, retained to save memory and time
wb = waitbar(0.5, 'Loading data - please wait ... ');

handles.Mat = [];
handles.Mat = load(fullfile(PathName, FileName));

pause(0.5);
waitbar(1.0, wb, 'Loading complete');
pause(0.5);
delete(wb);

% Update the first read-only edit window with the source filename
set(handles.MapFileEdit, 'String', sprintf('  Map Pickle File:       %s', handles.SourceFileName));

% Extract the different maps from the data pickle - ignore the MPA ROI
handles.PBV           = handles.Mat.AllPBV;
handles.UnfilteredPBV = handles.Mat.UnfilteredAllPBV;
handles.PBF           = handles.Mat.AllPBF;
handles.UnfilteredPBF = handles.Mat.UnfilteredAllPBF;
handles.MTT           = handles.Mat.AllMTT;
handles.TTP           = handles.Mat.AllTTP;
handles.Mask          = (handles.TTP > 0);

% Display the image size
Dims = size(handles.PBV);

handles.NROWS   = Dims(1);
handles.NCOLS   = Dims(2);
handles.NSLICES = Dims(3);

set(handles.ImageSizeEdit, 'String', sprintf('  Size:   %1d / %1d / %1d', Dims(1), Dims(2), Dims(3)));

handles.MinX = 0.5;
handles.MaxX = double(handles.NCOLS + 0.5);
handles.MinY = 0.5;
handles.MaxY = double(handles.NROWS + 0.5);

% Infer the downsampling factor from the image dimensions
switch handles.NSLICES
  case 112
    handles.Reduction = 1;
  case 56
    handles.Reduction = 2;
  case 28
    handles.Reduction = 4;
  case 14
    handles.Reduction = 8;
end

% Update the slider settings if necessary
set(handles.DisplayCeilingSlider, 'Enable', 'on');
set(handles.DisplayFloorSlider, 'Enable', 'on');

% Adjust the slider settings for the Slice, just in case the doensampling factor has changed between data sets
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
end

% Update the Slice edit window and its corresponding slider
set(handles.DisplaySliceEdit, 'String', sprintf('  Slice: %3d', handles.Slice));
set(handles.DisplaySliceSlider, 'Value', handles.Slice);

% Select the map to be viewed, and set units and scaling factors
switch handles.ViewMap
  case 'PBV'
    handles.Map = handles.PBV;
    handles.Units     = 'ml/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'Unfiltered PBV'
    handles.Map = handles.UnfilteredPBV;
    handles.Units     = 'ml/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'PBF'
    handles.Map = handles.PBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Unfiltered PBF'
    handles.Map = handles.UnfilteredPBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'MTT'
    handles.Map = handles.MTT;
    handles.Units     = 'sec';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'TTP'
    handles.Map = handles.TTP;
    handles.Units     = 'sec';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Processing Mask'
    handles.Map = handles.Mask;
    handles.Units     = '';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
end  

% Rescale the data for floating-point display
handles.Map = handles.Intercept + handles.Slope*double(handles.Map);

% Censor high values in the working copy of the displayed map, but leave the original maps alone (so that censorship can be toggled on and off)
if (handles.CensorHighValues == true)
  switch handles.ViewMap
    case { 'PBV', 'Unfiltered PBV' }
      handles.Map(handles.Map > 100.0) = 0.0;
    case { 'PBF', 'Unfiltered PBF' }
      handles.Map(handles.Map > 6000.0) = 0.0;
    case { 'MTT', 'TTP' }
      handles.Map(handles.Map > 60.0) = 0.0;
    case 'Processing Mask'
      % Nothing to do here
  end
end    

% Display the current slice
handles.Lower = min(handles.Map(:));
handles.Upper = max(handles.Map(:));
handles.Range = handles.Upper - handles.Lower;

handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Enable the option to proceed to segmentation
set(handles.SegmentRadio, 'Enable', 'on');

% Enable some interactivity with the displayed image
handles.ReviewMapIsPresent = true;

% Allow the image display axes to be captured
set(handles.CaptureDisplayButton, 'Enable', 'on');

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImportMapsButton_CreateFcn(hObject, eventdata, handles)

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

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

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
if (handles.Ceiling - handles.Floor <= 1)
  handles.Floor = handles.Ceiling - 1.0;
  set(handles.DisplayFloorSlider, 'Value', handles.Floor);
  set(handles.DisplayFloorEdit, 'String', sprintf('  Floor:   %3d %%', handles.Floor));
end

% Display the current slice
handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

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
if (handles.Ceiling - handles.Floor <= 1)
  handles.Ceiling = handles.Floor + 1.0;
  set(handles.DisplayCeilingSlider, 'Value', handles.Ceiling);
  set(handles.DisplayCeilingEdit, 'String', sprintf('  Ceiling: %3d %%', handles.Ceiling));
end

% Display the current slice
handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

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
if (handles.Ceiling - handles.Floor <= 1)
  handles.Ceiling = handles.Floor + 1.0;
  set(handles.DisplayCeilingSlider, 'Value', handles.Ceiling);
  set(handles.DisplayCeilingEdit, 'String', sprintf('  Ceiling: %3d %%', handles.Ceiling));
end

% Display the current slice
handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

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

% Display the current slice
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Update the HANDLES structure
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

% Display the current slice
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

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

% Check for the one exceptional case which does not take a size parameter
if strcmpi(handles.CurrentColormapName, 'vga')
  handles.Colormap = vga;
else
  handles.Colormap = eval(sprintf('%s(%s)', handles.CurrentColormapName, handles.CurrentColormapSize));
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

% Check for the one exceptional case which does not take a size parameter
if strcmpi(handles.CurrentColormapName, 'vga')
  handles.Colormap = vga;
else
  handles.Colormap = eval(sprintf('%s(%s)', handles.CurrentColormapName, handles.CurrentColormapSize));
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
if (handles.ReviewMapIsPresent == false)
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

handles.PixelValue = handles.Data(handles.PixelRow, handles.PixelCol);

set(handles.ImageRowEdit, 'String', sprintf('  Row:    %1d', handles.PixelRow));
set(handles.ImageColumnEdit, 'String', sprintf('  Column: %1d', handles.PixelCol));

set(handles.ImagePixelValueEdit, 'String', sprintf('  Pixel Value: %.4f %s', handles.PixelValue, handles.Units));

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CaptureDisplayButton_Callback(hObject, eventdata, handles)

F = getframe(handles.ImageDisplayAxes);
X = F.cdata;

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

[ FileName, PathName, FilterIndex ] = uiputfile(FilterSpec, DialogTitle, DefaultName);

if (FilterIndex ~= 0)
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

function QuantifyButton_Callback(hObject, eventdata, handles)

% Prompt for a filename to save the results
Listing = dir(fullfile(handles.TargetFolder, 'Quantitation', sprintf('%s_QUANTIFICATION_*.xlsx', handles.FileNameStub)));
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries(Folders) = [];
Entries = sort(Entries);
Entries = Entries';

if isempty(Entries)
  Suffix = '001';  
    
  DefaultName = fullfile(handles.TargetFolder, 'Quantitation', sprintf('%s_QUANTIFICATION_001.xlsx', handles.FileNameStub));
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
    
  DefaultName = fullfile(handles.TargetFolder, 'Quantitation', sprintf('%s_QUANTIFICATION_%s.xlsx', handles.FileNameStub, Suffix));
end

FilterSpec  = fullfile(handles.TargetFolder, 'Quantitation', '*.xlsx');
DialogTitle = 'Save Statistics To';

[ FileName, PathName, FilterIndex ] = uiputfile(FilterSpec, DialogTitle, DefaultName);

% Quit if no file is chosen
if (FilterIndex == 0)
  guidata(hObject, handles);
  return;
end

% Point to the output file and update the read-only edit window
XlsxFileName = fullfile(PathName, FileName);

set(handles.XlsxSummaryFileEdit, 'String', sprintf('  XLSX Summary File:     %s', FileName));

NTABS = 7;

wb = waitbar(0, 'Saving statistics ...');

% Some vital statistics first
DR = handles.Info.PixelSpacing(1);  % In mm
ST = handles.Info.SliceThickness;   % In mm
DV = ST*DR^2;                       % In mm^3

[ NR, NC, NP ] = size(handles.Map);

Head = { 'Rows', 'Column', 'Planes', 'In-plane resolution / mm', 'Slice thickness / mm', 'Volume / mm^3' };
Data = {  NR,     NC,       NP,       DR,                         ST,                     DV             };
Full = vertcat(Head, Data);

xlswrite(XlsxFileName, Full, 'Reesolution');

waitbar(double(1)/double(NTABS + 1), wb, sprintf('Saved 1 out of %1d tabs', NTABS));

% Count the segmented voxels below threshold to obtain a "deficit fraction"
RightSegmentedPixels = sum(handles.RightBinaryMask(:));
RightSegmentedVolume = 0.001*double(RightSegmentedPixels)*DV;
RightDisjunction     = handles.RightBinaryMask & ~handles.Mask;
RightNeglectedPixels = sum(RightDisjunction(:));
RightNeglectedVolume = 0.001*double(RightNeglectedPixels)*DV;
RightDeficit         = 100.0*double(RightNeglectedPixels)/double(RightSegmentedPixels);

LinksSegmentedPixels = sum(handles.LinksBinaryMask(:));
LinksSegmentedVolume = 0.001*double(LinksSegmentedPixels)*DV;
LinksDisjunction     = handles.LinksBinaryMask & ~handles.Mask;
LinksNeglectedPixels = sum(LinksDisjunction(:));
LinksNeglectedVolume = 0.001*double(LinksNeglectedPixels)*DV;
LinksDeficit         = 100.0*double(LinksNeglectedPixels)/double(LinksSegmentedPixels);

TotalSegmentedPixels = sum(handles.TotalBinaryMask(:));
TotalSegmentedVolume = 0.001*double(TotalSegmentedPixels)*DV;
TotalDisjunction     = handles.TotalBinaryMask & ~handles.Mask;
TotalNeglectedPixels = sum(TotalDisjunction(:));
TotalNeglectedVolume = 0.001*double(TotalNeglectedPixels)*DV;
TotalDeficit         = 100.0*double(TotalNeglectedPixels)/double(TotalSegmentedPixels);

Head = { 'Right voxels selected', 'Volume / ml',         'Right voxels below threshold', 'Volume / ml',         'Right percentage deficit', ...
         'Left voxels selected',  'Volume / ml',         'Left voxels below threshold',  'Volume / ml',         'Left percentage deficit', ...
         'Total voxels selected', 'Volume / ml',         'Total voxels below threshold', 'Volume / ml',         'Total percentage deficit' };
Data = {  RightSegmentedPixels,    RightSegmentedVolume,  RightNeglectedPixels,           RightNeglectedVolume,  RightDeficit, ...
          LinksSegmentedPixels,    LinksSegmentedVolume,  LinksNeglectedPixels,           LinksNeglectedVolume,  LinksDeficit, ...
          TotalSegmentedPixels,    TotalSegmentedVolume,  TotalNeglectedPixels,           TotalNeglectedVolume,  TotalDeficit };
Full = vertcat(Head, Data);

xlswrite(XlsxFileName, Full, 'Deficits');

waitbar(double(2)/double(NTABS + 1), wb, sprintf('Saved 2 out of %1d tabs', NTABS));

% Create volumes of segmented and processed voxels for the upcoming statistics
RightOverlap = handles.RightBinaryMask & handles.Mask;
LinksOverlap = handles.LinksBinaryMask & handles.Mask;
TotalOverlap = handles.TotalBinaryMask & handles.Mask;

% Calculate statistics for the PBV
Intercept = 0.0;
Slope     = 0.01;

pbv = Intercept + Slope*double(handles.PBV(RightOverlap));

if (handles.CensorHighValues == true)
  pbv(pbv > 100.0) = 100.0;
end

RightMu     = mean(pbv);
RightMedian = median(pbv);
RightSD     = std(pbv);
RightMini   = min(pbv);
RightMaxi   = max(pbv);

pbv = Intercept + Slope*double(handles.PBV(LinksOverlap));

if (handles.CensorHighValues == true)
  pbv(pbv > 100.0) = 100.0;
end

LinksMu     = mean(pbv);
LinksMedian = median(pbv);
LinksSD     = std(pbv);
LinksMini   = min(pbv);
LinksMaxi   = max(pbv);

pbv = Intercept + Slope*double(handles.PBV(TotalOverlap));

if (handles.CensorHighValues == true)
  pbv(pbv > 100.0) = 100.0;
end

TotalMu     = mean(pbv);
TotalMedian = median(pbv);
TotalSD     = std(pbv);
TotalMini   = min(pbv);
TotalMaxi   = max(pbv);

Head = { 'Right mean PBV / ml/(100 ml)', 'Median',     'S.D.',   'Minimum',  'Maximum', ...
         'Left mean PBV / ml/(100 ml)',  'Median',     'S.D.',   'Minimum',  'Maximum', ...
         'Total mean PBV / ml/(100 ml)', 'Median',     'S.D.',   'Minimum',  'Maximum' };
Data = {  RightMu,                        RightMedian,  RightSD,  RightMini,  RightMaxi, ...
          LinksMu,                        LinksMedian,  LinksSD,  LinksMini,  LinksMaxi, ...
          TotalMu,                        TotalMedian,  TotalSD,  TotalMini,  TotalMaxi };
Full = vertcat(Head, Data);

xlswrite(XlsxFileName, Full, 'PBV');

waitbar(double(3)/double(NTABS + 1), wb, sprintf('Saved 3 out of %1d tabs', NTABS));

% Calculate statistics for the PBF
Intercept = 0.0;
Slope     = 1.0;

pbf = Intercept + Slope*double(handles.PBF(RightOverlap));

if (handles.CensorHighValues == true)
  pbf(pbf > 6000.0) = 6000.0;
end

RightMu     = mean(pbf);
RightMedian = median(pbf);
RightSD     = std(pbf);
RightMini   = min(pbf);
RightMaxi   = max(pbf);

pbf = Intercept + Slope*double(handles.PBF(LinksOverlap));

if (handles.CensorHighValues == true)
  pbf(pbf > 6000.0) = 6000.0;
end

LinksMu     = mean(pbf);
LinksMedian = median(pbf);
LinksSD     = std(pbf);
LinksMini   = min(pbf);
LinksMaxi   = max(pbf);

pbf = Intercept + Slope*double(handles.PBF(TotalOverlap));

if (handles.CensorHighValues == true)
  pbf(pbf > 6000.0) = 6000.0;
end

TotalMu     = mean(pbf);
TotalMedian = median(pbf);
TotalSD     = std(pbf);
TotalMini   = min(pbf);
TotalMaxi   = max(pbf);

Head = { 'Right mean PBF / (ml/min)/(100 ml)', 'Median',     'S.D.',   'Minimum',  'Maximum', ...
         'Left mean PBF / (ml/min)/(100 ml)',  'Median',     'S.D.',   'Minimum',  'Maximum', ...
         'Total mean PBF / (ml/min)/(100 ml)', 'Median',     'S.D.',   'Minimum',  'Maximum' };
Data = {  RightMu,                              RightMedian,  RightSD,  RightMini,  RightMaxi, ...
          LinksMu,                              LinksMedian,  LinksSD,  LinksMini,  LinksMaxi, ...
          TotalMu,                              TotalMedian,  TotalSD,  TotalMini,  TotalMaxi };
Full = vertcat(Head, Data);

xlswrite(XlsxFileName, Full, 'PBF');

waitbar(double(4)/double(NTABS + 1), wb, sprintf('Saved 4 out of %1d tabs', NTABS));

% Calculate statistics for the MTT
Intercept = - 10.0;
Slope     = 0.001;

mtt = Intercept + Slope*double(handles.MTT(RightOverlap));

mtt(mtt < 0.0) = 0.0;

if (handles.CensorHighValues == true)
  mtt(mtt > 60.0) = 60.0;
end

RightMu     = mean(mtt);
RightMedian = median(mtt);
RightSD     = std(mtt);
RightMini   = min(mtt);
RightMaxi   = max(mtt);

mtt = Intercept + Slope*double(handles.MTT(LinksOverlap));

mtt(mtt < 0.0) = 0.0;

if (handles.CensorHighValues == true)
  mtt(mtt > 60.0) = 60.0;
end

LinksMu     = mean(mtt);
LinksMedian = median(mtt);
LinksSD     = std(mtt);
LinksMini   = min(mtt);
LinksMaxi   = max(mtt);

mtt = Intercept + Slope*double(handles.MTT(TotalOverlap));

mtt(mtt < 0.0) = 0.0;

if (handles.CensorHighValues == true)
  mtt(mtt > 60.0) = 60.0;
end

TotalMu     = mean(mtt);
TotalMedian = median(mtt);
TotalSD     = std(mtt);
TotalMini   = min(mtt);
TotalMaxi   = max(mtt);

Head = { 'Right mean MTT / sec', 'Median',     'S.D.',   'Minimum',  'Maximum', ...
         'Left mean MTT / sec',  'Median',     'S.D.',   'Minimum',  'Maximum', ...
         'Total mean MTT / sec', 'Median',     'S.D.',   'Minimum',  'Maximum' };
Data = {  RightMu,                RightMedian,  RightSD,  RightMini,  RightMaxi, ...
          LinksMu,                LinksMedian,  LinksSD,  LinksMini,  LinksMaxi, ...
          TotalMu,                TotalMedian,  TotalSD,  TotalMini,  TotalMaxi };
Full = vertcat(Head, Data);

xlswrite(XlsxFileName, Full, 'MTT');

waitbar(double(5)/double(NTABS + 1), wb, sprintf('Saved 5 out of %1d tabs', NTABS));

% Calculate statistics for the TTP
Intercept = - 10.0;
Slope     = 0.001;

ttp = Intercept + Slope*double(handles.TTP(RightOverlap));

ttp(ttp < 0.0) = 0.0;

if (handles.CensorHighValues == true)
  ttp(ttp > 60.0) = 60.0;
end

RightMu     = mean(ttp);
RightMedian = median(ttp);
RightSD     = std(ttp);
RightMini   = min(ttp);
RightMaxi   = max(ttp);

ttp = Intercept + Slope*double(handles.TTP(LinksOverlap));

ttp(ttp < 0.0) = 0.0;

if (handles.CensorHighValues == true)
  ttp(ttp > 60.0) = 60.0;
end

LinksMu     = mean(ttp);
LinksMedian = median(ttp);
LinksSD     = std(ttp);
LinksMini   = min(ttp);
LinksMaxi   = max(ttp);

ttp = Intercept + Slope*double(handles.TTP(TotalOverlap));

ttp(ttp < 0.0) = 0.0;

if (handles.CensorHighValues == true)
  ttp(ttp > 60.0) = 60.0;
end

TotalMu     = mean(ttp);
TotalMedian = median(ttp);
TotalSD     = std(ttp);
TotalMini   = min(ttp);
TotalMaxi   = max(ttp);

Head = { 'Right mean TTP / sec', 'Median',     'S.D.',   'Minimum',  'Maximum', ...
         'Left mean TTP / sec',  'Median',     'S.D.',   'Minimum',  'Maximum', ...
         'Total mean TTP / sec', 'Median',     'S.D.',   'Minimum',  'Maximum' };
Data = {  RightMu,                RightMedian,  RightSD,  RightMini,  RightMaxi, ...
          LinksMu,                LinksMedian,  LinksSD,  LinksMini,  LinksMaxi, ...
          TotalMu,                TotalMedian,  TotalSD,  TotalMini,  TotalMaxi };
Full = vertcat(Head, Data);

xlswrite(XlsxFileName, Full, 'TTP');

waitbar(double(6)/double(NTABS + 1), wb, sprintf('Saved 6 out of %1d tabs', NTABS));

% Note any data censorship
if (handles.CensorHighValues == true)
  Answer = 'Yes';
else
  Answer = 'No';
end

Head = { 'High values censored' };
Data = {  Answer };
Full = vertcat(Head, Data);

xlswrite(XlsxFileName, Full, 'Censorship');

waitbar(double(7)/double(NTABS + 1), wb, sprintf('Saved 7 out of %1d tabs', NTABS));

% Quit gracefully
pause(0.5);
waitbar(1, wb, 'All tabs saved !');
pause(0.5);
delete(wb);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ViewMapButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Update the choice of map to be displayed
handles.ViewMap = get(eventdata.NewValue, 'String');

% Quit if there is no data set loaded
if (handles.ReviewMapIsPresent == false)
  guidata(hObject, handles);
  return;
end  

% Select the map to be viewed, and set units and scaling factors
switch handles.ViewMap
  case 'PBV'
    handles.Map = handles.PBV;
    handles.Units     = 'ml/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'Unfiltered PBV'
    handles.Map = handles.UnfilteredPBV;
    handles.Units     = 'ml/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'PBF'
    handles.Map = handles.PBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Unfiltered PBF'
    handles.Map = handles.UnfilteredPBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'MTT'
    handles.Map = handles.MTT;
    handles.Units     = 'sec';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'TTP'
    handles.Map = handles.TTP;
    handles.Units     = 'sec';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Processing Mask'
    handles.Map = handles.Mask;
    handles.Units     = '';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
end       

% Rescale the data for floating-point display
handles.Map = handles.Intercept + handles.Slope*double(handles.Map);

if (handles.CensorHighValues == true)
  switch handles.ViewMap
    case { 'PBV', 'Unfiltered PBV' }
      handles.Map(handles.Map > 100.0) = 0.0;
    case { 'PBF', 'Unfiltered PBF' }
      handles.Map(handles.Map > 6000.0) = 0.0;
    case { 'MTT', 'TTP' }
      handles.Map(handles.Map > 60.0) = 0.0;
    case 'Processing Mask'
      % Nothing to do here
  end
end  

% Display the current slice
handles.Lower = min(handles.Map(:));
handles.Upper = max(handles.Map(:));
handles.Range = handles.Upper - handles.Lower;

handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Update the HANDLES structure
guidata(hObject, handles);

end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_CloseRequestFcn(hObject, eventdata, handles)

% Re-enable a warning that was disabled on start-up
warning('on', 'MATLAB:xlswrite:AddSheet');

% Now exit by deleting the figure
delete(hObject);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CensorHighValuesCheck_Callback(hObject, eventdata, handles)

% Check whether censorship is enabled
handles.CensorHighValues = get(hObject, 'Value');

% Quit if there is no data set loaded
if (handles.ReviewMapIsPresent == false)
  guidata(hObject, handles);
  return;
end  

% Select the map to be viewed, and set units and scaling factors
switch handles.ViewMap
  case 'PBV'
    handles.Map = handles.PBV;
    handles.Units     = 'ml/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'Unfiltered PBV'
    handles.Map = handles.UnfilteredPBV;
    handles.Units     = 'ml/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'PBF'
    handles.Map = handles.PBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Unfiltered PBF'
    handles.Map = handles.UnfilteredPBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'MTT'
    handles.Map = handles.MTT;
    handles.Units     = 'sec';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'TTP'
    handles.Map = handles.TTP;
    handles.Units     = 'sec';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Processing Mask'
    handles.Map = handles.Mask;
    handles.Units     = '';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
end       

% Rescale the data for floating-point display
handles.Map = handles.Intercept + handles.Slope*double(handles.Map);

if (handles.CensorHighValues == true)
  switch handles.ViewMap
    case { 'PBV', 'Unfiltered PBV' }
      handles.Map(handles.Map > 100.0) = 0.0;
    case { 'PBF', 'Unfiltered PBF' }
      handles.Map(handles.Map > 6000.0) = 0.0;
    case { 'MTT', 'TTP' }
      handles.Map(handles.Map > 60.0) = 0.0;
    case 'Processing Mask'
      % Nothing to do here
  end
end  

% Display the current slice
handles.Lower = min(handles.Map(:));
handles.Upper = max(handles.Map(:));
handles.Range = handles.Upper - handles.Lower;

handles.Mini = handles.Lower + handles.Range*(handles.Floor/100.0);
handles.Maxi = handles.Lower + handles.Range*(handles.Ceiling/100.0);

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapFileEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapFileEdit_CreateFcn(hObject, eventdata, handles)

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

function XlsxSummaryFileEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function XlsxSummaryFileEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CreateRightLungROIButton_Callback(hObject, eventdata, handles)

% Disable any response to motion events immediately
handles.SegmentationInProgress = true;
guidata(hObject, handles);

% Disable controls during segmentation - notice the HANDLES update just above
handles = DisableControlsDuringSegmentation(handles);
guidata(hObject, handles);

% Update the display - notice the HANDLES update just above
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Prompt for a polygon defining the outline of the right lung
if (handles.ReuseLastROI == true) && ~isempty(handles.RightPolygon)
  hp = impoly(handles.ImageDisplayAxes, handles.RightPolygon);
else
  hp = impoly(handles.ImageDisplayAxes);
end

hp.Deletable = false;
setVerticesDraggable(hp, true);
wait(hp);

BW = createMask(hp);
XY = getPosition(hp);
delete(hp);

handles.RightBinaryMask(:, :, handles.Slice) = logical(BW);

handles.RightPolygon = XY;

% Re-enable most of the controls
guidata(hObject, handles);
handles = EnableControlsDuringSegmentation(handles);
guidata(hObject, handles);

% Exit from segmentation mode - note the HANDLES update above
handles.SegmentationInProgress = false;
guidata(hObject, handles);

% Update the display - note the HANDLES update above
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Write out the binary mask to the appropriate folder
OutputFileName = fullfile(handles.TargetFolder, 'Regions of Interest', handles.FileNameStub, 'Right Lung', ...
                          sprintf('Binary-Mask-Slice-%03d.png', handles.Slice));
                      
imwrite(BW, OutputFileName);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CreateLeftLungROIButton_Callback(hObject, eventdata, handles)

% Disable any response to motion events immediately
handles.SegmentationInProgress = true;
guidata(hObject, handles);

% Disable controls during segmentation - notice the HANDLES update just above
handles = DisableControlsDuringSegmentation(handles);
guidata(hObject, handles);

% Update the display - notice the HANDLES update just above
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Prompt for a polygon defining the outline of the right lung
if (handles.ReuseLastROI == true) && ~isempty(handles.LinksPolygon)
  hp = impoly(handles.ImageDisplayAxes, handles.LinksPolygon);
else
  hp = impoly(handles.ImageDisplayAxes);
end

hp.Deletable = false;
setVerticesDraggable(hp, true);
wait(hp);

BW = createMask(hp);
XY = getPosition(hp);
delete(hp);

handles.LinksBinaryMask(:, :, handles.Slice) = logical(BW);

handles.LinksPolygon = XY;

% Re-enable most of the controls
guidata(hObject, handles);
handles = EnableControlsDuringSegmentation(handles);
guidata(hObject, handles);

% Exit from segmentation mode - note the HANDLES update above
handles.SegmentationInProgress = false;
guidata(hObject, handles);

% Update the display - note the HANDLES update above
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Write out the binary mask to the appropriate folder
OutputFileName = fullfile(handles.TargetFolder, 'Regions of Interest', handles.FileNameStub, 'Left Lung', ...
                          sprintf('Binary-Mask-Slice-%03d.png', handles.Slice));
                      
imwrite(BW, OutputFileName);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DeleteRightLungROIButton_Callback(hObject, eventdata, handles)

% Set the local slice-wise binary mask to false
handles.RightBinaryMask(:, :, handles.Slice) = false;

% Update the display
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Write out the binary mask to the appropriate folder
OutputFileName = fullfile(handles.TargetFolder, 'Regions of Interest', handles.FileNameStub, 'Right Lung', ...
                          sprintf('Binary-Mask-Slice-%03d.png', handles.Slice));
                      
BW = handles.RightBinaryMask(:, :, handles.Slice);
                      
imwrite(BW, OutputFileName);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DeleteLeftLungROIButton_Callback(hObject, eventdata, handles)

% Set the local slice-wise binary mask to false
handles.LinksBinaryMask(:, :, handles.Slice) = false;

% Update the display
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

% Write out the binary mask to the appropriate folder
OutputFileName = fullfile(handles.TargetFolder, 'Regions of Interest', handles.FileNameStub, 'Left Lung', ...
                          sprintf('Binary-Mask-Slice-%03d.png', handles.Slice));
                      
BW = handles.LinksBinaryMask(:, :, handles.Slice);
                      
imwrite(BW, OutputFileName);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ReuseLastROICheck_Callback(hObject, eventdata, handles)

% Just fetch the value - any side-effects take place later, not immediately
handles.ReuseLastROI = get(hObject, 'Value');

% Update the HANDLES structure
guidata(hObject, handles);

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

% The Display Menu controls - note that "Import Maps" will always be disabled in Segmentation mode
set(handles.PBVRadio, 'Enable', 'off');
set(handles.PBFRadio, 'Enable', 'off');
set(handles.MTTRadio, 'Enable', 'off');
set(handles.TTPRadio, 'Enable', 'off');
set(handles.ProcessingMaskRadio, 'Enable', 'off');

set(handles.CensorHighValuesCheck, 'Enable', 'off');
set(handles.CaptureDisplayButton, 'Enable', 'off');

% And finally, the segmentation controls themselves
set(handles.ReuseLastROICheck, 'Enable', 'off');
set(handles.CreateRightLungROIButton, 'Enable', 'off');
set(handles.DeleteRightLungROIButton, 'Enable', 'off');
set(handles.CreateLeftLungROIButton, 'Enable', 'off');
set(handles.DeleteLeftLungROIButton, 'Enable', 'off');
set(handles.QuantifyButton, 'Enable', 'off');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to re-enable inactive controls during segmentation                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = EnableControlsDuringSegmentation(handles)

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

% The Display Menu controls - note that "Import Maps" will always be disabled in Segmentation mode
set(handles.PBVRadio, 'Enable', 'on');
set(handles.PBFRadio, 'Enable', 'on');
set(handles.MTTRadio, 'Enable', 'on');
set(handles.TTPRadio, 'Enable', 'on');
set(handles.ProcessingMaskRadio, 'Enable', 'on');

set(handles.CensorHighValuesCheck, 'Enable', 'on');
set(handles.CaptureDisplayButton, 'Enable', 'on');

% And finally, the segmentation controls themselves
set(handles.ReuseLastROICheck, 'Enable', 'on');
set(handles.CreateRightLungROIButton, 'Enable', 'on');
set(handles.DeleteRightLungROIButton, 'Enable', 'on');
set(handles.CreateLeftLungROIButton, 'Enable', 'on');
set(handles.DeleteLeftLungROIButton, 'Enable', 'on');
set(handles.QuantifyButton, 'Enable', 'on');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to disable the segmentation controls during import/review                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = DisableSegmentationControls(handles)

% All of these controls live in the same UI panel
set(handles.ReuseLastROICheck, 'Enable', 'off');
set(handles.CreateRightLungROIButton, 'Enable', 'off');
set(handles.DeleteRightLungROIButton, 'Enable', 'off');
set(handles.CreateLeftLungROIButton, 'Enable', 'off');
set(handles.DeleteLeftLungROIButton, 'Enable', 'off');
set(handles.QuantifyButton, 'Enable', 'off');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to re-enable the segmentation controls segmentation                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = EnableSegmentationControls(handles)

% All of these controls live in the same UI panel
set(handles.ReuseLastROICheck, 'Enable', 'on');
set(handles.CreateRightLungROIButton, 'Enable', 'on');
set(handles.DeleteRightLungROIButton, 'Enable', 'on');
set(handles.CreateLeftLungROIButton, 'Enable', 'on');
set(handles.DeleteLeftLungROIButton, 'Enable', 'on');
set(handles.QuantifyButton, 'Enable', 'on');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to update the display                                                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = UpdateImageDisplay(handles)

handles.Data = handles.Map(:, :, handles.Slice);

if strcmpi(handles.ProgramState, 'Segment') && (handles.SegmentationInProgress == false)
  handles.RightROI = handles.RightBinaryMask(:, :, handles.Slice);
  handles.LinksROI = handles.LinksBinaryMask(:, :, handles.Slice);
  handles.TotalROI = handles.RightROI | handles.LinksROI;
  
  if any(handles.TotalROI(:))
    switch handles.ViewMap
      case { 'PBV', 'Unfiltered PBV', 'PBF', 'Unfiltered PBF' }
        handles.Data(~handles.TotalROI) = 0.0;
      case { 'MTT', 'TTP' } 
        handles.Data(~handles.TotalROI) = - 10.0;
    end
  end
end

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);

handles.ImageDisplayAxesPosition = get(handles.ImageDisplayAxes, 'Position');

handles.Colorbar = colorbar(handles.ImageDisplayAxes, 'EastOutside', 'FontSize', 16, 'FontWeight', 'bold');

ylabel(handles.Colorbar, handles.Units, 'FontSize', 16, 'FontWeight', 'bold');

set(handles.ImageDisplayAxes, 'Position', handles.ImageDisplayAxesPosition);

% Apply the colormap to the image axes
colormap(handles.ImageDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
r = handles.Reduction;
text(16.0/r, 16.0/r, handles.FileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');
text(16.0/r, 48.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes); 

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
    set(handles.ImportMapsButton, 'Enable', 'on');
  case 'Segment'
    guidata(hObject, handles);    
    handles = EnableSegmentationControls(handles);
    guidata(hObject, handles);
    set(handles.ImportMapsButton, 'Enable', 'off');
end        
          
% Update the folder names in the read-only edit windows
switch handles.ProgramState
    
  case 'Import/Review'
    set(handles.RightLungROIFolderEdit, 'String', '  Right Lung ROI Folder:');
    set(handles.LinksLungROIFolderEdit, 'String', '  Left Lung ROI Folder: ');    
   
  case 'Segment'
    % Read in a DICOM header for a later possible quantitation
    handles.Info = pft_ReadCommonDicomHeader(fullfile(handles.SourceFolder, handles.FileNameStub, 'PBV'));

    % Read in the right binary mask stack
    handles.RightLungFolder = fullfile(handles.TargetFolder, 'Regions of Interest', handles.FileNameStub, 'Right Lung');
  
    if (exist(handles.RightLungFolder, 'dir') ~= 7)
      mkdir(handles.RightLungFolder);
    end
  
    handles.RightBinaryMask = pft_ReadBinaryMaskStack(handles.RightLungFolder, size(handles.Map));
  
    p = strfind(handles.RightLungFolder, handles.FileNameStub);
    q = p(1);
    
    set(handles.RightLungROIFolderEdit, 'String', sprintf('  Right Lung ROI Folder: ..%c%s', filesep, handles.RightLungFolder(q:end)));
  
    % Read in the left binary mask stack
    handles.LinksLungFolder = fullfile(handles.TargetFolder, 'Regions of Interest', handles.FileNameStub, 'Left Lung');
  
    if (exist(handles.LinksLungFolder, 'dir') ~= 7)
      mkdir(handles.LinksLungFolder);
    end
  
    handles.LinksBinaryMask = pft_ReadBinaryMaskStack(handles.LinksLungFolder, size(handles.Map));
  
    p = strfind(handles.LinksLungFolder, handles.FileNameStub);
    q = p(1);
    
    set(handles.LinksLungROIFolderEdit, 'String', sprintf('  Left Lung ROI Folder:  ..%c%s', filesep, handles.LinksLungFolder(q:end)));
  
    % Combine the two maps
    handles.TotalBinaryMask = handles.RightBinaryMask | handles.LinksBinaryMask;
    
end    

% Now update the image display
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end
