function pft_AppendOneXlsxIngrischQuantificationFile(Source, Target)

% Extract the filename from the full path of the source file
[ P, F, E ] = fileparts(Source);

QuantificationSummaryFileName = strcat(F, E);

% Process the "Resolution" tab
[ Num, Txt, Raw ] = xlsread(Source, 'Resolution');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'Resolution');

% Process the "Deficits" tab
[ Num, Txt, Raw ] = xlsread(Source, 'Deficits');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'Deficits');

% Process the "PBV" tab
[ Num, Txt, Raw ] = xlsread(Source, 'PBV');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'PBV');

% Process the "Unfiltered PBV" tab
[ Num, Txt, Raw ] = xlsread(Source, 'Unfiltered PBV');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'Unfiltered PBV');

% Process the "PBF" tab
[ Num, Txt, Raw ] = xlsread(Source, 'PBF');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'PBF');

% Process the "MTT" tab
[ Num, Txt, Raw ] = xlsread(Source, 'MTT');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'MTT');

% Process the "Unfiltered MTT" tab
[ Num, Txt, Raw ] = xlsread(Source, 'Unfiltered MTT');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'Unfiltered MTT');

% Process the "TTP" tab
[ Num, Txt, Raw ] = xlsread(Source, 'TTP');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'TTP');

% Process the "Censorship" tab
[ Num, Txt, Raw ] = xlsread(Source, 'Censorship');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'Censorship');

end

