classdef AtmosphereSample < Atmosphere
	properties
		interpol = 'linear';

		% Database for interpolation
		alt; % range of altitudes
		rho; % range of densities
		mfp; % range of mean free paths

		% Statistics
		rhomean;
		rhovari;
		mfpmean;
		mfpvari;
	end

	methods
		function self = AtmosphereSample(atm)
			self.alt = atm.alt;
			
			self.rhomean = atm.rhomean;
			self.rhovari = atm.rhovari;
			self.mfpmean = atm.mfpmean;
			self.mfpvari = atm.mfpvari;
			
			Nalt = numel(self.alt);
			self.rho = zeros(Nalt, 1);
			self.mfp = zeros(Nalt, 1);
		end

		function update(self, Yrho, Ymfp)
			self.rho = self.rhomean + sqrt(self.rhovari) * Yrho;
			self.mfp = self.mfpmean + sqrt(self.mfpvari) * Ymfp;
		end

		function rho = model(self, h)
			rho = interp1(self.alt, self.rho, h, self.interpol);
		end

		function mfp = rarefaction(self, h)
			mfp = interp1(self.alt, self.mfp, h, self.interpol);
		end
	end
end
