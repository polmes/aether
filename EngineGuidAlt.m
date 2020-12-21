classdef EngineGuidAlt < EngineGuidRate
	properties (Access = protected)
		% New state scalars
		t0;
		prevalt;
	end

	methods (Access = protected)
		function [val, ter, sgn] = event(self, t, sc, pl)
			% Call superclass method
			[val, ter, sgn] = event@EngineAero(self, t, sc, pl);

			if ~self.bank && self.count == 1 && self.alt - self.prevalt > 0
				self.initroll();
				self.t0 = t;
			elseif self.count == 2 && (t - self.t0) >= sc.tref(1)
				self.initroll();
				self.t0 = t;
			elseif self.bank && self.PRA == self.target && (max(abs(self.MRP)) < self.tolMRP || t - self.t0 - self.offtime > pi/sc.maxW)
				self.stoproll();
			elseif self.bank && (t - self.t0) > 0
				self.rateroll(sc.maxW * (t - self.t0));
			end

			% Update properties
			self.prevalt = self.alt;

			% Append new event outputs
			val = [val; t - self.t0];
			ter = [ter; false];
			sgn = [sgn; +1];
		end

		function initreset(self)
			% Call superclass method
			initreset@EngineGuidRate(self);

			% New state scalars
			self.t0 = 1e9;
			self.prevalt = 1e9;
		end
	end
end
