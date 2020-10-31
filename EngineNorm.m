classdef EngineNorm < Engine
	properties (Access = protected)
		% New state vector
		Sref;
	end

	methods
		function [t, S, ie, te, Se] = integrate(self, S, sc, pl)
			% Reset variables for next integration
			self.initreset();

			% Prepare S0 if necessary
			if numel(S) < self.NS
				% [alt, Umag, gamma, chi, lat, lon, ph, th, ps, p, q, r]
				S0 = self.prepare(S, pl);
			elseif numel(S) == self.NS
				% [x, y, z, q0, q1, q2, q3, u, v, w, p, q, r]
				S0 = S;
			else
				util.exception('Unexpected length of initial conditions array: %d', numel(S));
			end

			% Reference vector
			self.Sref = [pl.R; pl.R; pl.R; 1; 1; 1; 1; sqrt(pl.mu/pl.R); sqrt(pl.mu/pl.R); sqrt(pl.mu/pl.R); sc.maxW; sc.maxW; sc.maxW];
			% S0 = S0 ./ self.Sref; % normalize

			% Events function
			self.opts.Events = @(t, S) self.event(t, sc, pl);

			% Call integrator
			[t, S, te, Se, ie] = self.integrator(@(t, S) self.motion(t, S, sc, pl), [0, self.T], S0, self.opts);
			% S = S .* self.Sref.';

			if t(end) < self.T && ~isempty(ie) && self.showwarnings
				warning(self.eventmssgs{ie(end)});
			end
		end
	end

	methods (Access = protected)
		function dS = motion(self, t, S, sc, pl)
			S = S .* self.Sref;
			dS = motion@Engine(self, t, S, sc, pl);
			dS = dS ./ self.Sref;
		end

		function initreset(self)
			% Call superclass method
			initreset@Engine(self);

			% New state vector
			self.Sref = ones(self.NS(), 1);
		end
	end
end
