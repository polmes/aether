classdef AtmosphereMSIS < Atmosphere
	properties (Access = protected)
		dt; % date and time
	end

	properties (Access = protected, Constant)
		% Molecular weights [kg/mol]
		% [He, O, N2, O2, Ar, H, N]
		Mi = [4.0026e-3, 15.9994e-3, 28.0134e-3, 31.9988e-3, 39.948e-3, 1.00797e-3, 14.0067e-3];
		sigma = 3.65e-10; % effective collision diameter [m]
		idx = [1:5, 7:8]; % corresponding to [He, O, N2, O2, Ar, H, N]
		gamma = 1.4; % heat capacity ratio
	end

	methods
		function self = AtmosphereMSIS(dateandtime)
			% Initial date and time for Day of Year + Time of Day
			self.dt = datetime(dateandtime, 'InputFormat', 'yyyy/MM/dd HH:mm:ss');
		end

		function [rho, P, T, Mw] = model(self, alt, lat, lon, dateandtime)
			% Assume constant solar radiation parameters: atmosnrlmsise00(..., 150, 150, 4)
			% and call MATLAB's built-in MSIS model
			% Note: year is ignored, so is taken as 2020
			doy = day(dateandtime, 'DayOfYear');
			tod = seconds(timeofday(dateandtime));
			[Ts, rhos] = atmosnrlmsise00(alt, lat, lon, 2020, doy, tod, 150, 150, 4);

			% Quantities of Interest
			rho = rhos(:,6); % mean density
			T = Ts(:,2); % atmospheric temperature
			Mw = sum(rhos(:,self.idx) .* self.Mi, 2) ./ sum(rhos(:,self.idx), 2); % mean molecular weight
			P = rho .* self.Ru ./ Mw .* T;
		end

		function [rho, MFP, a] = trajectory(self, t, alt, lat, lon)
			dateandtime = self.dt + seconds(t);
			[rho, P, T, Mw] = self.model(alt, lat, lon, dateandtime);

			% Mean Free Path
			V = sqrt(8 * self.Ru * T ./ (pi * Mw));
			nu = 4 * self.sigma^2 * self.NA * P .* sqrt(pi ./ (Mw * self.Ru .* T));
			MFP = V ./ nu;

			% Speed of Sound
			a = sqrt(self.gamma * self.Ru ./ Mw .* T);
		end
	end
end
