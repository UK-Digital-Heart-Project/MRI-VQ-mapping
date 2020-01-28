function SubFolders = pft_ListTwistFolders(Root)

% List the sub-folders of the Root folder
Listing    = dir(Root);
SubFolders = { Listing.name };
Folders    = [ Listing.isdir ];
SubFolders = SubFolders(Folders);
SubFolders = sort(SubFolders);
SubFolders = SubFolders';

SingleDot = strcmpi(SubFolders, '.');
SubFolders(SingleDot) = [];

DoubleDot = strcmpi(SubFolders, '..');
SubFolders(DoubleDot) = [];

% Return if no sub-folders are found
if isempty(SubFolders)
  return;
end

% Retain the sub-folders that contain "TWIST"
Retain = contains(SubFolders, 'TWIST');
SubFolders = SubFolders(Retain);

% Return if no sub-folders remain
if isempty(SubFolders)
  return;
end

% Discard any remaining folders containing "MIP" or "SUB"
Delete = contains(SubFolders, 'MIP') | contains(SubFolders, 'SUB') | contains(SubFolders, 'TEST')
SubFolders(Delete) = [];

% Return if no sub-folders remain
if isempty(SubFolders)
  return;
end

end




