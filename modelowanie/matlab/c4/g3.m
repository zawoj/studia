% Simulink implementation of online identification
% This script creates and configures Simulink models for online identification

clear all;
close all;
clc;

% Create a new Simulink model
modelName = 'OnlineIdentification';
if ~bdIsLoaded(modelName)
    new_system(modelName);
end
open_system(modelName);

% Set simulation parameters
set_param(modelName, 'Solver', 'ode45', 'StopTime', '20');

% Add a white noise source
add_block('simulink/Sources/Band-Limited White Noise', [modelName '/Noise']);
set_param([modelName '/Noise'], 'Position', [50, 100, 80, 130]);
set_param([modelName '/Noise'], 'SampleTime', '0.1');

% Add a transfer function block for G1(z) = (0.1z + 0.2)/(z^2 + 0.3z + 0.4)
add_block('simulink/Discrete/Discrete Transfer Fcn', [modelName '/G1']);
set_param([modelName '/G1'], 'Position', [150, 100, 250, 130]);
set_param([modelName '/G1'], 'Numerator', '[0.1 0.2]');
set_param([modelName '/G1'], 'Denominator', '[1 0.3 0.4]');
set_param([modelName '/G1'], 'SampleTime', '0.1');

% Add output noise
add_block('simulink/Sources/Band-Limited White Noise', [modelName '/OutputNoise']);
set_param([modelName '/OutputNoise'], 'Position', [150, 180, 180, 210]);
set_param([modelName '/OutputNoise'], 'SampleTime', '0.1');
set_param([modelName '/OutputNoise'], 'Variance', '0.01');

% Add a summing block for adding output noise
add_block('simulink/Math Operations/Sum', [modelName '/Sum']);
set_param([modelName '/Sum'], 'Position', [300, 105, 320, 125]);
set_param([modelName '/Sum'], 'Inputs', '++');

% Add RLS estimator block
add_block('slcontrol/Block-Libraries/Estimation Tools/Recursive Least Squares Estimator', [modelName '/RLS']);
set_param([modelName '/RLS'], 'Position', [400, 100, 500, 130]);
set_param([modelName '/RLS'], 'ForgettingFactor', '0.98');
set_param([modelName '/RLS'], 'InitialParameterEstimate', '[0 0 0 0]''');
set_param([modelName '/RLS'], 'InitialCovarianceMatrix', '100*eye(4)');
set_param([modelName '/RLS'], 'ParameterSize', '4');

% Add blocks to create regressor vector
add_block('simulink/Signal Routing/Demux', [modelName '/Demux']);
set_param([modelName '/Demux'], 'Position', [550, 100, 570, 130]);
set_param([modelName '/Demux'], 'Outputs', '4');

% Add scopes for visualization
add_block('simulink/Sinks/Scope', [modelName '/ParametersScope']);
set_param([modelName '/ParametersScope'], 'Position', [650, 100, 680, 130]);

% Add a clock for time
add_block('simulink/Sources/Clock', [modelName '/Clock']);
set_param([modelName '/Clock'], 'Position', [400, 200, 420, 220]);

% Add To Workspace blocks to save simulation results
add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspaceTheta']);
set_param([modelName '/ToWorkspaceTheta'], 'Position', [550, 200, 610, 230]);
set_param([modelName '/ToWorkspaceTheta'], 'VariableName', 'theta');
set_param([modelName '/ToWorkspaceTheta'], 'SampleTime', '0.1');

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspaceTime']);
set_param([modelName '/ToWorkspaceTime'], 'Position', [450, 200, 510, 230]);
set_param([modelName '/ToWorkspaceTime'], 'VariableName', 't');
set_param([modelName '/ToWorkspaceTime'], 'SampleTime', '0.1');

% Connect the blocks
add_line(modelName, 'Noise/1', 'G1/1', 'autorouting', 'on');
add_line(modelName, 'G1/1', 'Sum/1', 'autorouting', 'on');
add_line(modelName, 'OutputNoise/1', 'Sum/2', 'autorouting', 'on');
add_line(modelName, 'Sum/1', 'RLS/2', 'autorouting', 'on');
add_line(modelName, 'Noise/1', 'RLS/1', 'autorouting', 'on');
add_line(modelName, 'RLS/1', 'Demux/1', 'autorouting', 'on');
add_line(modelName, 'Demux/1', 'ParametersScope/1', 'autorouting', 'on');
add_line(modelName, 'RLS/1', 'ToWorkspaceTheta/1', 'autorouting', 'on');
add_line(modelName, 'Clock/1', 'ToWorkspaceTime/1', 'autorouting', 'on');

% Save model
save_system(modelName);

% Instructions for creating time-varying parameter model
fprintf('\nTo create a model with time-varying parameters:\n');
fprintf('1. Create a new subsystem to replace the Transfer Function block\n');
fprintf('2. Inside the subsystem, use a Multiport Switch to select between different Transfer Function blocks\n');
fprintf('3. Use a Step or Clock block to control the switching time\n');
fprintf('4. Set the forgetting factor to a value between 0.95 and 0.98\n');
fprintf('5. Experiment with different noise levels and input signals\n\n');

% Create a second model for continuous system identification
modelName2 = 'OnlineIdentificationContinuous';
if ~bdIsLoaded(modelName2)
    new_system(modelName2);
end
open_system(modelName2);

% Set simulation parameters
set_param(modelName2, 'Solver', 'ode45', 'StopTime', '20');

% Add a white noise source
add_block('simulink/Sources/Band-Limited White Noise', [modelName2 '/Noise']);
set_param([modelName2 '/Noise'], 'Position', [50, 100, 80, 130]);
set_param([modelName2 '/Noise'], 'SampleTime', '0.01');

% Add a transfer function block for G2(s) = (s + 1)/(s^2 + 2s + 3)
add_block('simulink/Continuous/Transfer Fcn', [modelName2 '/G2']);
set_param([modelName2 '/G2'], 'Position', [150, 100, 250, 130]);
set_param([modelName2 '/G2'], 'Numerator', '[1 1]');
set_param([modelName2 '/G2'], 'Denominator', '[1 2 3]');

% Add a zero-order hold for discretization
add_block('simulink/Discrete/Zero-Order Hold', [modelName2 '/ZOH']);
set_param([modelName2 '/ZOH'], 'Position', [300, 100, 330, 130]);
set_param([modelName2 '/ZOH'], 'SampleTime', '0.01');

% Add output noise
add_block('simulink/Sources/Band-Limited White Noise', [modelName2 '/OutputNoise']);
set_param([modelName2 '/OutputNoise'], 'Position', [300, 180, 330, 210]);
set_param([modelName2 '/OutputNoise'], 'SampleTime', '0.01');
set_param([modelName2 '/OutputNoise'], 'Variance', '0.01');

% Add a summing block for adding output noise
add_block('simulink/Math Operations/Sum', [modelName2 '/Sum']);
set_param([modelName2 '/Sum'], 'Position', [400, 105, 420, 125]);
set_param([modelName2 '/Sum'], 'Inputs', '++');

% Add RLS estimator block
add_block('slcontrol/Block-Libraries/Estimation Tools/Recursive Least Squares Estimator', [modelName2 '/RLS']);
set_param([modelName2 '/RLS'], 'Position', [500, 100, 600, 130]);
set_param([modelName2 '/RLS'], 'ForgettingFactor', '0.98');
set_param([modelName2 '/RLS'], 'InitialParameterEstimate', '[0 0 0 0]''');
set_param([modelName2 '/RLS'], 'InitialCovarianceMatrix', '100*eye(4)');
set_param([modelName2 '/RLS'], 'ParameterSize', '4');

% Add blocks to create regressor vector
add_block('simulink/Signal Routing/Demux', [modelName2 '/Demux']);
set_param([modelName2 '/Demux'], 'Position', [650, 100, 670, 130]);
set_param([modelName2 '/Demux'], 'Outputs', '4');

% Add scopes for visualization
add_block('simulink/Sinks/Scope', [modelName2 '/ParametersScope']);
set_param([modelName2 '/ParametersScope'], 'Position', [750, 100, 780, 130]);

% Add a clock for time
add_block('simulink/Sources/Clock', [modelName2 '/Clock']);
set_param([modelName2 '/Clock'], 'Position', [500, 200, 520, 220]);

% Add To Workspace blocks to save simulation results
add_block('simulink/Sinks/To Workspace', [modelName2 '/ToWorkspaceTheta']);
set_param([modelName2 '/ToWorkspaceTheta'], 'Position', [650, 200, 710, 230]);
set_param([modelName2 '/ToWorkspaceTheta'], 'VariableName', 'theta');
set_param([modelName2 '/ToWorkspaceTheta'], 'SampleTime', '0.01');

add_block('simulink/Sinks/To Workspace', [modelName2 '/ToWorkspaceTime']);
set_param([modelName2 '/ToWorkspaceTime'], 'Position', [550, 200, 610, 230]);
set_param([modelName2 '/ToWorkspaceTime'], 'VariableName', 't');
set_param([modelName2 '/ToWorkspaceTime'], 'SampleTime', '0.01');

% Connect the blocks
add_line(modelName2, 'Noise/1', 'G2/1', 'autorouting', 'on');
add_line(modelName2, 'G2/1', 'ZOH/1', 'autorouting', 'on');
add_line(modelName2, 'ZOH/1', 'Sum/1', 'autorouting', 'on');
add_line(modelName2, 'OutputNoise/1', 'Sum/2', 'autorouting', 'on');
add_line(modelName2, 'Sum/1', 'RLS/2', 'autorouting', 'on');
add_line(modelName2, 'Noise/1', 'RLS/1', 'autorouting', 'on');
add_line(modelName2, 'RLS/1', 'Demux/1', 'autorouting', 'on');
add_line(modelName2, 'Demux/1', 'ParametersScope/1', 'autorouting', 'on');
add_line(modelName2, 'RLS/1', 'ToWorkspaceTheta/1', 'autorouting', 'on');
add_line(modelName2, 'Clock/1', 'ToWorkspaceTime/1', 'autorouting', 'on');

% Save model
save_system(modelName2);