function varargout = pft_CreatePerfusionOverlaysMacOS(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pft_CreatePerfusionOverlaysMacOS_OpeningFcn, ...
                   'gui_OutputFcn',  @pft_CreatePerfusionOverlaysMacOS_OutputFcn, ...
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

function pft_CreatePerfusionOverlaysMacOS_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for pft_CreatePerfusionOverlaysMacOS
handles.output = hObject;

% Note that there is no cine-stack present to review
handles.ReviewImageIsPresent = false;

% Emphasise that no i/p or o/p is taking place
handles.InputInProgress  = false;
handles.OutputInProgress = false;

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
MP         = get(0, 'MonitorPositions');
ScreenSize = MP(end, :);
FigureSize = ScreenSize;

% FigureSize = get(hObject, 'Position');

% X0 = ScreenSize(1);
% Y0 = ScreenSize(2);
% WD = ScreenSize(3);
% HT = ScreenSize(4);
% 
% wd = FigureSize(3);
% ht = FigureSize(4);
% 
% FigureSize(1) = X0 + (WD - wd)/2;
% FigureSize(2) = Y0 + (HT - ht)/2;

FigureSize(1) = FigureSize(1) - 500;
FigureSize(2) = FigureSize(2) - 500;

set(hObject, 'Units', 'pixels', 'Position', FigureSize);

% Initialise the grayscale display
handles.GrayscaleData = zeros([176, 176], 'uint8');

handles.GrayscaleLower = 0;
handles.GrayscaleUpper = 255.0;
handles.GrayscaleRange = handles.GrayscaleUpper - handles.GrayscaleLower;

handles.GrayscaleCeiling = 15.0;
handles.GrayscaleFloor   = 0.0;

handles.GrayscaleMini = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleFloor/100.0);
handles.GrayscaleMaxi = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleCeiling/100.0);

handles.hGrayscaleImage = imagesc(handles.GrayscaleDisplayAxes, handles.GrayscaleData);
set(handles.hGrayscaleImage, 'HitTest', 'off', 'PickableParts', 'none');
caxis(handles.GrayscaleDisplayAxes, [handles.GrayscaleMini, handles.GrayscaleMaxi]);
colormap(handles.GrayscaleDisplayAxes, gray(256));

handles.GrayscaleDisplayAxes.XTick = [];
handles.GrayscaleDisplayAxes.YTick = [];
handles.GrayscaleDisplayAxes.XTickLabels = [];
handles.GrayscaleDisplayAxes.YTickLabels = [];

handles.CommonAxesPosition = get(handles.GrayscaleDisplayAxes, 'Position');

handles.GrayscaleColorbar = colorbar(handles.GrayscaleDisplayAxes, 'WestOutside', 'FontSize', 16, 'FontWeight', 'bold');

ylabel(handles.GrayscaleColorbar, 'Arbitrary Units', 'FontSize', 16, 'FontWeight', 'bold');

set(handles.GrayscaleDisplayAxes, 'Position', handles.CommonAxesPosition);

% Initialise the map display axes
handles.MapDisplayAxes.Visible = 'off';
handles.MapDisplayAxes.XTick = [];
handles.MapDisplayAxes.YTick = [];
handles.MapDisplayAxes.XTickLabels = [];
handles.MapDisplayAxes.YTickLabels = [];
linkprop([handles.GrayscaleDisplayAxes, handles.MapDisplayAxes], 'Position');

handles.ViewMap = 'PBV';

% Initialise a rectangle for movies and screen captures
handles.MainFigureColor = get(handles.MainFigure, 'Color');

AP = handles.CommonAxesPosition;

x0 = AP(1);
y0 = AP(2);
wd = AP(3);
ht = AP(4);

DX = 140;
DY = 12;

x0 = x0 - DX;
y0 = y0 - DY;
wd = wd + 2*DX;
ht = ht + 2*DY;

handles.Rectangle = [ x0 y0 wd ht ];

% Initialise the data source folders 
fid = fopen('Grayscale-Folder.txt', 'rt');
handles.GrayscaleFolder = fgetl(fid);
fclose(fid);

fid = fopen('Mapping-Folder.txt', 'rt');
handles.MappingFolder = fgetl(fid);
fclose(fid);

fid = fopen('Segmentation-Folder.txt', 'rt');
handles.SegmentationFolder = fgetl(fid);
fclose(fid);

ScreenshotsFolder = fullfile(handles.SegmentationFolder, 'Screenshots');

if (exist(ScreenshotsFolder, 'dir') ~= 7)
  mkdir(ScreenshotsFolder);
end

MoviesFolder = fullfile(handles.SegmentationFolder, 'Movies');

if (exist(MoviesFolder, 'dir') ~= 7)
  mkdir(MoviesFolder);
end

% Set limits for the cursor to find the image axes as the mouse is moved around
handles.NROWS = 176;
handles.NCOLS = 176;

handles.MinX = 0.5;
handles.MaxX = double(handles.NCOLS + 0.5);
handles.MinY = 0.5;
handles.MaxY = double(handles.NROWS + 0.5);

text(8, 8, 'No data loaded', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.GrayscaleDisplayAxes, 'Interpreter', 'none');

% Set the number of slices to an expected value to allow for parameter changes before any images are loaded
handles.NSLICES = 112;

% Set the image downsampling factor to control the size of text labels on the image
handles.Reduction = 1;

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

% Set the image slice
handles.Slice = 56;

% Initialise a notional "current" slice location
handles.CurrentSliceLocation = handles.SLx1(handles.Slice);

% Initialise some important display variables
handles.GrayscaleCeiling = 15.0;
handles.GrayscaleFloor   = 0.0;
handles.GrayscaleEpoch   = 1;

handles.MapCeiling = 15.0;
handles.MapFloor   = 0.0;

handles.Opacity = 1.00;

handles.CensorHighValues = true;

% Control the composition of the display, screenshots or movies
handles.Animate           = 'Grayscale Slices With Overlay';
handles.ApplySegmentation = true;
handles.ShowAllSlices     = false;

handles.LabelImages = true;

% Set the slider steps
set(handles.GrayscaleCeilingSlider, 'SliderStep', [1.0, 9.0]/99.0);
set(handles.GrayscaleFloorSlider, 'SliderStep', [1.0, 9.0]/99.0);
set(handles.SliceSlider, 'SliderStep', [1.0, 8.0]/111.0);
set(handles.GrayscaleEpochSlider, 'SliderStep', [1.0, 4.0]/16.0);

set(handles.MapCeilingSlider, 'SliderStep', [1.0, 9.0]/99.0);
set(handles.MapFloorSlider, 'SliderStep', [1.0, 9.0]/99.0);

set(handles.OpacitySlider, 'SliderStep', [0.01, 0.1]);

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

% Add listeners for a continuous slider response
hGrayscaleCeilingSliderListener = addlistener(handles.GrayscaleCeilingSlider, 'ContinuousValueChange', @CB_GrayscaleCeilingSlider_Listener);
setappdata(handles.GrayscaleCeilingSlider, 'MyListener', hGrayscaleCeilingSliderListener);

hGrayscaleFloorSliderListener = addlistener(handles.GrayscaleFloorSlider, 'ContinuousValueChange', @CB_GrayscaleFloorSlider_Listener);
setappdata(handles.GrayscaleFloorSlider, 'MyListener', hGrayscaleFloorSliderListener);

hSliceSliderListener = addlistener(handles.SliceSlider, 'ContinuousValueChange', @CB_SliceSlider_Listener);
setappdata(handles.SliceSlider, 'MyListener', hSliceSliderListener);

hGrayscaleEpochSliderListener = addlistener(handles.GrayscaleEpochSlider, 'ContinuousValueChange', @CB_GrayscaleEpochSlider_Listener);
setappdata(handles.GrayscaleEpochSlider, 'MyListener', hGrayscaleEpochSliderListener);

hMapCeilingSliderListener = addlistener(handles.MapCeilingSlider, 'ContinuousValueChange', @CB_MapCeilingSlider_Listener);
setappdata(handles.MapCeilingSlider, 'MyListener', hMapCeilingSliderListener);

hMapFloorSliderListener = addlistener(handles.MapFloorSlider, 'ContinuousValueChange', @CB_MapFloorSlider_Listener);
setappdata(handles.MapFloorSlider, 'MyListener', hMapFloorSliderListener);

hOpacitySliderListener = addlistener(handles.OpacitySlider, 'ContinuousValueChange', @CB_OpacitySlider_Listener);
setappdata(handles.OpacitySlider, 'MyListener', hOpacitySliderListener);

% Update the HANDLES structure
guidata(hObject, handles);

% UIWAIT makes pft_CreatePerfusionOverlaysMacOS wait for user response (see UIRESUME)
% uiwait(handles.MainFigure);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = pft_CreatePerfusionOverlaysMacOS_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpenCineStackButton_CreateFcn(hObject, eventdata, handles)

set(hObject, 'BackgroundColor', [0.6 1.0 0.6]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleCeilingSlider_Callback(hObject, eventdata, handles)

% Fetch the upper window value, rounded to 1 p.c.
handles.GrayscaleCeiling = round(get(hObject, 'Value'));
set(handles.GrayscaleCeilingEdit, 'String', sprintf('  Grayscale Ceiling: %3d %%', handles.GrayscaleCeiling));

% Keep the lower window value under control
if (handles.GrayscaleCeiling - handles.GrayscaleFloor <= 1)
  handles.GrayscaleFloor = handles.GrayscaleCeiling - 1.0;
  set(handles.GrayscaleFloorSlider, 'Value', handles.GrayscaleFloor);
  set(handles.GrayscaleFloorEdit, 'String', sprintf('  Grayscale Floor:   %3d %%', handles.GrayscaleFloor));
end

% Display the current slice
handles.GrayscaleMini = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleFloor/100.0);
handles.GrayscaleMaxi = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleCeiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_GrayscaleCeilingSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the upper window value, rounded to 1 p.c.
handles.GrayscaleCeiling = round(get(hObject, 'Value'));
set(handles.GrayscaleCeilingEdit, 'String', sprintf('  Grayscale Ceiling: %3d %%', handles.GrayscaleCeiling));

% Keep the lower window value under control
if (handles.GrayscaleCeiling - handles.GrayscaleFloor <= 1)
  handles.GrayscaleFloor = handles.GrayscaleCeiling - 1.0;
  set(handles.GrayscaleFloorSlider, 'Value', handles.GrayscaleFloor);
  set(handles.GrayscaleFloorEdit, 'String', sprintf('  Grayscale Floor:   %3d %%', handles.GrayscaleFloor));
end

% Display the current slice
handles.GrayscaleMini = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleFloor/100.0);
handles.GrayscaleMaxi = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleCeiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleCeilingSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleFloorSlider_Callback(hObject, eventdata, handles)

% Fetch the lower window value, rounded to 1 p.c.
handles.GrayscaleFloor = round(get(hObject, 'Value'));
set(handles.GrayscaleFloorEdit, 'String', sprintf('  Grayscale Floor:   %3d %%', handles.GrayscaleFloor));

% Keep the upper window value under control
if (handles.GrayscaleCeiling - handles.GrayscaleFloor <= 1)
  handles.GrayscaleCeiling = handles.GrayscaleFloor + 1.0;
  set(handles.GrayscaleCeilingSlider, 'Value', handles.GrayscaleCeiling);
  set(handles.GrayscaleCeilingEdit, 'String', sprintf('  Grayscale Ceiling: %3d %%', handles.GrayscaleCeiling));
end

% Display the current slice
handles.GrayscaleMini = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleFloor/100.0);
handles.GrayscaleMaxi = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleCeiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_GrayscaleFloorSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the lower window value, rounded to 1 p.c.
handles.GrayscaleFloor = round(get(hObject, 'Value'));
set(handles.GrayscaleFloorEdit, 'String', sprintf('  Grayscale Floor:   %3d %%', handles.GrayscaleFloor));

% Keep the upper window value under control
if (handles.GrayscaleCeiling - handles.GrayscaleFloor <= 1)
  handles.GrayscaleCeiling = handles.GrayscaleFloor + 1.0;
  set(handles.GrayscaleCeilingSlider, 'Value', handles.GrayscaleCeiling);
  set(handles.GrayscaleCeilingEdit, 'String', sprintf('  Grayscale Ceiling: %3d %%', handles.GrayscaleCeiling));
end

% Display the current slice
handles.GrayscaleMini = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleFloor/100.0);
handles.GrayscaleMaxi = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleCeiling/100.0);

% Update the HANDLES structure
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleFloorSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleCeilingEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleCeilingEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleFloorEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleFloorEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SliceEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SliceEdit_CreateFcn(hObject, eventdata, handles)

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

function SliceSlider_Callback(hObject, eventdata, handles)

% Fetch the current slice
handles.Slice = round(get(hObject, 'Value'));
set(handles.SliceEdit, 'String', sprintf('  Slice:           %3d', handles.Slice));

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

function CB_SliceSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the current slice
handles.Slice = round(get(hObject, 'Value'));
set(handles.SliceEdit, 'String', sprintf('  Slice:           %3d', handles.Slice));

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

function SliceSlider_CreateFcn(hObject, eventdata, handles)

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
colormap(handles.MapDisplayAxes, handles.Colormap);

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
colormap(handles.MapDisplayAxes, handles.Colormap);

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

% Also, do nothing if lengthy i/o is in progress
if (handles.InputInProgress == true) || (handles.OutputInProgress == true)
  return;
end

% Fetch the current point w.r.t. the IMAGE AXES rather than the MAIN FIGURE
P = get(handles.GrayscaleDisplayAxes, 'CurrentPoint');

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

% Report the cursor position and (if appropriate) the current perfusion map pixel value
handles.PixelRow = ceil(cy - 0.5);
handles.PixelCol = ceil(cx - 0.5);

handles.PixelValue = handles.MapData(handles.PixelRow, handles.PixelCol);

set(handles.ImageRowEdit, 'String', sprintf('  Row:    %1d', handles.PixelRow));
set(handles.ImageColumnEdit, 'String', sprintf('  Column: %1d', handles.PixelCol));

switch handles.Animate
  case { 'Grayscale Slices', 'Grayscale Epochs' }
    set(handles.ImagePixelValueEdit, 'String', '  Pixel Value:');
  case { 'Grayscale Slices With Overlay', 'Grayscale Epochs With Overlay', 'Maps Only' }
    set(handles.ImagePixelValueEdit, 'String', sprintf('  Pixel Value: %.4f %s', handles.PixelValue, handles.Units));
end

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CaptureDisplayButton_Callback(hObject, eventdata, handles)

% Offer the option to save the screenshot as an image
Listing = dir(fullfile(handles.SegmentationFolder, 'Screenshots', sprintf('%s_Overlay_*.png', handles.MapFileNameStub)));
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries(Folders) = [];
Entries = sort(Entries);
Entries = Entries';

if isempty(Entries)
  Suffix = '001';  
    
  DefaultName = fullfile(handles.SegmentationFolder, 'Screenshots', sprintf('%s_Overlay_001.png', handles.MapFileNameStub));
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
    
  DefaultName = fullfile(handles.SegmentationFolder, 'Screenshots', sprintf('%s_Overlay_%s.png', handles.MapFileNameStub, Suffix));
end

FilterSpec  = fullfile(handles.SegmentationFolder, 'Screenshots', '*.png');
DialogTitle = 'Save Screenshot As';

[ FileName, PathName, FilterIndex ] = uiputfile(FilterSpec, DialogTitle, DefaultName);

if (FilterIndex ~= 0)
  % Disable the motion function and hide the main controls
  handles.OutputInProgress = true;
  
  guidata(hObject, handles);
  handles = DisableControlsTemporarily(handles);
  guidata(hObject, handles);
    
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
  
  % Re-enable the motion function and show the main controls
  handles.OutputInProgress = false;
  
  guidata(hObject, handles);
  handles = EnableControlsTemporarily(handles);
  guidata(hObject, handles);
end

% Update the HANDLES structure - is this really necessary here, since "handles" is used in a read-only way ? 
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CaptureDisplayButton_CreateFcn(hObject, eventdata, handles)

set(hObject, 'BackgroundColor', [1.0 0.8 0.6]);

end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_DeleteFcn(hObject, eventdata, handles)

% Now exit by deleting the figure
delete(hObject);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_KeyPressFcn(hObject, eventdata, handles)

% Trap either of 2 conventional exit keys to turn off the warning that was turned off when the dialog opened
switch eventdata.Key
  case { 'escape', 'return' }
    delete(hObject);
  otherwise
    return;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_CloseRequestFcn(hObject, eventdata, handles)

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
% A worker function to disable active controls during output                                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = DisableControlsTemporarily(handles)

% The colormap controls
set(handles.ColormapListBox, 'Enable', 'off');
set(handles.ColormapSizeListBox, 'Enable', 'off');

% The windowing and data selection sliders
set(handles.GrayscaleCeilingSlider, 'Enable', 'off');
set(handles.GrayscaleFloorSlider, 'Enable', 'off');
set(handles.SliceSlider, 'Enable', 'off');
set(handles.GrayscaleEpochSlider, 'Enable', 'off');

set(handles.MapCeilingSlider, 'Enable', 'off');
set(handles.MapFloorSlider, 'Enable', 'off');

set(handles.OpacitySlider, 'Enable', 'off');

% The display menu controls
set(handles.ImportDataButton, 'Enable', 'off');
set(handles.CensorHighValuesCheck, 'Enable', 'off');
set(handles.LabelImagesCheck, 'Enable', 'off');

set(handles.CCRadio, 'Enable', 'off');
set(handles.UnfilteredCCRadio, 'Enable', 'off');
set(handles.PBVRadio, 'Enable', 'off');
set(handles.UnfilteredPBVRadio, 'Enable', 'off');
set(handles.PBFRadio, 'Enable', 'off');
set(handles.UnfilteredPBFRadio, 'Enable', 'off');
set(handles.MTTRadio, 'Enable', 'off');
set(handles.UnfilteredMTTRadio, 'Enable', 'off');
set(handles.TTPRadio, 'Enable', 'off');
set(handles.ThresholdMaskRadio, 'Enable', 'off');
set(handles.IngrischMaskRadio, 'Enable', 'off');

% The Output menu controls
set(handles.CaptureDisplayButton, 'Enable', 'off');
set(handles.CreateMovieButton, 'Enable', 'off');

% The Overlays menu controls
set(handles.GrayscaleSlicesRadio, 'Enable', 'off');
set(handles.GrayscaleSlicesWithOverlayRadio, 'Enable', 'off');
set(handles.GrayscaleEpochsRadio, 'Enable', 'off');
set(handles.GrayscaleEpochsWithOverlayRadio, 'Enable', 'off');
set(handles.MapsOnlyRadio, 'Enable', 'off');

set(handles.ApplySegmentationCheck, 'Enable', 'off');
set(handles.ShowAllSlicesCheck, 'Enable', 'off');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to re-enable inactive controls during segmentation                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = EnableControlsTemporarily(handles)

% The colormap controls
set(handles.ColormapListBox, 'Enable', 'on');
set(handles.ColormapSizeListBox, 'Enable', 'on');

% The windowing and slice selection sliders
set(handles.GrayscaleCeilingSlider, 'Enable', 'on');
set(handles.GrayscaleFloorSlider, 'Enable', 'on');
set(handles.SliceSlider, 'Enable', 'on');
set(handles.GrayscaleEpochSlider, 'Enable', 'on');

set(handles.MapCeilingSlider, 'Enable', 'on');
set(handles.MapFloorSlider, 'Enable', 'on');

set(handles.OpacitySlider, 'Enable', 'on');

% The display menu controls
set(handles.ImportDataButton, 'Enable', 'on');
set(handles.CensorHighValuesCheck, 'Enable', 'on');
set(handles.LabelImagesCheck, 'Enable', 'on');

set(handles.CCRadio, 'Enable', 'on');
set(handles.UnfilteredCCRadio, 'Enable', 'on');
set(handles.PBVRadio, 'Enable', 'on');
set(handles.UnfilteredPBVRadio, 'Enable', 'on');
set(handles.PBFRadio, 'Enable', 'on');
set(handles.UnfilteredPBFRadio, 'Enable', 'on');
set(handles.MTTRadio, 'Enable', 'on');
set(handles.UnfilteredMTTRadio, 'Enable', 'on');
set(handles.TTPRadio, 'Enable', 'on');
set(handles.ThresholdMaskRadio, 'Enable', 'on');
set(handles.IngrischMaskRadio, 'Enable', 'on');

% Disable any radio buttons corresponding to maps not actually present
if ~any(strcmpi(handles.MapFieldNames, 'CC'))
  set(handles.CCRadio, 'Enable', 'off');
end

if ~any(strcmpi(handles.MapFieldNames, 'UnfilteredCC'))
  set(handles.UnfilteredCCRadio, 'Enable', 'off');
end

if ~any(strcmpi(handles.MapFieldNames, 'UnfilteredPBF'))
  set(handles.UnfilteredPBFRadio, 'Enable', 'off');
end

if ~any(strcmpi(handles.MapFieldNames, 'UnfilteredMTT'))
  set(handles.UnfilteredMTTRadio, 'Enable', 'off');
end

if ~any(strcmpi(handles.MapFieldNames, 'ThresholdMask'))
  set(handles.ThresholdMaskRadio, 'Enable', 'off');
end

if ~any(strcmpi(handles.MapFieldNames, 'IngrischMask'))
  set(handles.IngrischMaskRadio, 'Enable', 'off');
end

% The Output menu controls
set(handles.CaptureDisplayButton, 'Enable', 'on');
set(handles.CreateMovieButton, 'Enable', 'on');

% The Overlays menu controls
set(handles.GrayscaleSlicesRadio, 'Enable', 'on');
set(handles.GrayscaleSlicesWithOverlayRadio, 'Enable', 'on');
set(handles.GrayscaleEpochsRadio, 'Enable', 'on');
set(handles.GrayscaleEpochsWithOverlayRadio, 'Enable', 'on');
set(handles.MapsOnlyRadio, 'Enable', 'on');

set(handles.ApplySegmentationCheck, 'Enable', 'on');
set(handles.ShowAllSlicesCheck, 'Enable', 'on');

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to update the display                                                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = UpdateImageDisplay(handles)

% Mask the map data by the segmentation if appropriate
if (handles.ApplySegmentation == true)
  switch handles.Animate
    case { 'Grayscale Slices', 'Grayscale Epochs' }
      handles.Masking = handles.Transparent;
    case { 'Grayscale Slices With Overlay', 'Grayscale Epochs With Overlay', 'Maps Only' }
      handles.RightROI = handles.RightBinaryMask(:, :, handles.Slice);
      handles.LinksROI = handles.LinksBinaryMask(:, :, handles.Slice);
      handles.TotalROI = handles.RightROI | handles.LinksROI;
     
      handles.Masking = handles.Opacity*double(handles.TotalROI);
  end   
else
  switch handles.Animate
    case { 'Grayscale Slices', 'Grayscale Epochs' }
      handles.Masking = handles.Transparent;
    case { 'Grayscale Slices With Overlay', 'Grayscale Epochs With Overlay', 'Maps Only' }
      handles.Masking = handles.Opacity*handles.Opaque;
  end
end  

% Create the two layers of the overlay according to the choice of composition
switch handles.Animate
  case { 'Grayscale Slices', 'Grayscale Epochs' }
    handles.GrayscaleData = handles.CineStack(:, :, handles.Slice, handles.GrayscaleEpoch);
    handles.MapData = handles.Black;
  case { 'Grayscale Slices With Overlay', 'Grayscale Epochs With Overlay' }
    handles.GrayscaleData = handles.CineStack(:, :, handles.Slice, handles.GrayscaleEpoch);
    handles.MapData = handles.Map(:, :, handles.Slice);
  case 'Maps Only'
    handles.GrayscaleData = handles.Black;
    handles.MapData = handles.Map(:, :, handles.Slice);    
end

% Now show the grayscale image with its colorbar   
handles.hGrayscaleImage = imagesc(handles.GrayscaleDisplayAxes, handles.GrayscaleData);
caxis(handles.GrayscaleDisplayAxes, [handles.GrayscaleMini, handles.GrayscaleMaxi]);

handles.GrayscaleDisplayAxes.XTick = [];
handles.GrayscaleDisplayAxes.YTick = [];
handles.GrayscaleDisplayAxes.XTickLabels = [];
handles.GrayscaleDisplayAxes.YTickLabels = [];

handles.GrayscaleColorbar = colorbar(handles.GrayscaleDisplayAxes, 'WestOutside', 'FontSize', 16, 'FontWeight', 'bold');
ylabel(handles.GrayscaleColorbar, 'Grayscale Units', 'FontSize', 16, 'FontWeight', 'bold');
set(handles.GrayscaleDisplayAxes, 'Position', handles.CommonAxesPosition);

% On top of that, the coloured perfusion map
handles.hMapImage = imagesc(handles.MapDisplayAxes, handles.MapData, 'AlphaData', handles.Masking);
caxis(handles.MapDisplayAxes, [handles.MapMini, handles.MapMaxi]);

handles.MapDisplayAxes.Visible = 'off';
handles.MapDisplayAxes.XTick = [];
handles.MapDisplayAxes.YTick = [];
handles.MapDisplayAxes.XTickLabels = [];
handles.MapDisplayAxes.YTickLabels = [];

handles.MapColorbar = colorbar(handles.MapDisplayAxes, 'EastOutside', 'FontSize', 16, 'FontWeight', 'bold');
ylabel(handles.MapColorbar, handles.CBUnits, 'FontSize', 16, 'FontWeight', 'bold');
set(handles.MapDisplayAxes, 'Position', handles.CommonAxesPosition);

% Apply the colormap to the perfusion map axes
colormap(handles.MapDisplayAxes, handles.Colormap);

% Add a basic annotation to the image
if (handles.LabelImages == true)
  r = handles.Reduction;
  text(16.0/r, 16.0/r, handles.MapFileNameStub, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.MapDisplayAxes, 'Interpreter', 'none');
  text(16.0/r, 32.0/r, sprintf('Slice %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.MapDisplayAxes); 
  text(16.0/r, 48.0/r, sprintf('Epoch %3d', handles.GrayscaleEpoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.MapDisplayAxes); 
end
  
% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleEpochSlider_Callback(hObject, eventdata, handles)

% Fetch the current epoch
handles.GrayscaleEpoch = round(get(hObject, 'Value'));
set(handles.GrayscaleEpochEdit, 'String', sprintf('  Grayscale Epoch: %3d', handles.GrayscaleEpoch));

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_GrayscaleEpochSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the current slice
handles.GrayscaleEpoch = round(get(hObject, 'Value'));
set(handles.GrayscaleEpochEdit, 'String', sprintf('  Grayscale Epoch: %3d', handles.GrayscaleEpoch));

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleEpochSlider_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleEpochEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GrayscaleEpochEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
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

function LabelImagesCheck_Callback(hObject, eventdata, handles)

% Fetch the Booelan value here
handles.LabelImages = logical(get(hObject, 'Value'));

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

function ImportDataButton_Callback(hObject, eventdata, handles)
  
% Prompt for a perfusion map MAT file - do nothing if none is chosen
[ MapFileName, MapPathName, FilterIndex ] = uigetfile('*.mat', 'Select a PERFUSION MAP pickle file', fullfile(handles.MappingFolder, '*mat'));

if (FilterIndex == 0)
  return;
end

% Prompt for a grayscale pickle file - do nothing if none is chosen
[ GrayscaleFileName, GrayscalePathName, FilterIndex ] = uigetfile('*.mat', 'Select a GRAYSCALE pickle file', fullfile(handles.GrayscaleFolder, '*mat'));

if (FilterIndex == 0)
  return;
end

% Disable most of the controls during input
handles.InputInProgress = true;

guidata(hObject, handles);
handles = DisableControlsTemporarily(handles);
guidata(hObject, handles);

% Read in the perfusion map file using a worker function
handles.MapFolder   = MapPathName;
handles.MapFileName = MapFileName;

[ p, f, e ] = fileparts(fullfile(MapPathName, MapFileName));

handles.MapFileNameStub = f;

set(handles.MapsFileEdit, 'String', sprintf('  Maps Pickle File:      %s', handles.MapFileNameStub));

guidata(hObject, handles);
handles = ImportPerfusionMaps(handles);
guidata(hObject, handles);

% Read in the right binary mask stack
handles.RightLungFolder = fullfile(handles.SegmentationFolder, 'Regions of Interest', handles.MapFileNameStub, 'Right Lung');
  
handles.RightBinaryMask = pft_ReadBinaryMaskStack(handles.RightLungFolder, size(handles.Map));
  
p = strfind(handles.RightLungFolder, handles.MapFileNameStub);
q = p(1);
    
set(handles.RightLungROIFolderEdit, 'String', sprintf('  Right Lung ROI Folder: ..%c%s', filesep, handles.RightLungFolder(q:end)));
  
% Read in the left binary mask stack
handles.LinksLungFolder = fullfile(handles.SegmentationFolder, 'Regions of Interest', handles.MapFileNameStub, 'Left Lung');
  
handles.LinksBinaryMask = pft_ReadBinaryMaskStack(handles.LinksLungFolder, size(handles.Map));
  
p = strfind(handles.LinksLungFolder, handles.MapFileNameStub);
q = p(1);
    
set(handles.LinksLungROIFolderEdit, 'String', sprintf('  Left Lung ROI Folder:  ..%c%s', filesep, handles.LinksLungFolder(q:end)));
  
% Combine the two maps
handles.TotalBinaryMask = handles.RightBinaryMask | handles.LinksBinaryMask;

% Read in the grayscale file using a worker function
handles.GrayscaleFolder   = GrayscalePathName;
handles.GrayscaleFileName = GrayscaleFileName;

[ p, f, e ] = fileparts(fullfile(GrayscalePathName, GrayscaleFileName));

handles.GrayscaleFileNameStub = f;

set(handles.GrayscaleFileEdit, 'String', sprintf('  Grayscale Pickle File: %s', handles.GrayscaleFileNameStub));

guidata(hObject, handles);
handles = OpenCineStack(handles);
guidata(hObject, handles);

% Enable some interactivity with the displayed image
handles.ReviewMapIsPresent = true;

% Create some dummy working arrays for efficient display of the various grayscale-and-perfusion-map compositions
Dimensions = [ handles.NROWS, handles.NCOLS ];

handles.Black       = zeros(Dimensions, 'uint8');
handles.Opaque      = ones(Dimensions);
handles.Transparent = zeros(Dimensions, 'double');

% Signal that a working image is present to the other callbacks
handles.ReviewImageIsPresent = true;

% Re-enable the previously disabled controls
handles.InputInProgress = false;

guidata(hObject, handles);
handles = EnableControlsTemporarily(handles);
guidata(hObject, handles);

% Now update the image display - note the previous update of the HANDLES structure
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CensorHighValuesCheck_Callback(hObject, eventdata, handles)

% Fetch the Boolean value here
handles.CensorHighValues = logical(get(hObject, 'Value'));

% Quit if there is no data set loaded
if (handles.ReviewImageIsPresent == false)
  guidata(hObject, handles);
  return;
end  

% Select the map to be viewed, and set units and scaling factors
switch handles.ViewMap
  case 'CC'
    handles.Map       = handles.CC;
    handles.Units     = '';
    handles.CBUnits   = 'Cross-Correlation';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0e-4;
  case 'Unfiltered CC'
    handles.Map       = handles.UnfilteredCC;
    handles.Units     = '';
    handles.CBUnits   = 'Unfiltered Cross-Correlation';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0e-4;   
  case 'PBV'
    handles.Map       = handles.PBV;
    handles.Units     = 'ml/100 ml';
    handles.CBUnits   = 'PBV [ml/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'Unfiltered PBV'
    handles.Map       = handles.UnfilteredPBV;
    handles.Units     = 'ml/100 ml';
    handles.CBUnits   = 'Unfiltered PBV [ml/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'PBF'
    handles.Map       = handles.PBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.CBUnits   = 'PBF [(ml/min)/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Unfiltered PBF'
    handles.Map       = handles.UnfilteredPBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.CBUnits   = 'Unfiltered PBF [(ml/min)/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'MTT'
    handles.Map       = handles.MTT;
    handles.Units     = 'sec';
    handles.CBUnits   = 'MTT [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Unfiltered MTT'
    handles.Map       = handles.UnfilteredMTT;
    handles.Units     = 'sec';
    handles.CBUnits   = 'Unfiltered MTT [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'TTP'
    handles.Map       = handles.TTP;
    handles.Units     = 'sec';
    handles.CBUnits   = 'TTP [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Threshold Mask'
    handles.Map       = handles.ThresholdMask;
    handles.Units     = '';
    handles.CBUnits   = 'Threshold Mask [Binary]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Ingrisch Mask'
    handles.Map       = handles.IngrischMask;
    handles.Units    = '';
    handles.CBUnits   = 'Ingrisch Mask [Binary]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
end  

% Rescale the data for floating-point display
handles.Map = handles.Intercept + handles.Slope*double(handles.Map);

if (handles.CensorHighValues == true)
  switch handles.ViewMap
    case { 'CC', 'Unfiltered CC' }
      % Nothing to do here
    case { 'PBV', 'Unfiltered PBV' }
      handles.Map(handles.Map > 100.0) = 0.0;
    case { 'PBF', 'Unfiltered PBF' }
      handles.Map(handles.Map > 6000.0) = 0.0;
    case { 'MTT', 'Unfiltered MTT' }
      handles.Map(handles.Map > 60.0) = 0.0;
    case 'TTP'
      handles.Map(handles.Map > 60.0) = 0.0;
    case { 'Threshold Mask', 'Ingrisch Mask' }
      % Nothing to do here
  end
end  

% Display the current slice
handles.MapLower = min(handles.Map(:));
handles.MapUpper = max(handles.Map(:));
handles.MapRange = handles.MapUpper - handles.MapLower;

handles.MapMini = handles.MapLower + handles.MapRange*(handles.MapFloor/100.0);
handles.MapMaxi = handles.MapLower + handles.MapRange*(handles.MapCeiling/100.0);

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapsFileEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapsFileEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapCeilingEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapCeilingEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapCeilingSlider_Callback(hObject, eventdata, handles)

% Fetch the upper window value, rounded to 1 p.c.
handles.MapCeiling = round(get(hObject, 'Value'));
set(handles.MapCeilingEdit, 'String', sprintf('  Map Ceiling: %3d %%', handles.MapCeiling));

% Keep the lower window value under control
if (handles.MapCeiling - handles.MapFloor <= 1)
  handles.MapFloor = handles.MapCeiling - 1.0;
  set(handles.MapFloorSlider, 'Value', handles.MapFloor);
  set(handles.MapFloorEdit, 'String', sprintf('  Map Floor:   %3d %%', handles.MapFloor));
end

% Display the current slice
handles.MapMini = handles.MapLower + handles.MapRange*(handles.MapFloor/100.0);
handles.MapMaxi = handles.MapLower + handles.MapRange*(handles.MapCeiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_MapCeilingSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the upper window value, rounded to 1 p.c.
handles.MapCeiling = round(get(hObject, 'Value'));
set(handles.MapCeilingEdit, 'String', sprintf('  Map Ceiling: %3d %%', handles.MapCeiling));

% Keep the lower window value under control
if (handles.MapCeiling - handles.MapFloor <= 1)
  handles.MapFloor = handles.MapCeiling - 1.0;
  set(handles.MapFloorSlider, 'Value', handles.MapFloor);
  set(handles.MapFloorEdit, 'String', sprintf('  Map Floor:   %3d %%', handles.MapFloor));
end

% Display the current slice
handles.MapMini = handles.MapLower + handles.MapRange*(handles.MapFloor/100.0);
handles.MapMaxi = handles.MapLower + handles.MapRange*(handles.MapCeiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapCeilingSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapFloorEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapFloorEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapFloorSlider_Callback(hObject, eventdata, handles)

% Fetch the lower window value, rounded to 1 p.c.
handles.MapFloor = round(get(hObject, 'Value'));
set(handles.MapFloorEdit, 'String', sprintf('  Map Floor:   %3d %%', handles.MapFloor));

% Keep the upper window value under control
if (handles.MapCeiling - handles.MapFloor <= 1)
  handles.MapCeiling = handles.MapFloor + 1.0;
  set(handles.MapCeilingSlider, 'Value', handles.MapCeiling);
  set(handles.MapCeilingEdit, 'String', sprintf('  Map Ceiling: %3d %%', handles.MapCeiling));
end

% Display the current slice
handles.MapMini = handles.MapLower + handles.MapRange*(handles.MapFloor/100.0);
handles.MapMaxi = handles.MapLower + handles.MapRange*(handles.MapCeiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_MapFloorSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the lower window value, rounded to 1 p.c.
handles.MapFloor = round(get(hObject, 'Value'));
set(handles.MapFloorEdit, 'String', sprintf('  Map Floor:   %3d %%', handles.MapFloor));

% Keep the upper window value under control
if (handles.MapCeiling - handles.MapFloor <= 1)
  handles.MapCeiling = handles.MapFloor + 1.0;
  set(handles.MapCeilingSlider, 'Value', handles.MapCeiling);
  set(handles.MapCeilingEdit, 'String', sprintf('  Map Ceiling: %3d %%', handles.MapCeiling));
end

% Display the current slice
handles.MapMini = handles.MapLower + handles.MapRange*(handles.MapFloor/100.0);
handles.MapMaxi = handles.MapLower + handles.MapRange*(handles.MapCeiling/100.0);

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MapFloorSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpacitySlider_Callback(hObject, eventdata, handles)

% Fetch the value in the range [0.00 .. 1.00], rounded to 2 d.p.
handles.Opacity = 0.01*round(get(hObject, 'Value')/0.01);

% Update the edit window
set(handles.OpacityEdit, 'String', sprintf('  Opacity: %.2f', handles.Opacity));

% Update the HANDLES structure and display the image
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

% Fetch the value in the range [0.00 .. 1.00], rounded to 2 d.p.
handles.Opacity = 0.01*round(get(hObject, 'Value')/0.01);

% Update the edit window
set(handles.OpacityEdit, 'String', sprintf('  Opacity: %.2f', handles.Opacity));

% Update the HANDLES structure and display the image
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

function OpacityEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this edit window is read-only (for the time being)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OpacityEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ApplySegmentationCheck_Callback(hObject, eventdata, handles)

% Fetch the Boolean value here
handles.ApplySegmentation = logical(get(hObject, 'Value'));

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

function ShowAllSlicesCheck_Callback(hObject, eventdata, handles)

% Fetch the Boolean value here
handles.ShowAllSlices = logical(get(hObject, 'Value'));

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

function CreateMovieButton_Callback(hObject, eventdata, handles)

% Offer the option to save the screenshot as an image
Listing = dir(fullfile(handles.SegmentationFolder, 'Movies', sprintf('%s_Overlay_*.avi', handles.MapFileNameStub)));
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries(Folders) = [];
Entries = sort(Entries);
Entries = Entries';

if isempty(Entries)
  Suffix = '001';  
    
  DefaultName = fullfile(handles.SegmentationFolder, 'Movies', sprintf('%s_Overlay_001.avi', handles.MapFileNameStub));
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
    
  DefaultName = fullfile(handles.SegmentationFolder, 'Movies', sprintf('%s_Overlay_%s.avi', handles.MapFileNameStub, Suffix));
end

FilterSpec  = fullfile(handles.SegmentationFolder, 'Movies', '*.avi');
DialogTitle = 'Save Movie As';

[ FileName, PathName, FilterIndex ] = uiputfile(FilterSpec, DialogTitle, DefaultName);

% Return if no file is chosen
if (FilterIndex == 0)
  guidata(hObject, handles);
  return;
end

% Disable motion events and the main program controls if movie creation is going to proceed
handles.OutputInProgress = true;

guidata(hObject, handles);
handles = DisableControlsTemporarily(handles);
guidata(hObject, handles);

% Point to the output file
MovieFileName = fullfile(PathName, FileName);

% Save the current slice and epoch, to return to the status quo ante once the movie has been created
CurrentSlice = handles.Slice;
CurrentEpoch = handles.GrayscaleEpoch;

% Create the chosen animation using a pair of nested loops
switch handles.Animate
  case { 'Grayscale Slices', 'Grayscale Slices With Overlay', 'Maps Only' }
    if (handles.ShowAllSlices == true)
      AlphaSlice = 1;
      OmegaSlice = handles.NSLICES;
      
      AlphaEpoch = handles.GrayscaleEpoch;
      OmegaEpoch = handles.GrayscaleEpoch;
    else
     SegmentationPresent = false([handles.NSLICES, 1]);
    
      for s = 1:handles.NSLICES
        Part = handles.TotalBinaryMask(:, :, s);
        if any(Part(:))
          SegmentationPresent(s) = true;
        end
      end
    
      AlphaSlice = find(SegmentationPresent, 1, 'first');
      OmegaSlice = find(SegmentationPresent, 1, 'last');
    
      AlphaEpoch = handles.GrayscaleEpoch;
      OmegaEpoch = handles.GrayscaleEpoch;
    end
    
  case { 'Grayscale Epochs', 'Grayscale Epochs With Overlay' }
    AlphaSlice = handles.Slice;
    OmegaSlice = handles.Slice;
    
    AlphaEpoch = 1;
    OmegaEpoch = handles.NEPOCHS;
end

% Create and initialise a VideoWriter object
VW = VideoWriter(MovieFileName, 'Uncompressed AVI');
VW.FrameRate = 20;
open(VW);

% Capture the frames on a white background
set(handles.MainFigure, 'Color', [1 1 1]);
 
% Now create the frames and add them to the movie, slice by slice or epoch by epoch
for s = AlphaSlice:OmegaSlice
  for e = AlphaEpoch:OmegaEpoch
    handles.Slice = s;
    handles.GrayscaleEpoch = e;
  
    guidata(hObject, handles);
    handles = UpdateImageDisplay(handles);
    guidata(hObject, handles);
  
    F = getframe(handles.MainFigure, handles.Rectangle);
    X = F.cdata;
    writeVideo(VW, X);  
  end
end

close(VW);

% Restore the colour of the main dialog
set(handles.MainFigure, 'Color', handles.MainFigureColor);
    
% Re-enable motion events and the main program controls
handles.OutputInProgress = false;

guidata(hObject, handles);
handles = EnableControlsTemporarily(handles);
guidata(hObject, handles);

% Return to the original slice and epoch, and update the HANDLES structure
handles.Slice = CurrentSlice;
handles.GrayscaleEpoch = CurrentEpoch;

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ViewMapButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Update the choice of map to be displayed
handles.ViewMap = get(eventdata.NewValue, 'String');

% Quit if there is no data set loaded
if (handles.ReviewImageIsPresent == false)
  guidata(hObject, handles);
  return;
end  

% Select the map to be viewed, and set units and scaling factors
switch handles.ViewMap
  case 'CC'
    handles.Map       = handles.CC;
    handles.Units     = '';
    handles.CBUnits   = 'Cross-Correlation';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0e-4;
  case 'Unfiltered CC'
    handles.Map       = handles.UnfilteredCC;
    handles.Units     = '';
    handles.CBUnits   = 'Unfiltered Cross-Correlation';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0e-4;   
  case 'PBV'
    handles.Map       = handles.PBV;
    handles.Units     = 'ml/100 ml';
    handles.CBUnits   = 'PBV [ml/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'Unfiltered PBV'
    handles.Map       = handles.UnfilteredPBV;
    handles.Units     = 'ml/100 ml';
    handles.CBUnits   = 'Unfiltered PBV [ml/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'PBF'
    handles.Map       = handles.PBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.CBUnits   = 'PBF [(ml/min)/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Unfiltered PBF'
    handles.Map       = handles.UnfilteredPBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.CBUnits   = 'Unfiltered PBF [(ml/min)/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'MTT'
    handles.Map       = handles.MTT;
    handles.Units     = 'sec';
    handles.CBUnits   = 'MTT [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Unfiltered MTT'
    handles.Map       = handles.UnfilteredMTT;
    handles.Units     = 'sec';
    handles.CBUnits   = 'Unfiltered MTT [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'TTP'
    handles.Map       = handles.TTP;
    handles.Units     = 'sec';
    handles.CBUnits   = 'TTP [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Threshold Mask'
    handles.Map       = handles.ThresholdMask;
    handles.Units     = '';
    handles.CBUnits   = 'Threshold Mask [Binary]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Ingrisch Mask'
    handles.Map       = handles.IngrischMask;
    handles.Units    = '';
    handles.CBUnits   = 'Ingrisch Mask [Binary]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
end  

% Rescale the data for floating-point display
handles.Map = handles.Intercept + handles.Slope*double(handles.Map);

if (handles.CensorHighValues == true)
  switch handles.ViewMap
    case { 'CC', 'Unfiltered CC' }
      % Nothing to do here
    case { 'PBV', 'Unfiltered PBV' }
      handles.Map(handles.Map > 100.0) = 0.0;
    case { 'PBF', 'Unfiltered PBF' }
      handles.Map(handles.Map > 6000.0) = 0.0;
    case { 'MTT', 'Unfiltered MTT' }
      handles.Map(handles.Map > 60.0) = 0.0;
    case 'TTP'
      handles.Map(handles.Map > 60.0) = 0.0;
    case { 'Threshold Mask', 'Ingrisch Mask' }
      % Nothing to do here
  end
end  

% Display the current slice
handles.MapLower = min(handles.Map(:));
handles.MapUpper = max(handles.Map(:));
handles.MapRange = handles.MapUpper - handles.MapLower;

handles.MapMini = handles.MapLower + handles.MapRange*(handles.MapFloor/100.0);
handles.MapMaxi = handles.MapLower + handles.MapRange*(handles.MapCeiling/100.0);

guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to read in the perfusion maps                                                                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = ImportPerfusionMaps(handles)

% Read in the maps, which are bundled in a structure called MapMat, retained to save memory and time
wb = waitbar(0.5, 'Loading perfusion maps - please wait ... ');

handles.MapMat = [];
handles.MapMat = load(fullfile(handles.MapFolder, handles.MapFileName));

pause(0.5);
waitbar(1.0, wb, 'Loading complete');
pause(0.5);
delete(wb);

% List the fields of the MapMat structure so that maps from different mapping GUI's can be extracted
handles.RawMapPickleFieldNames = fieldnames(handles.MapMat);

% Compile a directory of those field names which are actually present - this will be used to control the state logic elsewhere
handles.MapFieldNames = { 'PBV', 'UnfilteredPBV', 'PBF', 'MTT', 'TTP' };

% Extract the different maps from the data pickle which are guaranteed to exist - ignore the MPA ROI
handles.PBV           = handles.MapMat.AllPBV;
handles.UnfilteredPBV = handles.MapMat.UnfilteredAllPBV;
handles.PBF           = handles.MapMat.AllPBF;
handles.MTT           = handles.MapMat.AllMTT;
handles.TTP           = handles.MapMat.AllTTP;

% Now look for those that may or may not exist - note that the threshold mask is inferred rather than explicitly present
if any(strcmpi(handles.RawMapPickleFieldNames, 'AllCC'))
  handles.CC = handles.MapMat.AllCC;
  handles.MapFieldNames = horzcat(handles.MapFieldNames, { 'CC' });
end

if any(strcmpi(handles.RawMapPickleFieldNames, 'UnfilteredAllCC'))
  handles.UnfilteredCC = handles.MapMat.UnfilteredAllCC;
  handles.MapFieldNames = horzcat(handles.MapFieldNames, { 'UnfilteredCC' });
end

if any(strcmpi(handles.RawMapPickleFieldNames, 'UnfilteredAllPBF'))
  handles.UnfilteredPBF = handles.MapMat.UnfilteredAllPBF;
  handles.MapFieldNames = horzcat(handles.MapFieldNames, { 'UnfilteredPBF' });
end

if any(strcmpi(handles.RawMapPickleFieldNames, 'UnfilteredAllMTT'))
  handles.UnfilteredMTT = handles.MapMat.UnfilteredAllMTT;
  handles.MapFieldNames = horzcat(handles.MapFieldNames, { 'UnfilteredMTT' });
  set(handles.UnfilteredMTTRadio, 'Enable', 'on');
end

if any(strcmpi(handles.RawMapPickleFieldNames, 'AllIngrischMask'))
  handles.IngrischMask = handles.MapMat.AllIngrischMask;
  handles.MapFieldNames = horzcat(handles.MapFieldNames, { 'IngrischMask' });
  handles.ThresholdMask = [];
else
  handles.ThresholdMask = (handles.MapMat.AllTTP > 0);
  handles.MapFieldNames = horzcat(handles.MapFieldNames, { 'ThresholdMask' });
  handles.IngrischMask = [];
end

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

% Adjust the slider settings for the Slice, just in case the downsampling factor has changed between data sets
switch handles.Reduction
  case 1
    set(handles.SliceSlider, 'SliderStep', [1.0, 8.0]/double(handles.NSLICES - 1));
  case 2
    set(handles.SliceSlider, 'SliderStep', [1.0, 4.0]/double(handles.NSLICES - 1));
  case 4
    set(handles.SliceSlider, 'SliderStep', [1.0, 2.0]/double(handles.NSLICES - 1));
  case 8
    set(handles.SliceSlider, 'SliderStep', [1.0, 1.0]/double(handles.NSLICES - 1));
end

if (handles.Slice > handles.NSLICES)
  handles.Slice = handles.NSLICES;
end

% Update the Slice edit window and its corresponding slider
set(handles.SliceEdit, 'String', sprintf('  Slice:          %3d', handles.Slice));
set(handles.SliceSlider, 'Value', handles.Slice);

% If a previously selected "view map" option is unavailable, default to 'PBV'
if ~any(strcmpi(handles.MapFieldNames, handles.ViewMap))
  handles.ViewMap = 'PBV';
  set(handles.PBVRadio, 'Value', true);
end

% Select the map to be viewed, and set units and scaling factors
switch handles.ViewMap
  case 'CC'
    handles.Map       = handles.CC;
    handles.Units     = '';
    handles.CBUnits   = 'Cross-Correlation';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0e-4;
  case 'Unfiltered CC'
    handles.Map       = handles.UnfilteredCC;
    handles.Units     = '';
    handles.CBUnits   = 'Unfiltered Cross-Correlation';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0e-4;   
  case 'PBV'
    handles.Map       = handles.PBV;
    handles.Units     = 'ml/100 ml';
    handles.CBUnits   = 'PBV [ml/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'Unfiltered PBV'
    handles.Map       = handles.UnfilteredPBV;
    handles.Units     = 'ml/100 ml';
    handles.CBUnits   = 'Unfiltered PBV [ml/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 0.01;
  case 'PBF'
    handles.Map       = handles.PBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.CBUnits   = 'PBF [(ml/min)/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Unfiltered PBF'
    handles.Map       = handles.UnfilteredPBF;
    handles.Units     = '(ml/min)/100 ml';
    handles.CBUnits   = 'Unfiltered PBF [(ml/min)/100 ml]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'MTT'
    handles.Map       = handles.MTT;
    handles.Units     = 'sec';
    handles.CBUnits   = 'MTT [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Unfiltered MTT'
    handles.Map       = handles.UnfilteredMTT;
    handles.Units     = 'sec';
    handles.CBUnits   = 'Unfiltered MTT [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'TTP'
    handles.Map       = handles.TTP;
    handles.Units     = 'sec';
    handles.CBUnits   = 'TTP [sec]';
    handles.Intercept = - 10.0;
    handles.Slope     = 0.001;
  case 'Threshold Mask'
    handles.Map       = handles.ThresholdMask;
    handles.Units     = '';
    handles.CBUnits   = 'Threshold Mask [Binary]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
  case 'Ingrisch Mask'
    handles.Map       = handles.IngrischMask;
    handles.Units    = '';
    handles.CBUnits   = 'Ingrisch Mask [Binary]';
    handles.Intercept = 0.0;
    handles.Slope     = 1.0;
end  

% Rescale the data for floating-point display
handles.Map = handles.Intercept + handles.Slope*double(handles.Map);

if (handles.CensorHighValues == true)
  switch handles.ViewMap
    case { 'CC', 'Unfiltered CC' }
      % Nothing to do here   
    case { 'PBV', 'Unfiltered PBV' }
      handles.Map(handles.Map > 100.0) = 0.0;
    case { 'PBF', 'Unfiltered PBF' }
      handles.Map(handles.Map > 6000.0) = 0.0;
    case { 'MTT', 'Unfiltered MTT' }
      handles.Map(handles.Map > 60.0) = 0.0;
    case 'TTP'
      handles.Map(handles.Map > 60.0) = 0.0;
    case { 'Threshold Mask', 'Ingrisch Mask' }
      % Nothing to do here
  end
end  

% Prepare to display the current slice
handles.MapLower = min(handles.Map(:));
handles.MapUpper = max(handles.Map(:));
handles.MapRange = handles.MapUpper - handles.MapLower;

handles.MapMini = handles.MapLower + handles.MapRange*(handles.MapFloor/100.0);
handles.MapMaxi = handles.MapLower + handles.MapRange*(handles.MapCeiling/100.0);

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A worker function to read in the grayscale cine-stack                                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = OpenCineStack(handles)

% Read in the cine-stack from the pickle file used in the mapping GUI; discard the Acquisition times, but use the header information
wb = waitbar(0.5, 'Loading grayscale images - please wait ... ');

handles.GrayscaleMat = [];
handles.GrayscaleMat = load(fullfile(handles.GrayscaleFolder, handles.GrayscaleFileName));

pause(0.5);
waitbar(1.0, wb, 'Loading complete');
pause(0.5);
delete(wb);

% Select the cine-stack at the correct downsampling factor - this will have been set when the perfusion maps were read in
switch handles.Reduction
  case 1
    handles.CineStack = handles.GrayscaleMat.CineStackX1;
  case 2
    handles.CineStack = handles.GrayscaleMat.CineStackX2;
  case 4
    handles.CineStack = handles.GrayscaleMat.CineStackX4;
  case 8
    handles.CineStack = handles.GrayscaleMat.CineStackX8;
end  

% Retrieve the image size - in fact, only the epochs are needed, since the rows, columns and slices will already be known
Dims = size(handles.CineStack);

handles.NEPOCHS = Dims(4);

set(handles.ImageEpochsEdit, 'String', sprintf('  Epochs: %1d', Dims(4)));

% Calculate slice locations from the common working header
[ NR, NC, NP, NE ] = size(handles.GrayscaleMat.CineStackX1);

handles.ZOx1 = handles.GrayscaleMat.Head.SliceLocation;
handles.DZx1 = handles.GrayscaleMat.Head.SliceThickness;
handles.SLx1 = handles.ZOx1 + handles.DZx1*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.GrayscaleMat.CineStackX2);

handles.ZOx2 = handles.ZOx1 + 0.5*handles.DZx1;
handles.DZx2 = 2.0*handles.DZx1;
handles.SLx2 = handles.ZOx2 + handles.DZx2*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.GrayscaleMat.CineStackX4);

handles.ZOx4 = handles.ZOx1 + 1.5*handles.DZx1;
handles.DZx4 = 4.0*handles.DZx1;
handles.SLx4 = handles.ZOx4 + handles.DZx4*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.GrayscaleMat.CineStackX8);

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
set(handles.SliceSlider, 'Max', handles.NSLICES);

switch handles.Reduction
  case 1
    set(handles.SliceSlider, 'SliderStep', [1.0, 8.0]/double(handles.NSLICES - 1));
  case 2
    set(handles.SliceSlider, 'SliderStep', [1.0, 4.0]/double(handles.NSLICES - 1));
  case 4
    set(handles.SliceSlider, 'SliderStep', [1.0, 2.0]/double(handles.NSLICES - 1));
  case 8
    set(handles.SliceSlider, 'SliderStep', [1.0, 1.0]/double(handles.NSLICES - 1));
end

% This shouldn't happen - given the code immediately preceding - but it shouldn't do any harm
if (handles.Slice > handles.NSLICES)
  handles.Slice = handles.NSLICES; 
  
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
set(handles.GrayscaleEpochSlider, 'Max', handles.NEPOCHS);
set(handles.GrayscaleEpochSlider, 'SliderStep', [1.0, 4.0]/double(handles.NEPOCHS - 1));

if (handles.GrayscaleEpoch > handles.NEPOCHS)
  handles.GrayscaleEpoch = handles.NEPOCHS; 
end

% Update the Slice and Epoch edit windows and their corresponding sliders
set(handles.SliceEdit, 'String', sprintf('  Slice:           %3d', handles.Slice));
set(handles.GrayscaleEpochEdit, 'String', sprintf('  Grayscale Epoch: %3d', handles.GrayscaleEpoch));

set(handles.SliceSlider, 'Value', handles.Slice);
set(handles.GrayscaleEpochSlider, 'Value', handles.GrayscaleEpoch);

% Display the current slice and epoch
handles.GrayscaleLower = 0;
handles.GrayscaleUpper = max(handles.CineStack(:));
handles.GrayscaleRange = handles.GrayscaleUpper - handles.GrayscaleLower;

handles.GrayscaleMini = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleFloor/100.0);
handles.GrayscaleMaxi = handles.GrayscaleLower + handles.GrayscaleRange*(handles.GrayscaleCeiling/100.0);

% Return an updated HANDLES structure to the calling function
guidata(handles.MainFigure, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function AnimateButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Choose the overlay composition
handles.Animate = get(eventdata.NewValue, 'String');

% Quit if no usable image is present
if (handles.ReviewImageIsPresent == false)
  guidata(hObject, handles);
  return;
end

% Update the HANDLES structure and display the image
guidata(hObject, handles);
handles = UpdateImageDisplay(handles);
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_SizeChangedFcn(hObject, eventdata, handles)

% Locate the axes w.r.t. the figure
handles.CommonAxesPosition = get(handles.GrayscaleDisplayAxes, 'Position');  

AP = handles.CommonAxesPosition;

x0 = AP(1);
y0 = AP(2);
wd = AP(3);
ht = AP(4);

DX = 140;
DY = 12;

x0 = x0 - DX;
y0 = y0 - DY;
wd = wd + 2*DX;
ht = ht + 2*DY;

% Also, the image-capture rectangle
handles.Rectangle = [ x0 y0 wd ht ];

% Update the HANDLES structure and display the image
guidata(hObject, handles);

end
