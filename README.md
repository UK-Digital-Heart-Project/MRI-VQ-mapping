# MRI VQ mapping
Parametric mapping of MR lung perfusion and oxygen-enhanced imaging

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

## Perfusion Mapping
Perfusion maps are created from the initial "pickle" files.

In the folder ```Perfusion-GUIDE-Project```, use the function ```pft_DceMriPerfusionGui.m```.

This is documented with both a ```Quick User's Guide``` and a ```Short Checklist```.
A more extended technical description will follow.

The pixel-wise mapping is performed by deconvolving a measured ```Arterial Input Function``` from the local contrast ```time-course``` to yield a ```residue``` (impulse response) function. The following maps are created:

- Pulmonary Blood Volume (PBV), with and without filtering (apodisation of the AIF and time-course).
- Pulmonary Blood Flow (PBF), again, with and without filtering.
- Time to Peak (TTP).
- Mean Transit Time (MTT).

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

```This GUI was created using MATLAB 2015aSP1, and may not work correctly with earlier or later versions.```

## Co-Registration
Epochs later than one - up to the Last Usable Frame - are co-registered to the first using a free-form B-spline deformation.

Each volume is first interpolated to isotropic voxels using ```imresize3```; the co-registration step is performed using ```imregdemons``` with default parameters, after which the co-registered volume is downsampled to the original resolution.

Downsampled versions of the co-registered volumes (x2, x4, x8) are created using a "box" kernel, and saved with the full-resolution volumes.

An array of Acquisition Times and a sample Dicom header are saved with the co-registered cine-stacks in a pickle file with the same format as the input; an extension of ```-MM-Spline-Coregistered``` is added to the filename.

To co-register one data set, use the function ```pft_MultiModalCoregisterOnePickleFileInteractively.m```.

The function ```pft_MultiModalCoregisterOnePickleFileAutomatically.m``` is also provided, and is straightforwardly scripted.

```These functions were written using MATLAB 2017b; they should work correctly with later versions, but not with earlier ones.```




