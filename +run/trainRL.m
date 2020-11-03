% Initialize environment = engine
[sc, pl, en, S0] = util.pre('train_local');
en.initial(S0, sc, pl);

% Fix random seed
rng(0);

% % Create PG agent
% NN = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
%       fullyConnectedLayer(numel(en.getActionInfo.Dimension), 'Name', 'fc')                               ;
%       softmaxLayer('Name', 'actionProb')                                                                ];
% opts = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', 1);
% actor = rlStochasticActorRepresentation(NN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, opts);
% agent = rlPGAgent(actor);

% % Create DQN agent
% DNN = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
%        fullyConnectedLayer(24, 'Name', 'CriticStateFC1')                                          ;
%        reluLayer('Name', 'CriticRelu1')                                                           ;
%        fullyConnectedLayer(24, 'Name', 'CriticStateFC2')                                          ;
%        reluLayer('Name', 'CriticCommonRelu')                                                      ;
%        fullyConnectedLayer(numel(en.getActionInfo.Elements), 'Name', 'output')                   ];
% opts = rlRepresentationOptions('LearnRate', 0.001, 'GradientThreshold', 1);
% critic = rlQValueRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, opts);
% DQN = rlDQNAgentOptions('UseDoubleDQN', false, 'TargetSmoothFactor', 1, 'TargetUpdateFrequency', 4, ...
% 	'ExperienceBufferLength', 100000, 'DiscountFactor', 0.99, 'MiniBatchSize', 256);
% agent = rlDQNAgent(critic, DQN);

% Create DQN agent (multi-output)
DNN = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
       fullyConnectedLayer(24, 'Name', 'CriticStateFC1')                                          ;
       reluLayer('Name', 'CriticRelu1')                                                           ;
       fullyConnectedLayer(24, 'Name', 'CriticStateFC2')                                          ;
       reluLayer('Name', 'CriticCommonRelu')                                                      ;
       fullyConnectedLayer(numel(en.getActionInfo.Elements), 'Name', 'output')                   ];
opts = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', inf);
% opts = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', 1);
critic = rlQValueRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, opts);
DQN = rlDQNAgentOptions('UseDoubleDQN', false, 'DiscountFactor', 0.99, ...
	'TargetSmoothFactor', 1, 'TargetUpdateFrequency', 1, ...
	'ExperienceBufferLength', 1e5, 'MiniBatchSize', 256);
agent = rlDQNAgent(critic, DQN);

% % Alternative DQN agent (single-output)
% states = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
%           fullyConnectedLayer(24, 'Name', 'CriticStateFC1')                                          ;
%           reluLayer('Name', 'CriticRelu1')                                                           ;
%           fullyConnectedLayer(24, 'Name', 'CriticStateFC2')                                         ];
% action = [imageInputLayer(en.getActionInfo.Dimension, 'Normalization', 'none', 'Name', 'action') ;
%           fullyConnectedLayer(24, 'Name', 'CriticActionFC1')                                    ];
% common = [additionLayer(2, 'Name', 'add')          ;
%           reluLayer('Name', 'CriticCommonRelu')    ;
%           fullyConnectedLayer(1, 'Name', 'output')];
% DNN = layerGraph(states);
% DNN = addLayers(DNN, action);
% DNN = addLayers(DNN, common);
% DNN = connectLayers(DNN, 'CriticStateFC2', 'add/in1');
% DNN = connectLayers(DNN, 'CriticActionFC1', 'add/in2');
% opts = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', inf);
% critic = rlQValueRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, 'Action', {'action'}, opts);
% DQN = rlDQNAgentOptions('UseDoubleDQN', true, 'DiscountFactor', 0.99, ...
% 	'TargetSmoothFactor', 1, 'TargetUpdateFrequency', 1, ...
% 	'ExperienceBufferLength', 1e5, 'MiniBatchSize', 256);
% agent = rlDQNAgent(critic, DQN);

% Train agent
training = rlTrainingOptions('MaxEpisodes', 5000, 'MaxStepsPerEpisode', en.maxsteps, ...
	'StopTrainingCriteria', 'AverageReward', 'StopTrainingValue', 4000, 'ScoreAveragingWindowLength', 10, ...
	'UseParallel', true, 'Verbose', true, 'Plots', 'training-progress');
% training = rlTrainingOptions('MaxEpisodes', 5000, 'MaxStepsPerEpisode', en.maxsteps, ...
% 	'StopTrainingCriteria', 'AverageReward', 'StopTrainingValue', 4000, 'ScoreAveragingWindowLength', 10, ...
% 	'Verbose', true, 'Plots', 'training-progress');
train(agent, en, training);
