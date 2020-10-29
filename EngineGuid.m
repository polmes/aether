classdef EngineGuid < EngineAero
	properties (Access = protected)
		% New state scalars
		bank;
		count;

		% New state vectors
		Qir;
		MRP;
	end

	properties (Access = protected, Constant)
		tolMRP = 0.01;
		offtime = 10; % seconds
	end

	methods (Access = protected)
		function Mc = controls(self, ~, ~, sc)
			% Rate
			Wref = zeros(3, 1);
			dWref = zeros(3, 1);
			deltaW = self.W - Wref;

			% Attitude - body w.r.t. reference
			q0 = self.Q(1); q1 = self.Q(2); q2 = self.Q(3); q3 = self.Q(4);
			Qref = [q0, -q1, -q2, -q3 ;
					q1,  q0,  q3, -q2 ;
					q2, -q3,  q0,  q1 ;
					q3,  q2, -q1,  q0];
			Qbr = self.bank * Qref * self.Qir;
			self.MRP = Qbr(2:4) / (1 + Qbr(1)); % Quaternions -> Modified Rodrigues Parameters

			% Lyapunov-derived control law
			Mc = sc.I * (dWref - cross(self.W, Wref)) + cross(self.W, sc.I * self.W) - diag(sc.hold) * self.MRP - diag(sc.damp) * deltaW;
		end

		function [val, ter, sgn] = event(self, t, sc, pl)
			% Call superclass method
			[val, ter, sgn] = event@EngineAero(self, t, sc, pl);

			if ~self.bank && t >= sc.tref(self.count)
				% Reference attitude
				PRA = (mod(self.count, 2) * 2 - 1) * pi;
				PRV = self.Urel / norm(self.Urel);
				q0 = cos(PRA/2); q1 = PRV(1) * sin(PRA/2); q2 = PRV(2) * sin(PRA/2); q3 = PRV(3) * sin(PRA/2);
				Qref = [q0, -q1, -q2, -q3;
						q1,  q0,  q3, -q2;
						q2, -q3,  q0,  q1;
						q3,  q2, -q1,  q0];
				Qri = Qref * self.Q; % quaternion addition
				self.Qir = [Qri(1); -Qri(2:4)];

				% Update counters
				self.MRP = ones(3, 1); % to fool the conditional check that follows
				self.bank = true;
			elseif self.bank && (max(abs(self.MRP)) < self.tolMRP || t > sc.tref(self.count) + self.offtime)
				self.bank = false;
				self.count = self.count + 1;
			end

			% Append new event outputs
			val = [val; t - sc.tref(self.count)];
			ter = [ter; false];
			sgn = [sgn; +1];
		end

		function initreset(self)
			% Call superclass method
			initreset@EngineAero(self);

			% New state scalars
			self.bank = false;
			self.count = 1;

			% New state vectors
			self.Qir = zeros(4, 1);
			self.MRP = zeros(3, 1);
		end
	end
end
