function varargout = pft_PerfusionCoregistrationReview(varargin)
% PFT_PERFUSIONCOREGISTRATIONREVIEW MATLAB code for pft_PerfusionCoregistrationReview.fig
%      PFT_PERFUSIONCOREGISTRATIONREVIEW, by itself, creates a new PFT_PERFUSIONCOREGISTRATIONREVIEW or raises the existing
%      singleton*.
%
%      H = PFT_PERFUSIONCOREGISTRATIONREVIEW returns the handle to a new PFT_PERFUSIONCOREGISTRATIONREVIEW or the handle to
%      the existing singleton*.
%
%      PFT_PERFUSIONCOREGISTRATIONREVIEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PFT_PERFUSIONCOREGISTRATIONREVIEW.M with the given input arguments.
%
%      PFT_PERFUSIONCOREGISTRATIONREVIEW('Property','Value',...) creates a new PFT_PERFUSIONCOREGISTRATIONREVIEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pft_PerfusionCoregistrationReview_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pft_PerfusionCoregistrationReview_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pft_PerfusionCoregistrationReview

% Last Modified by GUIDE v2.5 29-Jan-2020 17:52:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pft_PerfusionCoregistrationReview_OpeningFcn, ...
                   'gui_OutputFcn',  @pft_PerfusionCoregistrationReview_OutputFcn, ...
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pft_PerfusionCoregistrationReview_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for pft_PerfusionCoregistrationReview
handles.output = hObject;

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
hEpochSliderListener = addlistener(handles.EpochSlider, 'ContinuousValueChange', @CB_EpochSlider_Listener);
setappdata(handles.EpochSlider, 'MyListener', hEpochSliderListener);

hSliceSliderListener = addlistener(handles.SliceSlider, 'ContinuousValueChange', @CB_SliceSlider_Listener);
setappdata(handles.SliceSlider, 'MyListener', hSliceSliderListener);

% Initialise the image display
handles.Data = zeros([176, 352], 'uint8');

handles.Mini = 0;
handles.Maxi = 255;

handles.hImage = imshow(handles.Data, [handles.Mini, handles.Maxi], 'Parent', handles.ImageDisplayAxes);
set(handles.hImage, 'HitTest', 'off', 'PickableParts', 'none');
colormap(handles.ImageDisplayAxes, gray(256));

text(8, 8, 'No data loaded', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', 16, 'FontWeight', 'bold', 'Parent', handles.ImageDisplayAxes, 'Interpreter', 'none');

% Initialise the data source folder and the results folder
fid = fopen('Source-Folder.txt', 'rt');
handles.SourceFolder = fgetl(fid);
fclose(fid);

fid = fopen('Target-Folder.txt', 'rt');
handles.TargetFolder = fgetl(fid);
fclose(fid);

% Disable some features which apply only to a genuine data set (not the initial blank placeholder)
handles.ReviewImagesArePresent = false;

% Set the number of Slices and Epochs to expected values to allow for parameter changes before any images are loaded
handles.NSLICES = 112;
handles.NEPOCHS = 12;

handles.NCoregisteredEpochs = 12;   % E.g., HH030
handles.NOriginalEpochs     = 17;   % E.g., HH030

% Initialise some important display variables
handles.Epoch   = 1;
handles.Slice   = 56;

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

% Set the downsampling factor to x1 to read in images at their original size by default
handles.Reduction = 1;

% Initialise the display mode
handles.Overlay = 'x1 - Original Size';
handles.Epochs  = 'Both';
handles.Method  = 'FalseColor';

% Update the HANDLES structure
guidata(hObject, handles);

% UIWAIT makes pft_PerfusionCoregistrationReview wait for user response (see UIRESUME)
% uiwait(handles.MainFigure);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = pft_PerfusionCoregistrationReview_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImportCineStacksButton_Callback(hObject, eventdata, handles)

% Prompt for a MAT file - do nothing if none is chosen
[ FileName, PathName, FilterIndex ] = uigetfile('*.m', 'Select a co-registered MAT file', fullfile(handles.SourceFolder, '*_TWIST-MM-Spline-Coregistered.mat'));

if (FilterIndex == 0)
  return;
end

handles.SourceFolder               = PathName;
handles.CoregisteredSourceFileName = FileName;
handles.CoregisteredSourcePathName = fullfile(PathName, FileName);

p = strfind(FileName, '-MM-Spline-Coregistered');
q = p(end);
r = q - 1;

handles.OriginalSourceFileName = sprintf('%s.mat', FileName(1:r));
handles.OriginalSourcePathName = fullfile(PathName, handles.OriginalSourceFileName);

% Quit if the ORIGINAL file corresponding to the CO-REGISTERED version is not found
if (exist(handles.OriginalSourcePathName, 'file') ~= 2)
  h = msgbox('Original MAT file not found', 'Data error', 'modal');
  uiwait(h);
  delete(h);
  guidata(hObject, handles);
  return;
end

% Read in the CO-REGISTERED CineStack, the Acquisition Times, and a common working Dicom header
wb = waitbar(0.5, 'Loading CO-REGISTERED data - please wait ... ');

handles.CoregisteredMat = [];
handles.CoregisteredMat = load(fullfile(handles.SourceFolder, handles.CoregisteredSourceFileName));

pause(0.5);
waitbar(1.0, wb, 'Loading complete');
pause(0.5);
delete(wb);

% Read in the ORIGINAL CineStack, the Acquisition Times, and a common working Dicom header
wb = waitbar(0.5, 'Loading ORIGINAL data - please wait ... ');

handles.OriginalMat = [];
handles.OriginalMat = load(fullfile(handles.SourceFolder, handles.OriginalSourceFileName));

pause(0.5);
waitbar(1.0, wb, 'Loading complete');
pause(0.5);
delete(wb);

% Select the cine-stacks at the correct downsampling factor
switch handles.Overlay
  case 'x1 - Original Size'
    handles.Reduction = 1;
    handles.CoregisteredCineStack = handles.CoregisteredMat.CineStackX1;
    handles.OriginalCineStack     = handles.OriginalMat.CineStackX1;
  case 'x2 Downsampled'
    handles.Reduction = 2;
    handles.CoregisteredCineStack = handles.CoregisteredMat.CineStackX2;
    handles.OriginalCineStack     = handles.OriginalMat.CineStackX2;
  case 'x4 Downsampled'
    handles.Reduction = 4;
    handles.CoregisteredCineStack = handles.CoregisteredMat.CineStackX4;
    handles.OriginalCineStack     = handles.OriginalMat.CineStackX4;
  case 'x8 Downsampled'
    handles.Reduction = 8;     
    handles.CoregisteredCineStack = handles.CoregisteredMat.CineStackX8;
    handles.OriginalCineStack     = handles.OriginalMat.CineStackX8;
end 

% Display the image size
CoregisteredDims = size(handles.CoregisteredCineStack);
OriginalDims     = size(handles.OriginalCineStack);

handles.NROWS               = CoregisteredDims(1);
handles.NCOLS               = CoregisteredDims(2);
handles.NSLICES             = CoregisteredDims(3);

handles.NCoregisteredEpochs = CoregisteredDims(4);
handles.NOriginalEpochs     = OriginalDims(4);

set(handles.SizeEdit, 'String', sprintf('  Size:   %1d / %1d / %1d', handles.NROWS, handles.NCOLS, handles.NSLICES));
set(handles.OriginalEpochsEdit, 'String', sprintf('  Original Epochs: %1d', handles.NOriginalEpochs));
set(handles.CoregisteredEpochsEdit, 'String', sprintf('  Co-Registered Epochs: %1d', handles.NCoregisteredEpochs));

% Calculate slice locations from the common working header
[ NR, NC, NP, NE ] = size(handles.OriginalMat.CineStackX1);

handles.ZOx1 = handles.OriginalMat.Head.SliceLocation;
handles.DZx1 = handles.OriginalMat.Head.SliceThickness;
handles.SLx1 = handles.ZOx1 + handles.DZx1*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.OriginalMat.CineStackX2);

handles.ZOx2 = handles.ZOx1 + 0.5*handles.DZx1;
handles.DZx2 = 2.0*handles.DZx1;
handles.SLx2 = handles.ZOx2 + handles.DZx2*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.OriginalMat.CineStackX4);

handles.ZOx4 = handles.ZOx1 + 1.5*handles.DZx1;
handles.DZx4 = 4.0*handles.DZx1;
handles.SLx4 = handles.ZOx4 + handles.DZx4*double(0:NP-1);

[ NR, NC, NP, NE ] = size(handles.OriginalMat.CineStackX8);

handles.ZOx8 = handles.ZOx1 + 3.5*handles.DZx1;
handles.DZx8 = 8.0*handles.DZx1;
handles.SLx8 = handles.ZOx8 + handles.DZx8*double(0:NP-1);

% Update the current slice to allow for possible downsampling
switch handles.Reduction
  case 1
    [ Value, Place ] = min(abs(handles.SLx1 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx1(handles.Slice);
  case 2
    [ Value, Place ] = min(abs(handles.SLx2 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx2(handles.Slice);
  case 4
    [ Value, Place ] = min(abs(handles.SLx4 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx4(handles.Slice);
  case 8
    [ Value, Place ] = min(abs(handles.SLx8 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx8(handles.Slice);
end

% Update the slider settings if necessary
set(handles.SliceSlider, 'Enable', 'on');
set(handles.SliceSlider, 'Max', handles.NSLICES);

% This shouldn't happen - given the code immediately preceding - but it shouldn't do any harm
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

set(handles.SliceSlider, 'Value', handles.Slice);
set(handles.SliceEdit, 'String', sprintf('Slice: %3d', handles.Slice));

% This is a necessary precaution between different data sets
handles.NCommonEpochs = min(handles.NCoregisteredEpochs, handles.NOriginalEpochs);

set(handles.EpochSlider, 'Enable', 'on');

switch handles.Epochs
  case 'Original'
    handles.NEPOCHS = handles.NOriginalEpochs;
  case 'Co-Registered'
    handles.NEPOCHS = handles.NCoregisteredEpochs;
  case 'Both'
    handles.NEPOCHS = handles.NCommonEpochs;
end

set(handles.EpochSlider, 'Max', handles.NEPOCHS);
set(handles.EpochSlider, 'SliderStep', [1.0, 4.0]/double(handles.NEPOCHS - 1));
    
if (handles.Epoch > handles.NEPOCHS)
  handles.Epoch = handles.NEPOCHS; 
end

set(handles.EpochSlider, 'Value', handles.Epoch);
set(handles.EpochEdit, 'String', sprintf('Epoch: %3d', handles.Epoch));

% Note that images have been loaded and need to be displayed
handles.ReviewImagesArePresent = true;

% Enable the Capture Display button
set(handles.CaptureDisplayButton, 'Enable', 'on');

% Select a pair of images to be overlaid
switch handles.Epochs
  case 'Original'
    A = handles.OriginalCineStack(:, :, handles.Slice, 1);
    B = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Co-Registered'
    A = handles.CoregisteredCineStack(:, :, handles.Slice, 1);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Both'
    A = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
end

% Display the overlay
imshowpair(A, B, handles.Method, 'Parent', handles.ImageDisplayAxes);

% Annotate the result
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

Label = handles.OriginalSourceFileName(1:r);

FontSize = 16;
TextStep = FontSize/handles.Reduction;

text(TextStep, TextStep, Label, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

text(TextStep, 2*TextStep, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

switch handles.Epochs
  case 'Original'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Co-Registered'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Both'
    text(TextStep, 3*TextStep, sprintf('Epoch:  %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original and co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
end

% Update the HANDLES structure
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OverlayButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Fetch the selection of overlays
handles.Overlay = get(eventdata.NewValue, 'String');

% Quit if there are no images to display
if (handles.ReviewImagesArePresent == false)
  guidata(hObject, handles);
  return;
end

% Select the cine-stacks at the correct downsampling factor
switch handles.Overlay
  case 'x1 - Original Size'
    handles.Reduction = 1;
    handles.CoregisteredCineStack = handles.CoregisteredMat.CineStackX1;
    handles.OriginalCineStack     = handles.OriginalMat.CineStackX1;
  case 'x2 Downsampled'
    handles.Reduction = 2;
    handles.CoregisteredCineStack = handles.CoregisteredMat.CineStackX2;
    handles.OriginalCineStack     = handles.OriginalMat.CineStackX2;
  case 'x4 Downsampled'
    handles.Reduction = 4;
    handles.CoregisteredCineStack = handles.CoregisteredMat.CineStackX4;
    handles.OriginalCineStack     = handles.OriginalMat.CineStackX4;
  case 'x8 Downsampled'
    handles.Reduction = 8;
    handles.CoregisteredCineStack = handles.CoregisteredMat.CineStackX8;
    handles.OriginalCineStack     = handles.OriginalMat.CineStackX8;
end 

% Fetch the image sizes
CoregisteredDims = size(handles.CoregisteredCineStack);
OriginalDims     = size(handles.OriginalCineStack);

handles.NROWS   = CoregisteredDims(1);
handles.NCOLS   = CoregisteredDims(2);
handles.NSLICES = CoregisteredDims(3);

handles.NCoregisteredEpochs = CoregisteredDims(4);
handles.NOriginalEpochs     = OriginalDims(4);

set(handles.SizeEdit, 'String', sprintf('  Size:   %1d / %1d / %1d', handles.NROWS, handles.NCOLS, handles.NSLICES));

% Update the current slice to allow for possible downsampling
switch handles.Reduction
  case 1
    [ Value, Place ] = min(abs(handles.SLx1 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx1(handles.Slice);
  case 2
    [ Value, Place ] = min(abs(handles.SLx2 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx2(handles.Slice);
  case 4
    [ Value, Place ] = min(abs(handles.SLx4 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx4(handles.Slice);
  case 8
    [ Value, Place ] = min(abs(handles.SLx8 - handles.CurrentSliceLocation));
    handles.Slice = Place;
    handles.CurrentSliceLocation = handles.SLx8(handles.Slice);
end

% Update the slider settings if necessary
set(handles.SliceSlider, 'Max', handles.NSLICES);

set(handles.SliceSlider, 'Value', handles.Slice);
set(handles.SliceEdit, 'String', sprintf('Slice: %3d', handles.Slice));

% Reset the sensitivity of the sliders
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

set(handles.SliceSlider, 'Value', handles.Slice);
set(handles.SliceEdit, 'String', sprintf('Slice: %3d', handles.Slice));

% This is a necessary precaution between different data sets
handles.NCommonEpochs = min(handles.NCoregisteredEpochs, handles.NOriginalEpochs);

set(handles.EpochSlider, 'Enable', 'on');

switch handles.Epochs
  case 'Original'
    handles.NEPOCHS = handles.NOriginalEpochs;    
  case 'Co-Registered'
    handles.NEPOCHS = handles.NCoregisteredEpochs;  
  case 'Both'
    handles.NEPOCHS = handles.NCommonEpochs;   
end

set(handles.EpochSlider, 'Max', handles.NEPOCHS);
set(handles.EpochSlider, 'SliderStep', [1.0, 4.0]/double(handles.NEPOCHS - 1));
    
if (handles.Epoch > handles.NEPOCHS)
  handles.Epoch = handles.NEPOCHS; 
end

set(handles.EpochSlider, 'Value', handles.Epoch);
set(handles.EpochEdit, 'String', sprintf('Epoch: %3d', handles.Epoch));
  
% Select a pair of images to be overlaid
switch handles.Epochs
  case 'Original'
    A = handles.OriginalCineStack(:, :, handles.Slice, 1);
    B = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Co-Registered'
    A = handles.CoregisteredCineStack(:, :, handles.Slice, 1);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Both'
    A = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
end

% Display the overlay
imshowpair(A, B, handles.Method, 'Parent', handles.ImageDisplayAxes);

% Annotate the result
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

Label = handles.OriginalSourceFileName(1:r);

FontSize = 16;
TextStep = FontSize/handles.Reduction;

text(TextStep, TextStep, Label, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

text(TextStep, 2*TextStep, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

switch handles.Epochs
  case 'Original'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Co-Registered'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Both'
    text(TextStep, 3*TextStep, sprintf('Epoch:  %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original and co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
end

% Update the HANDLES structure again
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function EpochsButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Fetch the selection of epochs - Original, Co-Registered or Both
handles.Epochs = get(eventdata.NewValue, 'String');

% Quit if there are no images to display
if (handles.ReviewImagesArePresent == false)
  guidata(hObject, handles);
  return;
end

% Fetch the image sizes
CoregisteredDims = size(handles.CoregisteredCineStack);
OriginalDims     = size(handles.OriginalCineStack);

handles.NROWS   = CoregisteredDims(1);
handles.NCOLS   = CoregisteredDims(2);
handles.NSLICES = CoregisteredDims(3);

handles.NCoregisteredEpochs = CoregisteredDims(4);
handles.NOriginalEpochs     = OriginalDims(4);

set(handles.SizeEdit, 'String', sprintf('  Size:   %1d / %1d / %1d', handles.NROWS, handles.NCOLS, handles.NSLICES));

% This is a necessary precaution between different data sets
handles.NCommonEpochs = min(handles.NCoregisteredEpochs, handles.NOriginalEpochs);

set(handles.EpochSlider, 'Enable', 'on');

switch handles.Epochs
  case 'Original'
    handles.NEPOCHS = handles.NOriginalEpochs;
  case 'Co-Registered'
    handles.NEPOCHS = handles.NCoregisteredEpochs;
  case 'Both'
    handles.NEPOCHS = handles.NCommonEpochs;
end

set(handles.EpochSlider, 'Max', handles.NEPOCHS);
set(handles.EpochSlider, 'SliderStep', [1.0, 4.0]/double(handles.NEPOCHS - 1));
    
if (handles.Epoch > handles.NEPOCHS)
  handles.Epoch = handles.NEPOCHS; 
end

set(handles.EpochSlider, 'Value', handles.Epoch);
set(handles.EpochEdit, 'String', sprintf('Epoch: %3d', handles.Epoch));

% Select a pair of images to be overlaid
switch handles.Epochs
  case 'Original'
    A = handles.OriginalCineStack(:, :, handles.Slice, 1);
    B = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Co-Registered'
    A = handles.CoregisteredCineStack(:, :, handles.Slice, 1);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Both'
    A = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
end

% Display the overlay
imshowpair(A, B, handles.Method, 'Parent', handles.ImageDisplayAxes);

% Annotate the result
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

Label = handles.OriginalSourceFileName(1:r);

FontSize = 16;
TextStep = FontSize/handles.Reduction;

text(TextStep, TextStep, Label, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

text(TextStep, 2*TextStep, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

switch handles.Epochs
  case 'Original'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Co-Registered'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Both'
    text(TextStep, 3*TextStep, sprintf('Epoch:  %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original and co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
end

% Update the HANDLES structure again
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MethodButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)

% Fetch the display method for the image montage
handles.Method = get(eventdata.NewValue, 'String');

% Quit if there are no images to display
if (handles.ReviewImagesArePresent == false)
  guidata(hObject, handles);
  return;
end
  
% Select a pair of images to be overlaid
switch handles.Epochs
  case 'Original'
    A = handles.OriginalCineStack(:, :, handles.Slice, 1);
    B = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Co-Registered'
    A = handles.CoregisteredCineStack(:, :, handles.Slice, 1);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Both'
    A = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
end

% Display the overlay
imshowpair(A, B, handles.Method, 'Parent', handles.ImageDisplayAxes);

% Annotate the result
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

Label = handles.OriginalSourceFileName(1:r);

FontSize = 16;
TextStep = FontSize/handles.Reduction;

text(TextStep, TextStep, Label, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

text(TextStep, 2*TextStep, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

switch handles.Epochs
  case 'Original'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Co-Registered'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Both'
    text(TextStep, 3*TextStep, sprintf('Epoch:  %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original and co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
end

% Update the HANDLES structure again
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CaptureDisplayButton_Callback(hObject, eventdata, handles)

% Capture the image axes
F = getframe(handles.ImageDisplayAxes);
X = F.cdata;

% Offer the option to save the screenshot as an image
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

FileNameStub = handles.OriginalSourceFileName(1:r);

Listing = dir(fullfile(handles.TargetFolder, sprintf('%s_Coregistration_Overlay_*.png', FileNameStub)));
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries(Folders) = [];
Entries = sort(Entries);
Entries = Entries';

if isempty(Entries)
  Suffix = '001';  
    
  DefaultName = fullfile(handles.TargetFolder, sprintf('%s_Coregistration_Overlay_%s.png', FileNameStub, Suffix));
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
    
  DefaultName = fullfile(handles.TargetFolder, sprintf('%s_Coregistration_Overlay_%s.png', FileNameStub, Suffix));
end

FilterSpec  = fullfile(handles.TargetFolder, '*.png');
DialogTitle = 'Save Screenshot As';

[ FileName, PathName, FilterIndex ] = uiputfile(FilterSpec, DialogTitle, DefaultName);

if (FilterIndex ~= 0)
  wb = waitbar(0.5, 'Exporting figure ... ');  
    
  imwrite(X, fullfile(PathName, FileName));
    
  pause(0.5);  
  waitbar(1.0, wb, 'Export complete');
  pause(0.5);
  delete(wb);  
end

% Update the HANDLES structure - is this really necessary here, since "handles" is used in a read-only way here ? 
guidata(hObject, handles);
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SizeEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this control is read-only (but writable programmatically)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SizeEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OriginalEpochsEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this control is read-only (but writable programmatically)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OriginalEpochsEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CoregisteredEpochsEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this control is read-only (but writable programmatically)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CoregisteredEpochsEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SliceSlider_Callback(hObject, eventdata, handles)

% Fetch the current slice and update the text display
handles.Slice = round(get(hObject, 'Value'));
set(handles.SliceEdit, 'String', sprintf('Slice: %3d', handles.Slice));

% Update the current slice location
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

% Select a pair of images to be overlaid
switch handles.Epochs
  case 'Original'
    A = handles.OriginalCineStack(:, :, handles.Slice, 1);
    B = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Co-Registered'
    A = handles.CoregisteredCineStack(:, :, handles.Slice, 1);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Both'
    A = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
end

% Display the overlay
imshowpair(A, B, handles.Method, 'Parent', handles.ImageDisplayAxes);

% Annotate the result
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

Label = handles.OriginalSourceFileName(1:r);

FontSize = 16;
TextStep = FontSize/handles.Reduction;

text(TextStep, TextStep, Label, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

text(TextStep, 2*TextStep, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

switch handles.Epochs
  case 'Original'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Co-Registered'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Both'
    text(TextStep, 3*TextStep, sprintf('Epoch:  %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original and co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
end

% Update the HANDLES structure again
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_SliceSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the current slice and update the text display
handles.Slice = round(get(hObject, 'Value'));
set(handles.SliceEdit, 'String', sprintf('Slice: %3d', handles.Slice));

% Update the current slice location
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

% Select a pair of images to be overlaid
switch handles.Epochs
  case 'Original'
    A = handles.OriginalCineStack(:, :, handles.Slice, 1);
    B = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Co-Registered'
    A = handles.CoregisteredCineStack(:, :, handles.Slice, 1);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Both'
    A = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
end

% Display the overlay
imshowpair(A, B, handles.Method, 'Parent', handles.ImageDisplayAxes);

% Annotate the result
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

Label = handles.OriginalSourceFileName(1:r);

FontSize = 16;
TextStep = FontSize/handles.Reduction;

text(TextStep, TextStep, Label, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

text(TextStep, 2*TextStep, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

switch handles.Epochs
  case 'Original'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Co-Registered'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Both'
    text(TextStep, 3*TextStep, sprintf('Epoch:  %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original and co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
end

% Update the HANDLES structure again
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SliceSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function EpochSlider_Callback(hObject, eventdata, handles)

% Fetch the current epoch and update the text display
handles.Epoch = round(get(hObject, 'Value'));
set(handles.EpochEdit, 'String', sprintf('Epoch: %3d', handles.Epoch));

% Select a pair of images to be overlaid
switch handles.Epochs
  case 'Original'
    A = handles.OriginalCineStack(:, :, handles.Slice, 1);
    B = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Co-Registered'
    A = handles.CoregisteredCineStack(:, :, handles.Slice, 1);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Both'
    A = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
end

% Display the overlay
imshowpair(A, B, handles.Method, 'Parent', handles.ImageDisplayAxes);

% Annotate the result
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

Label = handles.OriginalSourceFileName(1:r);

FontSize = 16;
TextStep = FontSize/handles.Reduction;

text(TextStep, TextStep, Label, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

text(TextStep, 2*TextStep, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

switch handles.Epochs
  case 'Original'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Co-Registered'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Both'
    text(TextStep, 3*TextStep, sprintf('Epoch:  %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original and co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
end

% Update the HANDLES structure again
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CB_EpochSlider_Listener(hObject, eventdata, handles)

% This was necessary in MATLAB 2013b
if ~(exist('handles', 'var'))
  handles = guidata(hObject);  
end

% Fetch the current epoch and update the text display
handles.Epoch = round(get(hObject, 'Value'));
set(handles.EpochEdit, 'String', sprintf('Epoch: %3d', handles.Epoch));

% Select a pair of images to be overlaid
switch handles.Epochs
  case 'Original'
    A = handles.OriginalCineStack(:, :, handles.Slice, 1);
    B = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Co-Registered'
    A = handles.CoregisteredCineStack(:, :, handles.Slice, 1);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
  case 'Both'
    A = handles.OriginalCineStack(:, :, handles.Slice, handles.Epoch);
    B = handles.CoregisteredCineStack(:, :, handles.Slice, handles.Epoch);
end

% Display the overlay
imshowpair(A, B, handles.Method, 'Parent', handles.ImageDisplayAxes);

% Annotate the result
p = strfind(handles.OriginalSourceFileName, '.');
q = p(end);
r = q - 1;

Label = handles.OriginalSourceFileName(1:r);

FontSize = 16;
TextStep = FontSize/handles.Reduction;

text(TextStep, TextStep, Label, 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

text(TextStep, 2*TextStep, sprintf('Slice: %3d', handles.Slice), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);

switch handles.Epochs
  case 'Original'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Co-Registered'
    text(TextStep, 3*TextStep, sprintf('Epochs: 1 and %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
  case 'Both'
    text(TextStep, 3*TextStep, sprintf('Epoch:  %1d', handles.Epoch), 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
    text(TextStep, 4*TextStep, 'Original and co-registered images', 'Color', [1 1 0], 'FontName', 'FixedWidth', 'FontSize', FontSize, 'FontWeight', 'bold', 'Interpreter', 'none', 'Parent', handles.ImageDisplayAxes);
end

% Update the HANDLES structure again
guidata(hObject, handles);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function EpochSlider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SliceEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this control is read-only (but writable programmatically)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SliceEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function EpochEdit_Callback(hObject, eventdata, handles)
  % Nothing to do here - this control is read-only (but writable programmatically)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function EpochEdit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
  set(hObject, 'BackgroundColor', 'white');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_KeyPressFcn(hObject, eventdata, handles)

switch eventdata.Key
  case { 'escape', 'return' }    
    delete(handles.MainFigure);
  otherwise
    return;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MainFigure_DeleteFcn(hObject, eventdata, handles)

delete(handles.MainFigure);

end
