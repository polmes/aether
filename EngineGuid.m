classdef EngineGuid < EngineAero
	properties (Access = protected)
		% New state scalars
		bank = false;
		hold = false;
		stage = 0;
		alpha0 = 0;
		MRP = zeros(3, 1);
		t0 = 0;
		t1 = 0;
		PRA = 0;
	end

	properties (Access = protected, Constant)
		fopts = optimoptions('fsolve', 'Display', 'off');
	end

	methods (Access = protected)
		function Mc = controls(self, ~, Ma, sc)
			% Rate
			Wref = zeros(3, 1);
			dWref = zeros(3, 1);
			deltaW = self.W - Wref;

			% Attitude - body w.r.t. reference
			deltaPRA = self.PRA; % min(self.PRA, self.PRA * (t - self.t1) / (self.PRA / sc.W));
			PRV = self.Urel / norm(self.Urel);
			q0 = cos(deltaPRA/2); q1 = PRV(1) * sin(deltaPRA/2); q2 = PRV(2) * sin(deltaPRA/2); q3 = PRV(3) * sin(deltaPRA/2);
			Qbr = [q0; -q1; -q2; -q3];
			self.MRP = Qbr(2:4) / (1 + Qbr(1)); % Quaternions -> Modified Rodrigues Parameters

			% Lyapunov-derived control law
			Mext = Ma;
			Mc = sc.I * (dWref - cross(self.W, Wref)) + cross(self.W, sc.I * self.W) - diag(sc.hold) * self.MRP - diag(sc.damp) * deltaW - Mext;
		end

		function [val, ter, dir] = event(self, t, sc, pl)
			% Call superclass method
			[val, ter, dir] = event@Engine(self, t, sc, pl);

			if self.stage == 0 && t >= sc.tref(1)
				self.alpha0 = self.alpha;
				self.bank = true;
				self.PRA = fsolve(@(x) self.estimator(x), pi, self.fopts);
				self.stage = 1;
			elseif self.stage == 1 && t < sc.tref(2)
				self.t1 = t;
				self.PRA = fsolve(@(x) self.estimator(x), self.PRA, self.fopts);
			elseif self.stage == 1 && t >= sc.tref(2)
				self.alpha0 = self.alpha;
				self.PRA = fsolve(@(x) self.estimator(x), -pi, self.fopts);
				self.stage = 2;
			elseif self.stage == 2 && t < sc.tref(3)
				self.t1 = t;
				self.PRA = fsolve(@(x) self.estimator(x), self.PRA, self.fopts);
			elseif self.stage == 2 && t >= sc.tref(3)
				self.bank = false;
				self.stage = 3;
				self.PRA = fsolve(@(x) self.estimator(x), 0, self.fopts);
			elseif self.stage == 3
				self.t1 = t;
				self.PRA = fsolve(@(x) self.estimator(x), self.PRA, self.fopts);
			end

			% Append new event outputs
			val = [val; self.bank];
			ter = [ter; false];
			dir = [dir; 0];
		end

		function f = estimator(self, PRA)
			PRV = self.Urel / norm(self.Urel);
			q0 = cos(PRA/2); q1 = PRV(1) * sin(PRA/2); q2 = PRV(2) * sin(PRA/2); q3 = PRV(3) * sin(PRA/2);
			Qref = [q0, -q1, -q2, -q3;
			        q1,  q0,  q3, -q2;
			        q2, -q3,  q0,  q1;
			        q3,  q2, -q1,  q0];
			Qri = Qref * self.Q; % quaternion addition

			q0 = Qri(1); q1 = Qri(2); q2 = Qri(3); q3 = Qri(4);
			Lir = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2+q0*q3)    , 2*(q1*q3-q0*q2)     ;
			       2*(q1*q2-q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q0*q1+q2*q3)     ;
				   2*(q0*q2+q1*q3)    , 2*(q2*q3-q0*q1)    , q0^2-q1^2-q2^2+q3^2];
			delta = atan2(Lir(2,3), Lir(3,3));

			% Quaternion Rotation (B -> I)
			q0 = self.Q(1); q1 = self.Q(2); q2 = self.Q(3); q3 = self.Q(4);
			Lbi = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2-q0*q3)    , 2*(q0*q2+q1*q3)     ;
			       2*(q1*q2+q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q2*q3-q0*q1)     ;
			       2*(q1*q3-q0*q2)    , 2*(q0*q1+q2*q3)    , q0^2-q1^2-q2^2+q3^2];

			Uref = Lir * Lbi * self.Urel;

			% Nominal frame of reference
			Lrn = [1,  0         , 0          ;
			       0,  cos(delta), sin(delta) ;
			       0, -sin(delta), cos(delta)];
			U = Lrn * Uref;

			% Angle of Attack
			Uinf = norm(self.Urel);
			alpha = atan2(U(3), U(1));
			beta = asin(U(2) / Uinf);

			f = beta + (sign(alpha) == sign(self.alpha0));
		end
	end
end
