function [ FileName, PathName, FilterIndex ] = pft_uigetfile(FilterSpec, DialogTitle, DefaultName)

% Supply a prompt to the user on the Mac
if ismac
  h = msgbox(DialogTitle, 'Prompt', 'modal');
  uiwait(h);
  delete(h);
end

[ FileName, PathName, FilterIndex ] = uigetfile(FilterSpec, DialogTitle, DefaultName);

end




