# MRI VQ mapping
Parametric mapping of MR lung perfusion and oxygen-enhanced imaging

## Data Preparation
MAT-format "Pickle" files are created for each study.

In the folder ```Data-Pickles```, use the script ```pft_CreateDataPickles.m```.

Be sure to initialise the text file ```Top-Level-Folder.txt``` first.

Each pickle contains:

- A DCE-MRI cine-stack (single-precision, floating-point), in the order (Rows, Cols, Planes, Epochs), last index varying most slowly.
- Three downsampled versions of the basic cine-stack, reduced (spatially) by x2, x4 and x8 - the temporal dimension is unaffected.
- An array of Acquisition Times for the later perfusion analysis.
- A sample DICOM header used to create DICOM-format outputs during perfusion mapping.

```This script was written using MATLAB 2017b, and may not work correctly with earlier versions.```

## Perfusion Mapping

