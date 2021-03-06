function epoch = new_epoch_data(obj, pts_in_epoch, epoch_duration)

if nargin < 2
    pts_in_epoch = 0;
end

if nargin < 3
    epoch_duration = 0;
end

epoch = struct( ...
    'pts_in_epoch', uint32(pts_in_epoch), ...
	'epoch_duration', single(epoch_duration), ...
	'expected_iti',  single(0), ...
	'actual_iti',  single(0), ...
	'total_var_events', uint32(0), ...
	'checksum', int32(0), ...
	'epoch_timestamp', int32(0), ...
	'reserved', zeros(1, 28, 'uint8'));

epoch = fix_checksum(obj, epoch);
