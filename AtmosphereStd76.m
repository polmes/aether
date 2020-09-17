classdef AtmosphereStd76 < Atmosphere
	% AtmosphereStd76
	%
	% Subclass from Atmosphere that implements the US Standard 76
	% atmospheric model from Schlatter (2009), based on a
	% thermospheric exotemperature of 1000 K

	properties (Access = protected, Constant)
		%       z [km], rho [kg/m^3], T [K]  , Mw [kg/kmol], lambda[m], P [Pa]
		data = [0     , 1.23E+00    , 288.15 , 28.96       , 6.63E-08 , 101341.32;
		        20    , 8.89E-02    , 216.65 , 28.96       , 9.14E-07 , 5530.20  ;
		        40    , 4.85E-03    , 250.30 , 28.96       , 2.03E-05 , 3.48E+02 ;
		        51    , 9.07E-04    , 270.65 , 28.96       , 3.67E-04 , 7.05E+01 ;
		        70.5  , 7.20E-04    , 216.846, 28.96       , 9.81E-04 , 4.48E+01 ;
		        92    , 2.39E-06    , 186.96 , 28.55       , 1.04E-01 , 1.30E-01 ;
		        100   , 5.60E-07    , 195.08 , 28.40       , 1.42E-01 , 3.20E-02 ;
		        120   , 2.22E-08    , 360    , 26.98       , 1.33E+01 , 2.47E-03 ;
		        150   , 2.08E-09    , 634.39 , 24.85       , 3.30E+01 , 4.41E-04 ;
		        200   , 2.54E-10    , 854.56 , 21.3        , 2.40E+02 , 8.48E-05 ;
		        300   , 1.92E-11    , 976.01 , 17.73       , 2.60E+03 , 8.77E-06 ;
		        400   , 9.84E-12    , 987.625, 15.98       , 1.60E+04 , 5.06E-06 ;
		        500   , 5.22E-13    , 999.24 , 13.745      , 1.48E+05 , 3.15E-07 ;
		        600   , 2.76E-13    , 999.605, 11.51       , 2.80E+05 , 1.99E-07 ;
		        700   , 3.07E-14    , 999.97 , 8.525       , 8.40E+05 , 2.99E-08 ;
		        900   , 1.26E-14    , 999.99 , 4.74        , 2.25E+06 , 2.21E-08 ;
		        800   , 2.17E-14    , 999.98 , 5.54        , 1.40E+06 , 3.25E-08 ;
		        1000  , 3.56E-15    , 1000   , 3.94        , 3.10E+06 , 7.51E-09];

		% Default interpolation technique to
		% Piecewise Cubic Hermite Interpolating Polynomial
		interpol = 'pchip';

		% Heat capacity ratio
		gamma = 1.4;
	end

	methods
		function [rho, P, T] = model(self, h)
			% Returns most basic data from the atmospheric model via
			% simple 1D interpolation
			%
			% Parameters:
			%   h   := Altitude [m], relative to the Earth
			%
			% Return values:
			%   T   := Temperature [K]
			%   P   := Pressure [Pa]
			%   rho := Density [kg/m^3]

			h = h / 1e3; % [m] -> [km] for interpolation

			% Interpolate
			rho = interp1(self.data(:, 1), self.data(:, 2), h, self.interpol);
			P = interp1(self.data(:, 1), self.data(:, 6), h, self.interpol);
			T = interp1(self.data(:, 1), self.data(:, 3), h, self.interpol);
		end

		function [Mw, lambda] = fluid(self, h)
			% Returns data related to the fluid in the atmosphere
			%
			% Parameters:
			%   h       := Altitude [m], relative to the Earth
			%
			% Return values:
			%   Mw      := Molecular weight [kg/mol]
			%   lambda  := Mean free path [m]

			h = h / 1e3; % [m] -> [km] for interpolation

			Mw = interp1(self.data(:, 1), self.data(:, 4) / 1e3, h, self.interpol);
			lambda = interp1(self.data(:, 1), self.data(:, 5) / 1e3, h, self.interpol);
		end

		function [rho, MFP, a] = trajectory(self, ~, alt, ~, ~)
			[rho, ~, T] = self.model(alt);
			[Mw, MFP] = self.fluid(alt);
			a = sqrt(self.gamma .* Ru ./ Mw .* T);
		end
	end
end
