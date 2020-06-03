%% PRE

% Load inputs
eval(['analysis.' mfilename '_inputs']);

% Load global constants
constants;

% Load data
files = dir([datadir name '*.mat']);
NF = numel(files);
Qc = cell(NF, 1);
for i = 1:NF
	data = load([datadir files(i).name]);
	Qc{i} = data.Q;
end
Q = cell2mat(Qc);
clear('Qc');

% QoI = [st, dur, pos, Uend, maxU, maxG, maxQ, q]
good = find(Q(:,1) == 1);
NS = size(Q, 1);
NG = numel(good);
n = floor(logspace(1, log10(NG), NT));

% Any errors?
disp(['Good trajectories: ' num2str(NG/NS * 100) '%']);

% Statistics
Qgood = Q(good, [3 4]);
Qmean = zeros(NT, 2);
Qvari = zeros(NT, 2);
for i = 1:numel(n)
	Qmean(i,:) = mean(Qgood(1:n(i),:));
	Qvari(i,:) = mean((Qgood(1:n(i),:) - Qmean(i,:)).^2);
end

%% POST

% Scatter plot
figure;
scatter(Qgood(:,1), Qgood(:,2), 10, 'filled');
grid('on');
xlabel('Range [$^\circ$]');
ylabel('Deploy Velocity [m/s]');

% Range convergence
figure;
hold('on');
grid('on');
xlabel('Number of Samples');
yyaxis('left');
plot(n, Qmean(:,1), '^-', 'MarkerFaceColor', 'auto');
ylabel('Mean Range [$^\circ$]');
yyaxis('right');
plot(n, Qvari(:,1), 'v-', 'MarkerFaceColor', 'auto');
ylabel('Range Variance');
set(gca, 'XScale', 'log');
xlim([0, inf]);

% Velocity convergence
figure;
hold('on');
grid('on');
xlabel('Number of Samples');
yyaxis('left');
plot(n, Qmean(:,2), '^-', 'MarkerFaceColor', 'auto');
ylabel('Mean Velocity [m/s]');
yyaxis('right');
plot(n, Qvari(:,2), 'v-', 'MarkerFaceColor', 'auto');
ylabel('Velocity Variance');
set(gca, 'XScale', 'log');
xlim([0, inf]);

% Set options
set(findobj('Type', 'Legend'), 'Interpreter', 'latex');
set(findobj('Type', 'axes'), 'FontSize', 12, 'TickLabelInterpreter', 'latex');
set(findobj('Type', 'ColorBar'), 'TickLabelInterpreter', 'latex');
set(findobj('Type', 'figure'), 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 10]);
set(findall(findobj('Type', 'axes'), 'Type', 'Text'), 'Interpreter', 'latex');
set(findall(findobj('Type', 'axes'), 'Type', 'Line'), 'LineWidth', 1);
