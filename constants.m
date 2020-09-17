% Apollo spacecraft
apollo.m = 5860; % mass [kg]
apollo.L = 3.9; % characteristic length / diameter [m]
apollo.R = 4.7; % nose diameter [m]
apollo.I = [8000, 7000, 7000]; % inertia [Ixx, Iyy, Izz] [kg.m^ 2]
apollo.deploy = 7.3e3; % parachute deployment altitude [m]

% Earth planet
earth.R = 6371e3; % average radius [m]
earth.M = 5.97237e24; % mass [kg]

% Atmosphere model initialization
atm.datetime = '1967/11/09 20:00:00'; % Apollo 4 mission date and UTC time ['yyyy/MM/dd HH:mm:ss']

% Max integration time
T = 2000; % [s]

% % Initial conditions (Apollo 4 full entry)
% alt = 122e3; % [m] ~400k ft, always start at edge of atmosphere
% Uinf = 11140; % [m/s] ~36545 ft/s
% gamma = deg2rad(-7.01);

% Initial conditions (Apollo 4 second entry)
alt = 78e3; % [m] ~255k ft
Uinf = 6.5e3; % [m/s] ~21k ft/s
gamma = 0; % horizontal velocity at peak altitude

% Data directory
datadir = 'mat/';
