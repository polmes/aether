classdef AtmosphereNRLMSISE < Atmosphere
	properties
		lat; % [deg]
		lon; % [deg]
		doy; % day of year [d]
		tod; % time of day [s]
	end

	properties (Constant)
		% Molecular weights [kg/mol]
		% [He, O, N2, O2, Ar, H, N]
		Mi = [4.0026e-3, 15.9994e-3, 28.0134e-3, 31.9988e-3, 39.948e-3, 1.00797e-3, 14.0067e-3];
		sigma = 3.65e-10; % effective collision diameter [m]
		idx = [1:5, 7:8]; % corresponding to [He, O, N2, O2, Ar, H, N]
	end

	methods
		function self = AtmosphereNRLMSISE(lat, lon, date, hrs)
			% Initial latitude, longitude, Day of Year, Time of Day
			self.lat = rad2deg(lat);
			self.lon = rad2deg(lon);
			self.doy = day(datetime(date), 'DayOfYear');
			self.tod = hrs * 3600;
		end

		function [rho, P, T, M] = model(self, h, lat, lon, doy, tod)
			% Assume constant year = 2020, as well as solar radiation parameters
			if nargin == 2
				[Ts, rhos] = atmosnrlmsise00(h, self.lat, self.lon, 2020, self.doy, self.tod, 150, 150, 4);
			elseif nargin == 6
				[Ts, rhos] = atmosnrlmsise00(h, lat, lon, 2020, doy, tod, 150, 150, 4);
			else
				ME = MException('AtmosphereNRLMSISE:model:input', 'Unexpected number of inputs: %d', nargin);
				throw(ME);
			end

			% Vectors
			rho = rhos(:,6); % mean density
			T = Ts(:,2); % atmospheric temperature

			M = sum(rhos(:,self.idx) .* self.Mi, 2) ./ sum(rhos(:,self.idx), 2); % mean molecular weight
			P = rho .* self.Ru ./ M .* T;
		end

		function MFP = rarefaction(self, h, lat, lon, doy, tod)
			if nargin == 2
				[~, P, T, M] = self.model(h);
			elseif nargin == 6
				[~, P, T, M] = self.model(h, lat, lon, doy, tod);
			else
				ME = MException('AtmosphereNRLMSISE:rarefaction:input', 'Unexpected number of inputs: %d', nargin);
				throw(ME);
			end

			V = sqrt(8 * self.Ru * T ./ (pi * M));
			nu = 4 * self.sigma^2 * self.NA * P .* sqrt(pi ./ (M * self.Ru .* T));
			MFP = V ./ nu;
		end
	end
end
