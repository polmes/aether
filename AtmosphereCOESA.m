classdef AtmosphereCOESA < Atmosphere
	% AtmosphereCOESA
	%
	% Implements the mathematical representation of the 1976 US Standard Atmosphere
	% by COESA (Committee on Extension to the Standard Atmosphere)
	% Takes standard MATLAB atmoscoesa function and expands it with additional data
	%
	% References:
	% [1] "The 1976 Standard Atmosphere Above 86-km Altitude"
	%     https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19770003812.pdf

	properties (Access = protected, Constant)
		action = 'None'; % show warning/error if out of range?

		%       h [km], MFP [m]
		data = [0     , 6.63E-08 ;
		        20    , 9.14E-07 ;
		        40    , 2.03E-05 ;
		        51    , 3.67E-04 ;
		        70.5  , 9.81E-04 ;
		        92    , 1.04E-01 ;
		        100   , 1.42E-01 ;
		        120   , 1.33E+01 ;
		        150   , 3.30E+01 ;
		        200   , 2.40E+02 ;
		        300   , 2.60E+03 ;
		        400   , 1.60E+04 ;
		        500   , 1.48E+05 ;
		        600   , 2.80E+05 ;
		        700   , 8.40E+05 ;
		        900   , 2.25E+06 ;
		        800   , 1.40E+06 ;
		        1000  , 3.10E+06];

		% Default interpolation technique to
		% Piecewise Cubic Hermite Interpolating Polynomial
		interpol = 'pchip';
	end

	methods
		function self = AtmosphereCOESA(~)
		end

		function [rho, P, T] = model(self, h)
			% h = alt [m]
			[T, ~, P, rho] = atmoscoesa(h, self.action);
		end

		function [rho, MFP, a, W] = trajectory(self, ~, alt, ~, ~)
			[~, a, ~, rho] = atmoscoesa(alt, self.action);

			h = alt / 1e3; % [m] -> [km] for interpolation
			MFP = interp1(self.data(:,1), self.data(:,2), h, self.interpol);

			W = self.W;
		end
	end
end
