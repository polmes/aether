classdef RandomGaussian < uq.Random
	properties
		mu;
		sigma;
	end

	properties (Constant)
		rule = 'gauss-hermite'; % for TASMANIAN
		INF = 2;
	end

	methods
		function self = RandomGaussian(mu, sigma)
			self.mu = mu;
			self.sigma = sigma;
		end

		function [x, w] = quadrature(self, m)
			% Computes Hermite polynomial abscissas and weights
			% for Gauss quadrature
			%
			% Input arguments:
			%	m : Number of Gauss points, taking into account that
			%	    m points integrate exactly a polynomial of order
			%	    p <= 2m - 1
			%
			% Output arguments:
			%	x : Coordinates/abscissas in which to evaluate the function
			%	    to be integrated, [x1, x2, ..., xm]
			%	w : Weights of each Gauss point during the sum,
			%	    [w1, w2, ..., wm]

			n = 1:(m - 1);
			beta = sqrt(n / 2);
			T = diag(beta, 1) + diag(beta, -1);
			[V, D] = eig(T);

			x = self.mu + self.sigma * diag(D); % abscissas
			w = (sqrt(pi) * V(1,:).^2).'; % weights
		end

		function x = adjust(self, x)
			x = self.mu + self.sigma * x;
		end

		function x = random(self, n, m)
			if nargin < 3
				m = 1;
			end

			x = self.adjust(randn(n, m));

			% Avoid singularities
			x(x < -self.INF) = -self.INF;
			x(x > +self.INF) = +self.INF;
		end

		function p = partition(self, n)
			p = norminv(linspace(self.mu, self.sigma, n + 1));

			% Avoid singularities
			p([1, n+1]) = [-self.INF, +self.INF];
		end
	end
end
