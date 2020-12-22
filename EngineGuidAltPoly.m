classdef EngineGuidAltPoly < EngineGuidRate
	properties (Access = protected)
		% New state scalars
		t0;
		t1;
		t2;
		alt0;
		alt1;
		alt2;
		tref;
	end

	methods (Access = protected)
		function [val, ter, sgn] = event(self, t, sc, pl)
			% Call superclass method
			[val, ter, sgn] = event@EngineAero(self, t, sc, pl);

			if self.count == 1 && ~self.bank && self.alt - self.alt0 > 0
				% 2nd-order polynomial fit to better estimate time of min altitude
				[p, ~, mu] = polyfit([self.t2, self.t1, self.t0, t], [self.alt2, self.alt1, self.alt0, self.alt], 2);
				xx = linspace(self.t2, t); % 100 points
				yy = polyval(p, xx, [], mu);
				[~, mi] = min(yy);
				self.initroll();
				self.tref = xx(mi);
			elseif self.count == 2 && (t - self.tref) >= sc.tref(1)
				self.initroll();
				self.tref = t;
			elseif self.bank && self.PRA == self.target && (t - self.tref - self.offtime > pi/sc.maxW)
				self.stoproll();
			elseif self.bank && (t - self.tref) > 0
				self.rateroll(sc.maxW * (t - self.tref));
			end

			% Update properties
			self.t2 = self.t1;
			self.t1 = self.t0;
			self.t0 = t;
			self.alt2 = self.alt1;
			self.alt1 = self.alt0;
			self.alt0 = self.alt;

			% Append new event outputs
			val = [val; t - self.tref];
			ter = [ter; false];
			sgn = [sgn; +1];
		end

		function initreset(self)
			% Call superclass method
			initreset@EngineGuidRate(self);

			% New state scalars
			self.t0 = 0;
			self.t1 = 0;
			self.t2 = 0;
			self.tref = 1e9;
			self.alt0 = 1e9;
			self.alt1 = 1e9;
			self.alt2 = 1e9;
		end
	end
end
