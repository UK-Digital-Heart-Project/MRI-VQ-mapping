function pft_AppendOneXlsxMappingFile(Source, Target)

% Extract the filename from the full path of the source file
[ P, F, E ] = fileparts(Source);

MappingSummaryFileName = strcat(F, E);

% Process the "ROI" tab
[ Num, Txt, Raw ] = xlsread(Source, 'ROI');

Data = Raw(2:end, :);

Data = horzcat({ MappingSummaryFileName }, Data);

xlsappend(Target, Data, 'ROI');

% Process the "AIF" tab
[ Num, Txt, Raw ] = xlsread(Source, 'AIF');

Data = Raw(2:end, :);

TIMS = size(Data, 1);

Pads = cell([TIMS - 1, 1]);

Left = vertcat({ MappingSummaryFileName }, Pads);

Full = horzcat(Left, Data);

xlsappend(Target, Full, 'AIF');

% Process the "Deconvolution" tab
[ Num, Txt, Raw ] = xlsread(Source, 'Deconvolution');

Data = Raw(2:end, :);

Data = horzcat({ MappingSummaryFileName }, Data);

xlsappend(Target, Data, 'Deconvolution');

% Process the "Filtering" tab
[ Num, Txt, Raw ] = xlsread(Source, 'Filtering');

Data = Raw(2:end, :);

TIMS = size(Data, 1);

Pads = cell([TIMS - 1, 1]);

Left = vertcat({ MappingSummaryFileName }, Pads);

Full = horzcat(Left, Data);

xlsappend(Target, Full, 'Filtering');

end

