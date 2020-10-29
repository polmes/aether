classdef EngineGuidRate < EngineAero
	properties (Access = protected)
		% New state scalars
		PRA;
		bank;
		count;
		target;

		% New state vectors
		Q0;
		Qir;
		MRP;
		PRV;
	end

	properties (Access = protected, Constant)
		tolMRP = 0.01;
		offtime = 10; % after W*dt [seconds]
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
				% Start bank angle roll
				self.Q0 = self.Q;
				self.PRV = self.Urel / norm(self.Urel);
				self.target = (mod(self.count, 2) * 2 - 1) * pi;

				% For next checks
				self.MRP = ones(3, 1);
				self.Qir = zeros(4, 1);
				self.bank = true;
			elseif self.bank && self.PRA == self.target && (max(abs(self.MRP)) < self.tolMRP || t - sc.tref(self.count) - self.offtime > pi/sc.maxW)
				% Reached final attitude, stop enforcing MRP
				self.bank = false;
				self.count = self.count + 1;
			elseif self.bank && (t - sc.tref(self.count)) > 0
				% Rate-limit bank angle rotation
				self.PRA = sign(self.target) * min(abs(self.target), sc.maxW * (t - sc.tref(self.count)));
				q0 = cos(self.PRA/2); q1 = self.PRV(1) * sin(self.PRA/2); q2 = self.PRV(2) * sin(self.PRA/2); q3 = self.PRV(3) * sin(self.PRA/2);
				Qref = [q0, -q1, -q2, -q3;
						q1,  q0,  q3, -q2;
						q2, -q3,  q0,  q1;
						q3,  q2, -q1,  q0];
				Qri = Qref * self.Q0; % quaternion addition
				self.Qir = [Qri(1); -Qri(2:4)];
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
			self.PRA = 0;
			self.bank = false;
			self.count = 1;
			self.target = 0;

			% New state vectors
			self.Q0 = zeros(4, 1);
			self.Qir = zeros(4, 1);
			self.MRP = zeros(3, 1);
			self.PRV = zeros(3, 1);
		end
	end
end
