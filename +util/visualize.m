function visualize(S, pl)
	x = S(:,1) .* cos(S(:,2)) .* cos(S(:,3));
	y = S(:,1) .* cos(S(:,2)) .* sin(S(:,3));
	z = S(:,1) .* sin(S(:,2));

	figure;
	hold('on');
	plot3(x, y, z);

	if nargin > 1
		[xe, ye, ze] = sphere();
		xe = pl.R * xe;
		ye = pl.R * ye;
		ze = pl.R * ze;

		surf(xe, ye, ze);
	else
		plot3(0, 0, 0, 'k*');
	end

	axis('equal');
	xlabel('X');
	ylabel('Y');
	zlabel('Z');
end
