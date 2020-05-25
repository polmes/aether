classdef AtmosphereProcess < AtmosphereSample
	properties
		% Correlation lengths
		lrho;
		lmfp;
		
		% Eigenvalues (v) and Eigenfunctions (f)
		vrho;
		frho;
		vmfp;
		fmfp;
	end
	
	methods
		function self = AtmosphereProcess(atm, d)
			self = self@AtmosphereSample(atm);
			self.lrho = atm.lrho;
			self.lmfp = atm.lmfp;
			
			Nalt = numel(self.alt);
			a = (self.alt(Nalt) - self.alt(1)) / 2;
			[self.vrho, self.frho] = uq.KLE(self.lrho, a, d, Nalt);
			[self.vmfp, self.fmfp] = uq.KLE(self.lrho, a, d, Nalt);
		end
		
		function update(self, Yrho, Ymfp)
			% Note: vxxx = lambda [1 x d]
			%       fxxx = phi [Nalt x d]
			%       Yxxx = Yi [1 x d]
			self.rho = self.rhomean + sqrt(self.rhovari) .* sum(sqrt(self.vrho) .* self.frho .* Yrho, 2);
			self.mfp = self.mfpmean + sqrt(self.mfpvari) .* sum(sqrt(self.vmfp) .* self.fmfp .* Ymfp, 2);
		end
	end
end
