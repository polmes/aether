function flight3D(t, lat, lon, alt, ph, th, ps, scaling)
	%% GENERATE SIMULATION DATA

	% Handle inputs
	if nargin == 7
		scaling = 30;
	end

	% Build FlightGear animation object
	h = fganimation;
	h.TimeseriesSource = [t, lat, lon, alt, ph, th, ps];
	h.TimeScaling = scaling;

	%% FLIGHTGEAR

	% Apollo aircraft files
	aircraft = 'apollo';
	directory = fullfile(pwd, 'constants', aircraft);

	% Build command line call
	opts = '--fdm=network,localhost,5501,5502,5503 --units-meters --enable-freeze --enable-terrasync --timeofday=morning --prop:/sim/current-view/view-number=1';
	cmd = ['fgfs --aircraft=' aircraft ' --aircraft-dir=' directory ' --lat=' num2str(rad2deg(lat(1))) ' --lon=' num2str(rad2deg(lon(1))) ' --altitude=' num2str(alt(1)) ' ' opts];

	% Start FlightGear
	status = system(['LD_LIBRARY_PATH="" ' cmd ' &']);
	if status > 0
		util.exception('Error during call to FlightGear fgfs executable');
	end

	% Wait until user is ready
	disp('Press any key when FlightGear is ready');
	pause;

	%% VISUALIZE SIMTLATION

	% Interface with FlightGear
	run = true;
	while run
		% Playback
		play(h);
		disp('Playing back...');

		% Repeat?
		pause(t(end) / h.TimeScaling);
		disp('Press R to replay simulation or other key to exit');

		% Trick MATLAB into reading keyboard
		f = figure('Position', [0 0 1 1], ...
			'Name', 'Waiting...', 'NumberTitle', 'off', ...
			'WindowKeyPressFcn', @keycheck);
		waitfor(f, 'UserData');
		if ~strcmp(f.UserData, 'r')
			run = false;
		end
		close(f);
	end

	% Kill FlightGear
	system('killall fgfs');
end

function keycheck(obj, KeyData)
	set(obj, 'UserData', KeyData.Key);
end
