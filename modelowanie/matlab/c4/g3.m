% Simulink implementation of online identification
% This script creates and configures Simulink models for online identification

clear all;
close all;
clc;

fprintf('Starting Simulink model creation for online system identification\n\n');

% Create a new Simulink model
modelName = 'OnlineIdentification';
if ~bdIsLoaded(modelName)
    new_system(modelName);
end
open_system(modelName);

fprintf('Creating Simulink model: %s\n', modelName);
fprintf('This model implements online identification of discrete system G1\n');
fprintf('G1(z) = (0.1z + 0.2)/(z^2 + 0.3z + 0.4)\n\n');

% Set simulation parameters
set_param(modelName, 'Solver', 'ode45', 'StopTime', '20');

% Add a white noise source
add_block('simulink/Sources/Band-Limited White Noise', [modelName '/Noise']);
set_param([modelName '/Noise'], 'Position', [50, 100, 80, 130]);
set_param([modelName '/Noise'], 'Ts', '0.1');

% Add a transfer function block for G1(z) = (0.1z + 0.2)/(z^2 + 0.3z + 0.4)
add_block('simulink/Discrete/Discrete Transfer Fcn', [modelName '/G1']);
set_param([modelName '/G1'], 'Position', [150, 100, 250, 130]);
set_param([modelName '/G1'], 'Numerator', '[0.1 0.2]');
set_param([modelName '/G1'], 'Denominator', '[1 0.3 0.4]');
set_param([modelName '/G1'], 'SampleTime', '0.1');

% Add output noise
add_block('simulink/Sources/Band-Limited White Noise', [modelName '/OutputNoise']);
set_param([modelName '/OutputNoise'], 'Position', [150, 180, 180, 210]);
set_param([modelName '/OutputNoise'], 'Ts', '0.1');
set_param([modelName '/OutputNoise'], 'Cov', '0.01');

% Add a summing block for adding output noise
add_block('simulink/Math Operations/Sum', [modelName '/Sum']);
set_param([modelName '/Sum'], 'Position', [300, 105, 320, 125]);
set_param([modelName '/Sum'], 'Inputs', '++');

% Create custom RLS implementation using MATLAB Function block instead of slcontrol
fprintf('Creating custom RLS implementation using MATLAB Function block\n');

% Create a subsystem for RLS implementation
add_block('simulink/Ports & Subsystems/Subsystem', [modelName '/RLS']);
set_param([modelName '/RLS'], 'Position', [400, 100, 500, 130]);

% Check if input/output ports already exist before adding
if isempty(find_system([modelName '/RLS'], 'BlockType', 'Inport', 'Name', 'In1'))
    add_block('simulink/Ports & Subsystems/Inport', [modelName '/RLS/In1']);
    set_param([modelName '/RLS/In1'], 'Position', [50, 100, 70, 120]);
end

if isempty(find_system([modelName '/RLS'], 'BlockType', 'Inport', 'Name', 'In2'))
    add_block('simulink/Ports & Subsystems/Inport', [modelName '/RLS/In2']);
    set_param([modelName '/RLS/In2'], 'Position', [50, 160, 70, 180]);
end

if isempty(find_system([modelName '/RLS'], 'BlockType', 'Outport', 'Name', 'Out1'))
    add_block('simulink/Ports & Subsystems/Outport', [modelName '/RLS/Out1']);
    set_param([modelName '/RLS/Out1'], 'Position', [450, 130, 470, 150]);
end

% Add MATLAB Function block for RLS algorithm
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/RLS/RLSFunction']);
set_param([modelName '/RLS/RLSFunction'], 'Position', [250, 120, 350, 160]);

% Set the MATLAB Function block content with RLS algorithm
rls_code = [
    'function theta = RLSFunction(u, y)\n'...
    '    persistent P theta_prev phi_prev;\n'...
    '    if isempty(P)\n'...
    '        % Initialize parameters\n'...
    '        P = 100*eye(4);\n'...
    '        theta_prev = zeros(4,1);\n'...
    '        phi_prev = zeros(4,1);\n'...
    '    end\n'...
    '    \n'...
    '    % Current regressor vector\n'...
    '    phi = [-y; -phi_prev(1); u; phi_prev(3)];\n'...
    '    \n'...
    '    % Forgetting factor\n'...
    '    lambda = 0.98;\n'...
    '    \n'...
    '    % RLS algorithm\n'...
    '    K = P*phi/(lambda + phi''*P*phi);\n'...
    '    epsilon = y - phi''*theta_prev;\n'...
    '    theta = theta_prev + K*epsilon;\n'...
    '    P = (P - K*phi''*P)/lambda;\n'...
    '    \n'...
    '    % Store for next iteration\n'...
    '    theta_prev = theta;\n'...
    '    phi_prev = phi;\n'...
    'end\n'
];

set_param([modelName '/RLS/RLSFunction'], 'MATLABFcn', rls_code);

% Connect blocks in RLS subsystem
add_line([modelName '/RLS'], 'In1/1', 'RLSFunction/1', 'autorouting', 'on');
add_line([modelName '/RLS'], 'In2/1', 'RLSFunction/2', 'autorouting', 'on');
add_line([modelName '/RLS'], 'RLSFunction/1', 'Out1/1', 'autorouting', 'on');

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

% Save model diagram as PNG
fprintf('Saving model diagram as PNG...\n');
print([modelName, '/'], '-dpng', 'G1_simulink_model.png');

% Display model configuration details
fprintf('Discrete System G1 Model Configuration:\n');
fprintf('Sample Time: 0.1 seconds\n');
fprintf('Simulation Time: 20 seconds\n');
fprintf('Noise Variance: 0.01\n');
fprintf('Forgetting Factor: 0.98\n');
fprintf('Initial Parameter Estimate: [0 0 0 0]\n');
fprintf('Initial Covariance Matrix: 100*eye(4)\n\n');

% Instructions for creating time-varying parameter model
fprintf('To create a model with time-varying parameters:\n');
fprintf('1. Create a new subsystem to replace the Transfer Function block\n');
fprintf('2. Inside the subsystem, use a Multiport Switch to select between different Transfer Function blocks\n');
fprintf('3. Use a Step or Clock block to control the switching time\n');
fprintf('4. Set the forgetting factor to a value between 0.95 and 0.98\n');
fprintf('5. Experiment with different noise levels and input signals\n\n');

% Create a second model for continuous system identification
fprintf('Creating second Simulink model for continuous system identification\n\n');
modelName2 = 'OnlineIdentificationContinuous';
if ~bdIsLoaded(modelName2)
    new_system(modelName2);
end
open_system(modelName2);

fprintf('Creating Simulink model: %s\n', modelName2);
fprintf('This model implements online identification of continuous system G2\n');
fprintf('G2(s) = (s + 1)/(s^2 + 2s + 3)\n\n');

% Set simulation parameters
set_param(modelName2, 'Solver', 'ode45', 'StopTime', '20');

% Add a white noise source
add_block('simulink/Sources/Band-Limited White Noise', [modelName2 '/Noise']);
set_param([modelName2 '/Noise'], 'Position', [50, 100, 80, 130]);
set_param([modelName2 '/Noise'], 'Ts', '0.01');

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
set_param([modelName2 '/OutputNoise'], 'Ts', '0.01');
set_param([modelName2 '/OutputNoise'], 'Cov', '0.01');

% Add a summing block for adding output noise
add_block('simulink/Math Operations/Sum', [modelName2 '/Sum']);
set_param([modelName2 '/Sum'], 'Position', [400, 105, 420, 125]);
set_param([modelName2 '/Sum'], 'Inputs', '++');

% Create custom RLS implementation for G2
fprintf('Creating custom RLS implementation for continuous system\n');

% Create a subsystem for RLS implementation
add_block('simulink/Ports & Subsystems/Subsystem', [modelName2 '/RLS']);
set_param([modelName2 '/RLS'], 'Position', [500, 100, 600, 130]);

% Add input/output ports to RLS subsystem
add_block('simulink/Ports & Subsystems/In1', [modelName2 '/RLS/In1']);
set_param([modelName2 '/RLS/In1'], 'Position', [50, 100, 70, 120]);
add_block('simulink/Ports & Subsystems/In2', [modelName2 '/RLS/In2']);
set_param([modelName2 '/RLS/In2'], 'Position', [50, 160, 70, 180]);

add_block('simulink/Ports & Subsystems/Out1', [modelName2 '/RLS/Out1']);
set_param([modelName2 '/RLS/Out1'], 'Position', [450, 130, 470, 150]);

% Add MATLAB Function block for RLS algorithm
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName2 '/RLS/RLSFunction']);
set_param([modelName2 '/RLS/RLSFunction'], 'Position', [250, 120, 350, 160]);

% Set the MATLAB Function block content with RLS algorithm for continuous system
rls_code = [
    'function theta = RLSFunction(u, y)\n'...
    '    persistent P theta_prev phi_prev;\n'...
    '    if isempty(P)\n'...
    '        % Initialize parameters\n'...
    '        P = 100*eye(4);\n'...
    '        theta_prev = zeros(4,1);\n'...
    '        phi_prev = zeros(4,1);\n'...
    '    end\n'...
    '    \n'...
    '    % Current regressor vector\n'...
    '    phi = [y; phi_prev(1); u; phi_prev(3)];\n'...
    '    \n'...
    '    % Forgetting factor\n'...
    '    lambda = 0.98;\n'...
    '    \n'...
    '    % RLS algorithm\n'...
    '    K = P*phi/(lambda + phi''*P*phi);\n'...
    '    epsilon = y - phi''*theta_prev;\n'...
    '    theta = theta_prev + K*epsilon;\n'...
    '    P = (P - K*phi''*P)/lambda;\n'...
    '    \n'...
    '    % Store for next iteration\n'...
    '    theta_prev = theta;\n'...
    '    phi_prev = phi;\n'...
    'end\n'
];

set_param([modelName2 '/RLS/RLSFunction'], 'MATLABFcn', rls_code);

% Connect blocks in RLS subsystem
add_line([modelName2 '/RLS'], 'In1/1', 'RLSFunction/1', 'autorouting', 'on');
add_line([modelName2 '/RLS'], 'In2/1', 'RLSFunction/2', 'autorouting', 'on');
add_line([modelName2 '/RLS'], 'RLSFunction/1', 'Out1/1', 'autorouting', 'on');

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

% Save model diagram as PNG
fprintf('Saving model diagram as PNG...\n');
print([modelName2, '/'], '-dpng', 'G2_simulink_model.png');

% Display model configuration details
fprintf('Continuous System G2 Model Configuration:\n');
fprintf('Sample Time: 0.01 seconds\n');
fprintf('Simulation Time: 20 seconds\n');
fprintf('Noise Variance: 0.01\n');
fprintf('Forgetting Factor: 0.98\n');
fprintf('Initial Parameter Estimate: [0 0 0 0]\n');
fprintf('Initial Covariance Matrix: 100*eye(4)\n\n');

% Create time-varying model for demonstration
fprintf('Creating a time-varying parameter model example...\n');
modelName3 = 'OnlineIdentificationTimeVarying';
if ~bdIsLoaded(modelName3)
    new_system(modelName3);
end
open_system(modelName3);

fprintf('Creating Simulink model: %s\n', modelName3);
fprintf('This model demonstrates time-varying parameter identification\n\n');

% Set simulation parameters
set_param(modelName3, 'Solver', 'ode45', 'StopTime', '40');

% Add time-varying system using manual switch
add_block('simulink/Sources/Band-Limited White Noise', [modelName3 '/Noise']);
set_param([modelName3 '/Noise'], 'Position', [50, 100, 80, 130]);
set_param([modelName3 '/Noise'], 'Ts', '0.1');

% Create subsystem for time-varying plant
add_block('simulink/Ports & Subsystems/Subsystem', [modelName3 '/TimeVaryingPlant']);
set_param([modelName3 '/TimeVaryingPlant'], 'Position', [150, 100, 250, 130]);

% Create first system
add_block('simulink/Discrete/Discrete Transfer Fcn', [modelName3 '/TimeVaryingPlant/G1']);
set_param([modelName3 '/TimeVaryingPlant/G1'], 'Position', [200, 70, 300, 100]);
set_param([modelName3 '/TimeVaryingPlant/G1'], 'Numerator', '[0.1 0.2]');
set_param([modelName3 '/TimeVaryingPlant/G1'], 'Denominator', '[1 0.3 0.4]');
set_param([modelName3 '/TimeVaryingPlant/G1'], 'SampleTime', '0.1');

% Create second system (with changed parameters)
add_block('simulink/Discrete/Discrete Transfer Fcn', [modelName3 '/TimeVaryingPlant/G2']);
set_param([modelName3 '/TimeVaryingPlant/G2'], 'Position', [200, 170, 300, 200]);
set_param([modelName3 '/TimeVaryingPlant/G2'], 'Numerator', '[0.1 0.5]');  % b0 changed from 0.2 to 0.5
set_param([modelName3 '/TimeVaryingPlant/G2'], 'Denominator', '[1 0.3 0.4]');
set_param([modelName3 '/TimeVaryingPlant/G2'], 'SampleTime', '0.1');

% Add a switch
add_block('simulink/Signal Routing/Manual Switch', [modelName3 '/TimeVaryingPlant/Switch']);
set_param([modelName3 '/TimeVaryingPlant/Switch'], 'Position', [400, 120, 430, 150]);

% Add step block to control switching
add_block('simulink/Sources/Step', [modelName3 '/TimeVaryingPlant/Step']);
set_param([modelName3 '/TimeVaryingPlant/Step'], 'Position', [100, 230, 130, 260]);
set_param([modelName3 '/TimeVaryingPlant/Step'], 'Time', '20');  % Switch at t=20
set_param([modelName3 '/TimeVaryingPlant/Step'], 'After', '1');
set_param([modelName3 '/TimeVaryingPlant/Step'], 'Before', '0');

% Add multiport switch
add_block('simulink/Signal Routing/Multiport Switch', [modelName3 '/TimeVaryingPlant/MultiSwitch']);
set_param([modelName3 '/TimeVaryingPlant/MultiSwitch'], 'Position', [350, 120, 380, 150]);
set_param([modelName3 '/TimeVaryingPlant/MultiSwitch'], 'Inputs', '3');

% Add input/output ports for subsystem
add_block('simulink/Ports & Subsystems/In1', [modelName3 '/TimeVaryingPlant/In1']);
set_param([modelName3 '/TimeVaryingPlant/In1'], 'Position', [50, 120, 70, 140]);

add_block('simulink/Ports & Subsystems/Out1', [modelName3 '/TimeVaryingPlant/Out1']);
set_param([modelName3 '/TimeVaryingPlant/Out1'], 'Position', [480, 120, 500, 140]);

% Connect the blocks in subsystem
add_line([modelName3 '/TimeVaryingPlant'], 'In1/1', 'G1/1', 'autorouting', 'on');
add_line([modelName3 '/TimeVaryingPlant'], 'In1/1', 'G2/1', 'autorouting', 'on');
add_line([modelName3 '/TimeVaryingPlant'], 'G1/1', 'MultiSwitch/1', 'autorouting', 'on');
add_line([modelName3 '/TimeVaryingPlant'], 'G2/1', 'MultiSwitch/2', 'autorouting', 'on');
add_line([modelName3 '/TimeVaryingPlant'], 'Step/1', 'MultiSwitch/3', 'autorouting', 'on');
add_line([modelName3 '/TimeVaryingPlant'], 'MultiSwitch/1', 'Out1/1', 'autorouting', 'on');

% Rest of the model (same as before)
add_block('simulink/Sources/Band-Limited White Noise', [modelName3 '/OutputNoise']);
set_param([modelName3 '/OutputNoise'], 'Position', [150, 180, 180, 210]);
set_param([modelName3 '/OutputNoise'], 'Ts', '0.1');
set_param([modelName3 '/OutputNoise'], 'Cov', '0.01');

add_block('simulink/Math Operations/Sum', [modelName3 '/Sum']);
set_param([modelName3 '/Sum'], 'Position', [300, 105, 320, 125]);
set_param([modelName3 '/Sum'], 'Inputs', '++');

% Create custom RLS implementation for time-varying system
fprintf('Creating custom RLS implementation for time-varying system\n');

% Create a subsystem for RLS implementation
add_block('simulink/Ports & Subsystems/Subsystem', [modelName3 '/RLS']);
set_param([modelName3 '/RLS'], 'Position', [400, 100, 500, 130]);

% Add input/output ports to RLS subsystem
add_block('simulink/Ports & Subsystems/In1', [modelName3 '/RLS/In1']);
set_param([modelName3 '/RLS/In1'], 'Position', [50, 100, 70, 120]);
add_block('simulink/Ports & Subsystems/In2', [modelName3 '/RLS/In2']);
set_param([modelName3 '/RLS/In2'], 'Position', [50, 160, 70, 180]);

add_block('simulink/Ports & Subsystems/Out1', [modelName3 '/RLS/Out1']);
set_param([modelName3 '/RLS/Out1'], 'Position', [450, 130, 470, 150]);

% Add MATLAB Function block for RLS algorithm
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName3 '/RLS/RLSFunction']);
set_param([modelName3 '/RLS/RLSFunction'], 'Position', [250, 120, 350, 160]);

% Set the MATLAB Function block content with RLS algorithm - using lower forgetting factor
rls_code = [
    'function theta = RLSFunction(u, y)\n'...
    '    persistent P theta_prev phi_prev;\n'...
    '    if isempty(P)\n'...
    '        % Initialize parameters\n'...
    '        P = 100*eye(4);\n'...
    '        theta_prev = zeros(4,1);\n'...
    '        phi_prev = zeros(4,1);\n'...
    '    end\n'...
    '    \n'...
    '    % Current regressor vector\n'...
    '    phi = [-y; -phi_prev(1); u; phi_prev(3)];\n'...
    '    \n'...
    '    % Lower forgetting factor for better tracking of time-varying parameters\n'...
    '    lambda = 0.95;\n'...
    '    \n'...
    '    % RLS algorithm\n'...
    '    K = P*phi/(lambda + phi''*P*phi);\n'...
    '    epsilon = y - phi''*theta_prev;\n'...
    '    theta = theta_prev + K*epsilon;\n'...
    '    P = (P - K*phi''*P)/lambda;\n'...
    '    \n'...
    '    % Store for next iteration\n'...
    '    theta_prev = theta;\n'...
    '    phi_prev = phi;\n'...
    'end\n'
];

set_param([modelName3 '/RLS/RLSFunction'], 'MATLABFcn', rls_code);

% Connect blocks in RLS subsystem
add_line([modelName3 '/RLS'], 'In1/1', 'RLSFunction/1', 'autorouting', 'on');
add_line([modelName3 '/RLS'], 'In2/1', 'RLSFunction/2', 'autorouting', 'on');
add_line([modelName3 '/RLS'], 'RLSFunction/1', 'Out1/1', 'autorouting', 'on');

add_block('simulink/Signal Routing/Demux', [modelName3 '/Demux']);
set_param([modelName3 '/Demux'], 'Position', [550, 100, 570, 130]);
set_param([modelName3 '/Demux'], 'Outputs', '4');

add_block('simulink/Sinks/Scope', [modelName3 '/ParametersScope']);
set_param([modelName3 '/ParametersScope'], 'Position', [650, 100, 680, 130]);

add_block('simulink/Sources/Clock', [modelName3 '/Clock']);
set_param([modelName3 '/Clock'], 'Position', [400, 200, 420, 220]);

add_block('simulink/Sinks/To Workspace', [modelName3 '/ToWorkspaceTheta']);
set_param([modelName3 '/ToWorkspaceTheta'], 'Position', [550, 200, 610, 230]);
set_param([modelName3 '/ToWorkspaceTheta'], 'VariableName', 'theta');
set_param([modelName3 '/ToWorkspaceTheta'], 'SampleTime', '0.1');

add_block('simulink/Sinks/To Workspace', [modelName3 '/ToWorkspaceTime']);
set_param([modelName3 '/ToWorkspaceTime'], 'Position', [450, 200, 510, 230]);
set_param([modelName3 '/ToWorkspaceTime'], 'VariableName', 't');
set_param([modelName3 '/ToWorkspaceTime'], 'SampleTime', '0.1');

% Connect the blocks
add_line(modelName3, 'Noise/1', 'TimeVaryingPlant/1', 'autorouting', 'on');
add_line(modelName3, 'TimeVaryingPlant/1', 'Sum/1', 'autorouting', 'on');
add_line(modelName3, 'OutputNoise/1', 'Sum/2', 'autorouting', 'on');
add_line(modelName3, 'Sum/1', 'RLS/2', 'autorouting', 'on');
add_line(modelName3, 'Noise/1', 'RLS/1', 'autorouting', 'on');
add_line(modelName3, 'RLS/1', 'Demux/1', 'autorouting', 'on');
add_line(modelName3, 'Demux/1', 'ParametersScope/1', 'autorouting', 'on');
add_line(modelName3, 'RLS/1', 'ToWorkspaceTheta/1', 'autorouting', 'on');
add_line(modelName3, 'Clock/1', 'ToWorkspaceTime/1', 'autorouting', 'on');

% Save model
save_system(modelName3);

% Save model diagram as PNG
fprintf('Saving time-varying model diagram as PNG...\n');
print([modelName3, '/'], '-dpng', 'G1_time_varying_simulink_model.png');

% Save internal subsystem as PNG
open_system([modelName3 '/TimeVaryingPlant']);
fprintf('Saving time-varying plant subsystem diagram as PNG...\n');
print([modelName3, '/TimeVaryingPlant/'], '-dpng', 'G1_time_varying_plant_subsystem.png');

% Display time-varying model configuration details
fprintf('Time-Varying System Model Configuration:\n');
fprintf('Sample Time: 0.1 seconds\n');
fprintf('Simulation Time: 40 seconds\n');
fprintf('Parameter Change Time: 20 seconds\n');
fprintf('Changed Parameter: b0 from 0.2 to 0.5\n');
fprintf('Noise Variance: 0.01\n');
fprintf('Forgetting Factor: 0.95\n');
fprintf('Initial Parameter Estimate: [0 0 0 0]\n');
fprintf('Initial Covariance Matrix: 100*eye(4)\n\n');

fprintf('Instructions for running the simulation:\n');
fprintf('1. Click the Run button in the Simulink model window\n');
fprintf('2. View parameter estimation results in the ParametersScope\n');
fprintf('3. Parameters will be saved to the workspace for further analysis\n');
fprintf('4. For better visualization, plot the theta variable from the workspace\n\n');

fprintf('All Simulink models have been created and saved as PNG files.\n');