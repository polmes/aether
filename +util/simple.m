function simple(t, S, sc, pl)
    % Variables
	rad = S(:,1); lat = S(:,2); lon = S(:,3);
	alt = rad - pl.R;
	x = rad .* cos(lat) .* cos(lon);
	y = rad .* cos(lat) .* sin(lon);
	z = rad .* sin(lat);
	Uinf = sqrt(sum(S(:,8:10).^2, 2));
    q0 = S(:,4); q1 = S(:,5); q2 = S(:,6); q3 = S(:,7);
	ph = atan2(2 * (q0.*q1 + q2.*q3), 1 - 2 * (q1.^2 + q2.^2));
	th = asin(2 * (q0.*q2 - q3.*q1));
	ps = atan2(2 * (q0.*q3 + q1.*q2), 1 - 2 * (q2.^2 + q3.^2));
    alpha = atan2(S(:,10), S(:,8));
    [MFP, a] = pl.atm.rarefaction(alt);
    Kn = MFP / sc.L;
    M = Uinf ./ a;
    CL = sc.Cx('CL', alpha, Kn, M);
	CD = sc.Cx('CD', alpha, Kn, M);
	Cm = sc.Cx('Cm', alpha, Kn, M);

    % X-Y-Z
	figure;
	hold('on');
	plot3(x/1e3, z/1e3, y/1e3);
    plot3(0, 0, 0, 'k*');
% 	axis('equal');
	xlabel('$X$ [km]');
	ylabel('$Y$ [km]');
	zlabel('$Z$ [km]');

    % Trajectory vs. time
	figure;
	hold('on');
    grid('on');
    xlabel('Time [s]');
	yyaxis('left');
	plot(t, alt / 1e3); % [km]
    ylabel('Altitude [km]');
	yyaxis('right');
	plot(t, rad2deg(lat));
	plot(t, rad2deg(lon));
    ylabel('Range [$^\circ$]');

    % Velocity + Mach vs. time
    figure;
    grid('on');
    xlabel('Time [s]');
    yyaxis('left');
    plot(t, Uinf);
    ylabel('Velocity [m/s]');
    yyaxis('right');
    plot(t, M);
    ylabel('Mach');

    % Rarefaction + AoA vs. time
    figure;
    grid('on');
    xlabel('Time [s]');
    yyaxis('left');
    plot(t, rad2deg(alpha));
    ylabel('Angle of Attack [$^\circ$]');
    yyaxis('right');
    plot(t, Kn);
    ylabel('Knudsen');
    set(gca, 'YScale', 'log');

    % Attitude vs. time
    figure;
    hold('on');
    plot(t, rad2deg(ph));
    plot(t, rad2deg(th));
    plot(t, rad2deg(ps));
    grid('on');
    xlabel('Time [s]');
    ylabel('Attitide Angle [$^\circ$]');
    legend('$\phi$', '$\theta$', '$\psi$');

    % Aerodynamics vs. time
    figure;
    hold('on');
    plot(t, CL);
    plot(t, CD);
    plot(t, Cm);
    grid('on');
    xlabel('Time [s]');
    ylabel('Coefficient');
    legend('$C_L$', '$C_D$', '$C_m$');

    % Set options
    set(findobj('Type', 'Legend'), 'Interpreter', 'latex');
    set(findobj('Type', 'axes'), 'FontSize', 12, 'TickLabelInterpreter', 'latex');
    set(findobj('Type', 'ColorBar'), 'TickLabelInterpreter', 'latex');
    set(findobj('Type', 'figure'), 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 10]);
    set(findall(findobj('Type', 'axes'), 'Type', 'Text'), 'Interpreter', 'latex');
    set(findall(findobj('Type', 'axes'), 'Type', 'Line'), 'LineWidth', 1);
end