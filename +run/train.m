function [agent, stats] = train(varargin)
	% Handle inputs
	if ~nargin || isempty(varargin{1})
		[sc, pl, en, S0, RL] = util.pre('environment', varargin{2:end});
	else
		[sc, pl, en, S0, RL] = util.pre(varargin{:});
	end

	% Initialize environment = engine
	en.initial(S0, sc, pl, RL.targetreward);

	% Fix random seed
	% rng(0);

	% Reinforcement Learning Agents
	% See: https://www.mathworks.com/help/reinforcement-learning/ug/create-agents-for-reinforcement-learning.html
	switch RL.type
		case 'PG'
			% Create PG agent
			NN = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
			      fullyConnectedLayer(numel(en.getActionInfo.Elements), 'Name', 'fc')                        ;
			      softmaxLayer('Name', 'actionProb')                                                        ];
			opts = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', 1);
			% opts = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', inf);
			actor = rlStochasticActorRepresentation(NN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, opts);
			% PG = rlPGAgentOptions('UseBaseline', false, 'EntropyLossWeight', 0.5);
			agent = rlPGAgent(actor);
		case {'DQN', 'multiDQN'}
			% Create DQN agent (multi-output)
			DNN = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
			       fullyConnectedLayer(24, 'Name', 'CriticStateFC1')                                          ;
			       reluLayer('Name', 'CriticRelu1')                                                           ;
			       fullyConnectedLayer(24, 'Name', 'CriticStateFC2')                                          ;
			       reluLayer('Name', 'CriticCommonRelu')                                                      ;
			       fullyConnectedLayer(numel(en.getActionInfo.Elements), 'Name', 'output')                   ];
			opts = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', 1);
			% opts = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', 1);
			% opts = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', inf);
			if exist('rlQValueRepresentation', 'file') == 2
				critic = rlQValueRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, opts);
			else
				critic = rlRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, opts);
			end
			DQN = rlDQNAgentOptions('UseDoubleDQN', false, 'DiscountFactor', 0.99, ...
				'TargetSmoothFactor', 1, 'TargetUpdateFrequency', 1, ...
				'ExperienceBufferLength', 1e5, 'MiniBatchSize', 256, ...
				'SaveExperienceBufferWithAgent', true, 'ResetExperienceBufferBeforeTraining', false);
			% DQN.EpsilonGreedyExploration.Epsilon = 0.5;
			agent = rlDQNAgent(critic, DQN);
		case {'singleDQN'}
			% Alternative DQN agent (single-output)
			states = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
			          fullyConnectedLayer(24, 'Name', 'CriticStateFC1')                                          ;
			          reluLayer('Name', 'CriticRelu1')                                                           ;
			          fullyConnectedLayer(24, 'Name', 'CriticStateFC2')                                         ];
			action = [imageInputLayer(en.getActionInfo.Dimension, 'Normalization', 'none', 'Name', 'action') ;
			          fullyConnectedLayer(24, 'Name', 'CriticActionFC1')                                    ];
			common = [additionLayer(2, 'Name', 'add')          ;
			          reluLayer('Name', 'CriticCommonRelu')    ;
			          fullyConnectedLayer(1, 'Name', 'output')];
			DNN = layerGraph(states);
			DNN = addLayers(DNN, action);
			DNN = addLayers(DNN, common);
			DNN = connectLayers(DNN, 'CriticStateFC2', 'add/in1');
			DNN = connectLayers(DNN, 'CriticActionFC1', 'add/in2');
			opts = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', inf);
			if exist('rlQValueRepresentation', 'file') == 2
				critic = rlQValueRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, 'Action', {'action'}, opts);
			else
				critic = rlRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, 'Action', {'action'}, opts);
			end
			DQN = rlDQNAgentOptions('UseDoubleDQN', true, 'DiscountFactor', 0.99, ...
				'TargetSmoothFactor', 1, 'TargetUpdateFrequency', 1, ...
				'ExperienceBufferLength', 1e5, 'MiniBatchSize', 256);
			agent = rlDQNAgent(critic, DQN);
		case 'PPO'
			% Create PPO agent
			weights.criticFC1 = sqrt(2/prod(en.getObservationInfo.Dimension))*(rand(200,prod(en.getObservationInfo.Dimension))-0.5);
			weights.criticFC2 = sqrt(2/200)*(rand(100,200)-0.5);
			weights.criticOut = sqrt(2/100)*(rand(1,100)-0.5);
			bias.criticFC1 = 1e-3*ones(200,1);
			bias.criticFC2 = 1e-3*ones(100,1);
			bias.criticOut = 1e-3;
			weights.actorFC1 = sqrt(2/prod(en.getObservationInfo.Dimension))*(rand(200,prod(en.getObservationInfo.Dimension))-0.5);
			weights.actorFC2 = sqrt(2/200)*(rand(100,200)-0.5);
			weights.actorOut = sqrt(2/100)*(rand(numel(en.getActionInfo.Elements),100)-0.5);
			bias.actorFC1 = 1e-3*ones(200,1);
			bias.actorFC2 = 1e-3*ones(100,1);
			bias.actorOut = 1e-3*ones(numel(en.getActionInfo.Elements),1);
			CNN = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'observation')     ;
			       fullyConnectedLayer(200, 'Name', 'CriticFC1', 'Weights', weights.criticFC1, 'Bias', bias.criticFC1)  ;
			       reluLayer('Name','CriticRelu1')                                                                      ;
			       fullyConnectedLayer(100, 'Name', 'CriticFC2', 'Weights', weights.criticFC2, 'Bias', bias.criticFC2)  ;
			       reluLayer('Name', 'CriticRelu2')                                                                     ;
			       fullyConnectedLayer(1, 'Name', 'CriticOutput', 'Weights', weights.criticOut, 'Bias', bias.criticOut)];
			cropts = rlRepresentationOptions('LearnRate', 1e-3);
			critic = rlValueRepresentation(CNN, en.getObservationInfo, 'Observation', {'observation'}, cropts);
			ANN = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'observation')                            ;
    		       fullyConnectedLayer(200, 'Name', 'ActorFC1', 'Weights', weights.actorFC1, 'Bias', bias.actorFC1)                            ;
    		       reluLayer('Name', 'ActorRelu1')                                                                                             ;
    		       fullyConnectedLayer(100, 'Name', 'ActorFC2', 'Weights', weights.actorFC2, 'Bias', bias.actorFC2)                            ;
    		       reluLayer('Name', 'ActorRelu2')                                                                                             ;
    		       fullyConnectedLayer(numel(en.getActionInfo.Elements), 'Name', 'Action', 'Weights', weights.actorOut, 'Bias', bias.actorOut) ;
    		       softmaxLayer('Name', 'actionProbability')                                                                                  ];
			acopts = rlRepresentationOptions('LearnRate', 1e-3);
			actor = rlStochasticActorRepresentation(ANN, en.getObservationInfo, en.getActionInfo, 'Observation', {'observation'}, acopts);
			PPO = rlPPOAgentOptions('ExperienceHorizon', 512, 'ClipFactor', 0.2, 'EntropyLossWeight', 0.02, 'MiniBatchSize', 64, ...
				'NumEpoch', 3, 'AdvantageEstimateMethod', 'gae', 'GAEFactor', 0.95, 'SampleTime', 0.25, 'DiscountFactor', 0.9995);
			agent = rlPPOAgent(actor, critic, PPO);
		otherwise
			util.exception('Unknown RL agent/policy type provided');
	end

	% Training options
	if RL.visualize
		plotting = 'training-progress';
	else
		plotting = 'none';
	end
	training = rlTrainingOptions('MaxEpisodes', RL.maxepisodes, 'MaxStepsPerEpisode', en.maxsteps, ...
		'StopTrainingCriteria', 'AverageReward', 'StopTrainingValue', RL.targetreward, 'ScoreAveragingWindowLength', RL.averageover, ...
		'UseParallel', true, 'Verbose', RL.verbose, 'Plots', plotting);
	if strcmp(RL.type, 'PG')
		training.ParallelizationOptions.DataToSendFromWorkers = 'gradients';
	end

	% Train agent
	stats = train(agent, en, training);

	% Save agent
	filename = util.constructname(mfilename, [varargin, RL.type, num2str(numel(stats.EpisodeSteps))]);
	util.store(filename, agent, en, stats);
end
