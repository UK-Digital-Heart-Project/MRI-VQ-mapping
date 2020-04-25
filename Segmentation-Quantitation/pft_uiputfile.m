function [ FileName, PathName, FilterIndex] = pft_uiputfile(FilterSpec, DialogTitle, DefaultName)

% Supply a prompt to the user on the Mac
if ismac
  h = msgbox(DialogTitle, 'Prompt', 'modal');
  uiwait(h);
  delete(h);
end

[ FileName, PathName, FilterIndex] = uiputfile(FilterSpec, DialogTitle, DefaultName);

end

