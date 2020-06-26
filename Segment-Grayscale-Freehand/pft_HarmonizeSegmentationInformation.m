function [ BW, XY, WP, PP ] = pft_HarmonizeSegmentationInformation(bw, xy, wp, pp)
% Inputs and outputs are:
% BW - a stack of binary masks.
% XY - a cell array of positions
% WP - a cell array of waypoint vectors, one per slice
% PP - a cell array of polygons
% 
% Some inputs may be missing at particular slices because:
% - Flood-filling was used (so, no polygons);
% - Polygons were not properly saved in an earlier GUI;
% - Positions and waypoints were not implemented in applications before this one.

% Fetch the dimensions first
Dims = size(bw);
Rows = Dims(1);
Cols = Dims(2);
Plns = Dims(3);

% Initialize the outputs - make them equal to the inputs
BW = bw;
XY = xy;
WP = wp;
PP = pp;

% Iterate over the slices of the binary mask - these will always be present, though some may be all-false
wb = waitbar(0, 'Harmonizing segmentation data ... ');

for n = 1:Plns
  Part = squeeze(bw(:, :, n));
  
  if ~any(Part)
    waitbar(double(n)/double(Plns), wb, sprintf('Processed %1d of %1d slices', n, Plns));
    continue;
  end
  
  if ~isempty(xy{n}) && ~isempty(wp{n}) && isempty(pp{n})
    Position  = xy{n};
    Waypoints = wp{n};
    PP{n} = Position(Waypoints, :);
  elseif isempty(xy{n}) && isempty(wp{n}) && ~isempty(pp{n})
    Position = pp{n};
    NPTS  = length(Position);
    XY{n} = Position;
    WP{n} = true(NPTS, 1);    
  elseif isempty(xy{n}) && isempty(wp{n}) && isempty(pp{n})
    Boundary = bwboundaries(Part, 8);
    Position = Boundary{1};
    Position = flip(Position, 2);
    NPTS = length(Position);
    STEP = idivide(int32(NPTS), int32(20));
    Waypoints = false(NPTS, 1);
    Waypoints(1:STEP:end) = true;
    XY{n} = Position;
    WP{n} = Waypoints;
    PP{n} = Position(Waypoints, :);
  end  
  
  waitbar(double(n)/double(Plns), wb, sprintf('Processed %1d of %1d slices', n, Plns));  
end

waitbar(double(n)/double(Plns), wb, 'All slices processed !');
pause(1.0);
delete(wb);

end
