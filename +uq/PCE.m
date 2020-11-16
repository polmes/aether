function [C, Psi, I] = PCE(Y, U, inputs, p)
	% Constants
	NS = size(Y, 1); % # of samples
	ND = size(Y, 2); % # of dimensions
	NQ = size(U, 2); % # of QoI's

	% 1 - Generate PC indices
	I = iPC(p, ND);
	P1 = size(I, 1); % # of total indices: P+1 = (p+d)! / (p!d!)

	% 2 - Generate measurement matrix
	Psi = ones(NS, P1);
	for k = 1:ND
		% Get matrix of basis functions evaluated at sample points for each polynomial order in the k-th dimension
		B = inputs(k).basis(p, Y(:,k)); % normalization to Y ~ N(0,1) is performed inside basis method
		Psi = Psi .* B(:, I(:,k)+1);
	end

	% 3 - Least-squares regression
	C = zeros(P1, NQ);
	for q = 1:NQ
		C(:,q) = Psi \ U(:,q); % solves (Psi.' * Psi) * C = Psi.' * U
	end

	% Total order indices
	function I = iPC(p, d)
		% Generate all possible combinations 0...p
		M = mat2cell(repmat(0:p, d, 1), ones(1, d));
		I = combvec(M{:});

		% Remove combinations that exceed maximum order
		I(:, sum(I) > p) = [];

		% Return
		I = I.';
	end
end
