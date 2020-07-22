# MRI VQ mapping
Parametric mapping of MR lung perfusion and oxygen-enhanced imaging

## Dependencies
All of the following applications were written in ```MATLAB 2015aSP1```, ```2017b``` or ```2020a```.
In most cases, these versions are required to ensure that specific features of particular programs work correctly.

At least the following toolboxes are needed (to run the software from the MATLAB IDE):

- Signal Processing.
- Image Processing.
- Statistics and Machine Learning.

For a more portable solution, the authors may be approached to create standalone executables of a particular script or GUI.
Please specify the platform when making the request.

## Data Preparation
MAT-format "pickle" files are created for each study.

In the folder ```Data-Pickles```, use the script ```pft_CreateDataPickles.m```.

Be sure to initialise the text file ```Top-Level-Folder.txt``` first.

Each pickle contains:

- A DCE-MRI cine-stack (single-precision, floating-point), in the order (Rows, Cols, Planes, Epochs), last index varying most slowly.
- Three downsampled versions of the basic cine-stack, reduced (spatially) by x2, x4 and x8 - the temporal dimension is unaffected.
- An array of Acquisition Times for the later perfusion analysis.
- A sample DICOM header used to create DICOM-format outputs during perfusion mapping.

```This script was written using MATLAB 2017b, and may not work correctly with earlier versions.```

## Co-Registration
Epochs later than one - up to the Last Usable Frame - are co-registered to the first using a free-form B-spline deformation.

Each volume is first interpolated to isotropic voxels using ```imresize3```; the co-registration step is performed using ```imregdemons``` with default parameters, after which the co-registered volume is downsampled to the original resolution.

Downsampled versions of the co-registered volumes (x2, x4, x8) are created using a "box" kernel, and saved with the full-resolution volumes.

An array of Acquisition Times and a sample Dicom header are saved with the co-registered cine-stacks in a pickle file with the same format as the input; an extension of ```-MM-Spline-Coregistered``` is added to the filename.

To co-register one data set, use the function ```pft_MultiModalCoregisterOnePickleFileInteractively.m```.

The function ```pft_MultiModalCoregisterOnePickleFileAutomatically.m``` is also provided, and is straightforwardly scripted.

```These functions were written using MATLAB 2017b; they should work correctly with later versions, but may not with earlier ones.```

## Co-Registration Review
Since co-registration is a lengthy process, a single-dialog GUI has been created to allow comparisons between:

- Epochs 1 and N of the original cine-stack.
- Epochs 1 and N of the co-registered cine-stack.
- Simultaneous epochs of the original and co-registered images.

The active function here is ```pft_PerfusionCoregistrationReview.m```.

Be sure to initialise the text files ```Source-Folder.txt``` and ```Target-Folder.txt```.

```This MATLAB GUIDE application was created with MATLAB 2017b.```

## Co-Registration Review for MacOS
The functionality is the same as for the generic release; this build has been tailored to a local MacOS machine with a dual monitor display.

The active function here is ```pft_PerfusionCoregistrationReviewMacOS.m```.

```This MATLAB GUIDE application was created with MATLAB 2017b.```

## Perfusion Mapping
Perfusion maps are created from the initial "pickle" files.

In the folder ```Perfusion-GUIDE-Project```, use the function ```pft_DceMriPerfusionGui.m```.

This is documented with both a ```Quick User's Guide``` and a ```Short Checklist```.
A more extended technical description will follow.

The pixel-wise mapping is performed by deconvolving a measured ```Arterial Input Function``` from the local contrast ```time-course``` to yield a ```residue``` (impulse response) function. The following maps are created:

- Pulmonary Blood Volume (PBV), with and without filtering (apodisation of the AIF and time-course).
- Pulmonary Blood Flow (PBF), again, with and without filtering.
- Time to Peak (TTP).
- Mean Transit Time (MTT). This is calculated using the central moment theorem, making MTT a primary quantity and PBF = PBV/MTT secondary.

The user is required to set:

- The last usable frame (just before breath-holding fails).
- A region of interest within the main pulmonary artery.
- A number of deconvolution parameters.
- A processing threshold.

These decisions can be made during an initial, interactive phase of data review.
The effect of changing the deconvolution parameters may be examined by freezing the time-course display at a given voxel.
Conversely, the effect of applying a given set of parameters across the cine-stack is visible in an unfrozen display.

The mapping outputs are:

- A summary XL file with multiple tabs.
- A PNG-format black-and-white image of the region-of-interest selected in the MPA.
- A MAT-format pickle file conatining the 6 maps, plus the ROI.
- A folder of the maps in DICOM format, organised into sub-folders. 

The working reference is:

Perfusion: DSC & DCE Basics and Analysis.
Linda Knutsson, Proc. Intl. Soc. Magn. Reson. Med. 21, (2013).

```This GUI was created using MATLAB 2015aSP1, and may not work correctly with earlier or later versions.```

## Perfusion Mapping for MacOS

In the folder ```Perfusion-GUIDE-Project-MacOS```, use the function ```pft_DceMriPerfusionGuiMacOS.m```.

The only difference from the Windows version is that output summaries are written as single-page CSV files,
rather than XLSX files with multiple tabs.

## Perfusion Mapping - Ingrisch Version

In the folder ```Perfusion-GUIDE-Project-Ingrisch```, use the function ```pft_DceMriPerfusionGuiIngrisch.m```.

The working reference is:

Quantitative Pulmonary Perfusion Magnetic Resonance Imaging: Influence of Temporal Resolution and Signal-to-Noise Ratio.
Michael Ingrisch et al, Investigative Radiology 45(1), pp.7-14, January 2010.

The cross-correlation between the time-course and the AIF is used together with the PBV to perform a semi-automatic
segmentation of the lungs from the rest of the anatomy. This thresholding step is computationally expensive and the execution
is accordingly slow.

Here, the PBF is estimated from the peak of the residue function after deconvolution, making PBF a primary measure and MTT = PBV/PBF secondary.

## Perfusion Mapping - Ingrisch Version for MacOS

In the folder ```Perfusion-GUIDE-Project-Ingrisch-MacOS```, use the function ```pft_DceMriPerfusionGuiIngrischMacOS.m```.

## Perfusion Mapping - Hybrid Version

In the folder ```Perfusion-GUIDE-Project-Hybrid```, use the function ```pft_DceMriPerfusionGuiHybrid.m```.

This GUI combines the simple thresholding of the original "Mapping" workflow with the calculations of the "Ingrisch" method.

A percentage signal threshold is required from the user, and interpolation around the peak of the residue function is optional.

## Perfusion Mapping - Hybrid Version for MacOS

In the folder ```Perfusion-GUIDE-Project-Hybrid-MacOS```, use the function ```pft_DceMriPerfusionGuiHybridMacOS.m```.

## Segmentation and Quantitation
A simple GUI allows manual segmentation of the lungs from previously created perfusion maps.

Statitistics may then be saved to an XLSX file. Up to 10 tabs provide information on:

- Data dimensions and resolution.
- Voxel counts and volumes in the segmented regions, including deficit fractions (volumes where no significant perfusion was observed).
- PBV, including means, medians, standard deviations, minima and maxima.
- Unfiltered PBV.
- PBF.
- Unfiltered PBF.
- MTT.
- Unfiltered MTT.
- TTP.
- Data censorship.

Results are grouped together for the right lung, left lung, and the combined region.

The interface is straightforward and the outputs are self-explanatory.

The GUI has been generalised to accept inputs from Mark 1 Mapping, Mark 2 Ingrisch and Mark 3 Hybrid workflows.

```This GUI was created using MATLAB 2015aSP1, and may not work correctly with earlier or later versions.```

## Segmentation and Quantitation for MacOS

Outputs are written to a single-page CSV file rather than a multi-tab XLSX; results can be straightforwardly transcribed at a later stage.

```This GUI was created using MATLAB 2015aSP1, and may not work correctly with earlier or later versions.```

## Segmentation from Grayscale Images
Segmentation using perfusion maps may be difficult in the presence of gross perfusion deficits.
This GUI allows segmentation using the original grayscale cine-stacks.

Quantitation using the manually drawn regions-of-interest and the previously calculated perfusion maps may then carried out using the separate Segmentation-Quantitation GUI.

```This GUI was created using MATLAB 2015aSP1, and may not work correctly with earlier or later versions.```

## Segmentation from Grayscale Images - Freehand or Assisted
Segmentation of the original grayscale images using either a freehand operation (one flowing movement of the mouse, trackpad or pen, or several mouse clicks), or an edge-detected tracing of a region boundary, with mouse clicks to define the waypoints.

Regions of interest are overlaid (with controlled transparency) on the grayscale images, so that they can be visualised at different epochs.

Regions can be created, modified or deleted.

Segmentations can be read in from other applications - e.g., the flood-filling GUI - and modified here.

Masks are written to the usual Left and Right Lung sub-folders. Region boundaries and waypoints are stored in ```Positions.mat```, and vertices in ```Polygons.mat```.

```This GUI was created using MATLAB 2020a, and will not work correctly with versions much earlier than that.```

## Segmentation from Grayscale Images - Freehand or Assisted - MacOS
Created to accommodate a MacOS system with multiple monitors.
The main dialog may be maximised to make all the controls visible.

```This GUI was created using MATLAB 2020a, and will not work correctly with much earlier versions.```

## Mapping Histograms
Histograms are generated from segmented maps.

Run the script ```pft_CreateHistograms```.

The two inputs are:

- The mapping data pickle.
- The segmentation folder.

The name of the output folder matches that of the segmentation folder.

Histograms are created for the right and left lungs, both separately and together, for the following parameters:

- PBV.
- Unfiltered PBV (if present).
- PBF.
- Unfiltered PBF (if present).
- MTT.
- Unfiltered MTT (if present).
- TTP.

Graphs are stored in several formats - for use with further software downstream - and there are several PDF compilations,
including one with a heavily decorated name to indicate the source of the data.

This script should work for results from any mapping workflow, and on any platform.

```This script was created using MATLAB 2017b; use with earlier or later versions may alter the appearance of the graphs produced.```

## Create Overlays
Overlays of segmented perfusion maps on a grayscale background are created (movies or single frames).

Run the function ```pft_CreatePerfusionOverlays```.

The three inputs are:

- The mapping data pickle.
- The segmentation folder.
- The grayscale cine-stack.

The second is inferred from the first; it has the same name (without the suffix) and must be correctly located within the folder structure.

Three text-mode start-up files need to be edited by hand for the application to work in a specific user environment.

The possible outputs are:

- PNG screen captures.
- AVI movies.

The operation of the GUI is WYSIWIG and the interface is self-explanatory.

All controls affecting the appearance of the display in the image axes are immediately responsive.

The available compositions are:

- Grayscale slices.
- Grayscale slices with overlays.
- Grayscale epochs.
- Grayscale epochs with overlays.
- Maps only.

Segmentation may be turned on or off.

Movies may include all the slices, or just those between the first and last included in the segmentation.

The opacity control allows the creation of "overlays" containing just the grayscale slice, or only the perfusion map,
or a transparent rendition of the two.

The application interrogates the input pickle file to determine which maps are present - note the greyed "View Map" controls
along the right-hand edge. This is designed to accommodate pickle files containing different collections of maps,
calculated by a later version of the mapping GUI.

```This MATLAB GUIDE application was created with MATLAB 2017b. Graphics may appear slightly different in earlier or later versions.```

## Create Overlays for MacOS
A version created to overcome problems with a dual monitor system on an Apple Mac.

Run the function ```pft_CreatePerfusionOverlaysMacOS```.

```This MATLAB GUIDE application was created with MATLAB 2017b. Graphics may appear slightly different in earlier or later versions.```

## Update Excel Files
House-keeping scripts for use on MS Windows only.

Browse to the folder ```Main-Scripts``` after placing the main folder and all of its sub-folders on the MATLAB path.

For each workflow (Mark 1 Mapping, Ingrisch, Hybrid), there are two scripts; these collate respectively:

- The mapping parameters for each processing of a given data pickle;
- The quantitative results following manual segmentation.

As usual, the local TXT files need to be maintained to point to the appropriate folders on the user's local machine.

## Segment Grayscale Images by Flood-Filling
Lung cavities may be segmented by selecting a single seed-point with the mouse.
A small suite of parameters controls the flood-filling operation.

Run the function ```pft_DceMriPerfusionSegmentGrayscaleFloodFill.m```

```This MATLAB GUIDE application was created with MATLAB 2017b, although this consideration is probably not critical.```

## Segment Grayscale Images by Flood-Filling - MacOS Version
Created to address possible problems with dual monitors on a MacOS system.

Run the function ```pft_DceMriPerfusionSegmentGrayscaleFloodFillMacOS.m```

```This MATLAB GUIDE application was created with MATLAB 2017b, although this consideration is probably not critical.```

## Combine Histograms Retrospectively
Create a montage of the Right/Left/Total histograms of the segmented MTT, PBV, PBF and TTP.

Two scripts are available, to create outputs in mutually transposed arrangements: ```pft_CreateHistogramMontage.m``` and ```pft_CreateHistogramMontageTransposed.m.```

```These scripts created with MATLAB 2017b, although this consideration is probably not critical.```

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3956495.svg)](https://doi.org/10.5281/zenodo.3956495)



