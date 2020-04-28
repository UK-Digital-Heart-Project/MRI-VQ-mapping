function pft_AppendOneXlsxQuantificationFile(Source, Target, UnfilteredPBVHead, UnfilteredPBFHead)

% Extract the filename from the full path of the source file
[ P, F, E ] = fileparts(Source);

QuantificationSummaryFileName = strcat(F, E);

% Check which sheets are present - the unfiltered PBV and PBF may be absent from some of the early files
[ Status, Sheets ] = xlsfinfo(Source);

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

% Process the "Unfiltered PBV" tab specially
if any(strcmpi(Sheets, 'Unfiltered PBV'))
  [ Num, Txt, Raw ] = xlsread(Source, 'Unfiltered PBV');

  Data = Raw(2:end, :);

  Data = horzcat({ QuantificationSummaryFileName }, Data);

  xlsappend(Target, Data, 'Unfiltered PBV');
else
  Width = size(UnfilteredPBVHead, 2);
  Blank = repmat({ 'N/A' }, 1, Width - 1);
  Dummy = horzcat({ QuantificationSummaryFileName }, Blank);
  
  xlsappend(Target, Dummy, 'Unfiltered PBV');
end

% Process the "PBF" tab
[ Num, Txt, Raw ] = xlsread(Source, 'PBF');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'PBF');

% Process the "Unfiltered PBF" tab specially
if any(strcmpi(Sheets, 'Unfiltered PBF'))
  [ Num, Txt, Raw ] = xlsread(Source, 'Unfiltered PBF');

  Data = Raw(2:end, :);

  Data = horzcat({ QuantificationSummaryFileName }, Data);

  xlsappend(Target, Data, 'Unfiltered PBF');
else
  Width = size(UnfilteredPBFHead, 2);
  Blank = repmat({ 'N/A' }, 1, Width - 1);
  Dummy = horzcat({ QuantificationSummaryFileName }, Blank);
  
  xlsappend(Target, Dummy, 'Unfiltered PBF');
end

% Process the "MTT" tab
[ Num, Txt, Raw ] = xlsread(Source, 'MTT');

Data = Raw(2:end, :);

Data = horzcat({ QuantificationSummaryFileName }, Data);

xlsappend(Target, Data, 'MTT');

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

