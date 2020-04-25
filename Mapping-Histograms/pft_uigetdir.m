function folder_name = pft_uigetdir(start_path, dialog_title)

% Supply a prompt to the user on the Mac
if ismac
  h = msgbox(dialog_title, 'Prompt', 'modal');
  uiwait(h);
  delete(h);
end

folder_name = uigetdir(start_path, dialog_title);

end
