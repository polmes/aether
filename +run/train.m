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
			opts = rlRepresentationOptions('LearnRate', RL.learnrate, 'GradientThreshold', inf);
			if exist('rlStochasticActorRepresentation', 'file') == 2
				actor = rlStochasticActorRepresentation(NN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, opts);
			else
				actor = rlRepresentation(NN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, 'Action', {'actionProb'}, opts);
			end
			agent = rlPGAgent(actor);
		case {'multiDQN'}
			% Create DQN agent (multi-output)
			DNN = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
			       fullyConnectedLayer(RL.neurons, 'Name', 'CriticStateFC1')                                  ;
			       reluLayer('Name', 'CriticRelu1')                                                           ;
			       fullyConnectedLayer(RL.neurons, 'Name', 'CriticStateFC2')                                  ;
			       reluLayer('Name', 'CriticCommonRelu')                                                      ;
			       fullyConnectedLayer(numel(en.getActionInfo.Elements), 'Name', 'output')                   ];
			opts = rlRepresentationOptions('LearnRate', RL.learnrate, 'GradientThreshold', inf);
			critic = rlQValueRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, opts);
			DQN = rlDQNAgentOptions('UseDoubleDQN', false, 'DiscountFactor', 0.99, ...
				'TargetSmoothFactor', 0.1, 'TargetUpdateFrequency', 5, ...
				'ExperienceBufferLength', 1e5, 'MiniBatchSize', 256, ...
				'SaveExperienceBufferWithAgent', true, 'ResetExperienceBufferBeforeTraining', false);
			agent = rlDQNAgent(critic, DQN);
		case {'DQN', 'singleDQN'}
			% Create DQN agent (single-output)
			states = [imageInputLayer(en.getObservationInfo.Dimension, 'Normalization', 'none', 'Name', 'state') ;
			          fullyConnectedLayer(RL.neurons, 'Name', 'CriticStateFC1')                                  ;
			          reluLayer('Name', 'CriticRelu1')                                                           ;
			          fullyConnectedLayer(RL.neurons, 'Name', 'CriticStateFC2')                                 ];
			action = [imageInputLayer(en.getActionInfo.Dimension, 'Normalization', 'none', 'Name', 'action') ;
			          fullyConnectedLayer(RL.neurons, 'Name', 'CriticActionFC1')                            ];
			common = [additionLayer(2, 'Name', 'add')          ;
			          reluLayer('Name', 'CriticCommonRelu')    ;
			          fullyConnectedLayer(1, 'Name', 'output')];
			DNN = layerGraph(states);
			DNN = addLayers(DNN, action);
			DNN = addLayers(DNN, common);
			DNN = connectLayers(DNN, 'CriticStateFC2', 'add/in1');
			DNN = connectLayers(DNN, 'CriticActionFC1', 'add/in2');
			opts = rlRepresentationOptions('LearnRate', RL.learnrate, 'GradientThreshold', inf);
			if exist('rlQValueRepresentation', 'file') == 2
				critic = rlQValueRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, 'Action', {'action'}, opts);
			else
				critic = rlRepresentation(DNN, en.getObservationInfo, en.getActionInfo, 'Observation', {'state'}, 'Action', {'action'}, opts);
			end
			DQN = rlDQNAgentOptions('UseDoubleDQN', false, 'DiscountFactor', 0.99, ...
				'TargetSmoothFactor', 1, 'TargetUpdateFrequency', 4, ...
				'ExperienceBufferLength', 1e5, 'MiniBatchSize', 256, ...
				'SaveExperienceBufferWithAgent', true, 'ResetExperienceBufferBeforeTraining', false);
			agent = rlDQNAgent(critic, DQN);
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
