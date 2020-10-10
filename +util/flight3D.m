function flight3D(t, S, pl)
	%% GENERATE SIMULATION DATA
	
	% Assemble variables into timeseries
	[lat, lon, alt] = pl.xyz2lla(S(:,1), S(:,2), S(:,3), t);
	q0 = S(:,4); q1 = S(:,5); q2 = S(:,6); q3 = S(:,7);
	ph = real(atan2(2 * (q0.*q1 + q2.*q3), 1 - 2 * (q1.^2 + q2.^2)));
	th = real(asin(2 * (q0.*q2 - q3.*q1)));
	ps = real(atan2(2 * (q0.*q3 + q1.*q2), 1 - 2 * (q2.^2 + q3.^2)));
	ts = [t, lat, lon, alt, ph, th, ps];
	
	% Build FlightGear animation object
	h = fganimation;
	h.TimeseriesSource = ts;
	h.TimeScaling = 50;
	
	%% FLIGHTGEAR'--heading-offset-deg=240 --pitch-offset-deg=20'
	
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

