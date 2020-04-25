function [pathname] = pft_uigetfile_n_dir(start_path, dialog_title)

% Supply a prompt to the user on the Mac
if ismac
  h = msgbox(dialog_title, 'Prompt', 'modal');
  uiwait(h);
  delete(h);
end

% The remaining code is unaltered from the Mathworks download (aside from minor formatting)
import javax.swing.JFileChooser;

jchooser = javaObjectEDT('javax.swing.JFileChooser', start_path);

jchooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
if nargin > 1
    jchooser.setDialogTitle(dialog_title);
end

jchooser.setMultiSelectionEnabled(true);

status = jchooser.showOpenDialog([]);

if status == JFileChooser.APPROVE_OPTION
  jFile = jchooser.getSelectedFiles();
  pathname{size(jFile, 1)}=[];
  for n=1:size(jFile, 1)
    pathname{n} = char(jFile(n).getAbsolutePath);
  end	
elseif status == JFileChooser.CANCEL_OPTION
  pathname = [];
else
  error('Error occured while picking file.');
end

end
