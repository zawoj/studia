% Online Identification Implementation Using Pure MATLAB
% This script implements the RLS algorithm for both discrete and continuous systems
% without using Simulink, focusing on direct equation implementation

%% PART 1: DISCRETE SYSTEM IDENTIFICATION
% G1(z) = (0.1z + 0.2)/(z^2 + 0.3z + 0.4)

clear all;
close all;
clc;

% Simulation parameters
T = 0.1;      % Sample time
t_end = 20;   % Simulation end time
t = 0:T:t_end;
N = length(t);

% True parameters of the system G1
a1_true = 0.3;
a0_true = 0.4;
b1_true = 0.1;
b0_true = 0.2;

% Generate input signal (white noise)
rng(42);  % Set seed for reproducibility
u = randn(N, 1);

% Generate output signal using difference equation
y = zeros(N, 1);
for k = 3:N
    y(k) = -a1_true*y(k-1) - a0_true*y(k-2) + b1_true*u(k-1) + b0_true*u(k-2);
end

% Add measurement noise
noise_level = 0.01;
y_noisy = y + noise_level*randn(N, 1);

% Initialize RLS algorithm parameters
theta = zeros(N, 4);  % Parameter estimates [a1, a0, b1, b0]
theta(1:2, :) = repmat([0, 0, 0, 0], 2, 1);  % Initial guess

% Initialize covariance matrix P
P = zeros(4, 4, N);
P(:,:,1:2) = repmat(100*eye(4), 1, 1, 2);  % High initial uncertainty

% Forgetting factor
lambda = 0.98;

% Run RLS algorithm
for k = 3:N
    % Form regressor vector
    phi = [-y_noisy(k-1); -y_noisy(k-2); u(k-1); u(k-2)];
    
    % Prediction error
    epsilon = y_noisy(k) - phi' * theta(k-1,:)';
    
    % Update P matrix according to equation (1) from the PDF
    P_prev = P(:,:,k-1);
    P(:,:,k) = (P_prev - (P_prev * phi * phi' * P_prev) / (lambda + phi' * P_prev * phi)) / lambda;
    
    % Calculate Kalman gain according to equation (3)
    K = P(:,:,k) * phi;
    
    % Update parameter estimates according to equation (4)
    theta(k,:) = theta(k-1,:) + (K * epsilon)';
end

% Display parameter estimation results at different time points
disp('=== PART 1: DISCRETE SYSTEM IDENTIFICATION ===');
disp('True parameters: ');
disp(['a1 = ', num2str(a1_true), ', a0 = ', num2str(a0_true), ...
      ', b1 = ', num2str(b1_true), ', b0 = ', num2str(b0_true)]);

% Display results at 25%, 50%, 75% and 100% of simulation time
checkpoints = [round(N*0.25), round(N*0.5), round(N*0.75), N];
for i = 1:length(checkpoints)
    k = checkpoints(i);
    disp(['Parameters at t = ', num2str(t(k)), 's (', num2str(k), '/', num2str(N), ' samples):']);
    disp(['a1 = ', num2str(theta(k,1)), ', a0 = ', num2str(theta(k,2)), ...
          ', b1 = ', num2str(theta(k,3)), ', b0 = ', num2str(theta(k,4))]);
    disp(['Error (%): a1 = ', num2str(100*(theta(k,1)-a1_true)/a1_true), ...
          ', a0 = ', num2str(100*(theta(k,2)-a0_true)/a0_true), ...
          ', b1 = ', num2str(100*(theta(k,3)-b1_true)/b1_true), ...
          ', b0 = ', num2str(100*(theta(k,4)-b0_true)/b0_true)]);
end

% Combined plot (as before)
fig1 = figure('Name', 'Discrete System Identification - Combined', 'NumberTitle', 'off');
subplot(2,1,1);
plot(t, theta(:,1), 'r-', t, theta(:,2), 'g-', t, theta(:,3), 'b-', t, theta(:,4), 'm-', 'LineWidth', 1.5);
hold on;
plot(t, a1_true*ones(size(t)), 'r--', t, a0_true*ones(size(t)), 'g--', ...
     t, b1_true*ones(size(t)), 'b--', t, b0_true*ones(size(t)), 'm--', 'LineWidth', 1);
hold off;
title('Parameter Estimation for G1(z) = (0.1z + 0.2)/(z^2 + 0.3z + 0.4)');
xlabel('Time [s]');
ylabel('Parameter values');
legend('Estimated a_1', 'Estimated a_0', 'Estimated b_1', 'Estimated b_0', ...
       'True a_1', 'True a_0', 'True b_1', 'True b_0');
grid on;

% Plot diagonal elements of P matrix
subplot(2,1,2);
plot(t, squeeze(P(1,1,:)), 'r-', t, squeeze(P(2,2,:)), 'g-', ...
     t, squeeze(P(3,3,:)), 'b-', t, squeeze(P(4,4,:)), 'm-', 'LineWidth', 1.5);
title('Covariance Matrix Diagonal Elements');
xlabel('Time [s]');
ylabel('P matrix diagonal values');
legend('P(1,1)', 'P(2,2)', 'P(3,3)', 'P(4,4)');
grid on;

% Save the combined figure
saveas(fig1, 'part1_combined.png');

% Individual parameter plots with auto-scaling y-axis
param_names = {'a_1', 'a_0', 'b_1', 'b_0'};
true_values = [a1_true, a0_true, b1_true, b0_true];

for i = 1:4
    fig = figure('Name', ['Discrete System - ' param_names{i}], 'NumberTitle', 'off');
    plot(t, theta(:,i), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(t, true_values(i)*ones(size(t)), 'r--', 'LineWidth', 1.5);
    hold off;
    title(['Parameter Estimation for ' param_names{i}]);
    xlabel('Time [s]');
    ylabel(['Parameter ' param_names{i} ' value']);
    legend(['Estimated ' param_names{i}], ['True ' param_names{i}]);
    grid on;
    % Auto-scale y-axis with some margin
    ylim_current = ylim;
    ylim_range = ylim_current(2) - ylim_current(1);
    ylim([ylim_current(1) - 0.1*ylim_range, ylim_current(2) + 0.1*ylim_range]);
    
    % Save individual parameter figure
    saveas(fig, ['part1_' param_names{i} '.png']);
end

% Individual covariance matrix plots
for i = 1:4
    fig = figure('Name', ['Discrete System - P(' num2str(i) ',' num2str(i) ')'], 'NumberTitle', 'off');
    plot(t, squeeze(P(i,i,:)), 'b-', 'LineWidth', 1.5);
    title(['Covariance Matrix Element P(' num2str(i) ',' num2str(i) ')']);
    xlabel('Time [s]');
    ylabel(['P(' num2str(i) ',' num2str(i) ') value']);
    grid on;
    
    % Save covariance figure
    saveas(fig, ['part1_P' num2str(i) num2str(i) '.png']);
end

%% PART 2: DISCRETE SYSTEM WITH TIME-VARYING PARAMETERS
% G1(z) with changing b0 parameter

clear all;
close all;

% Simulation parameters
T = 0.1;
t_end = 40;
t = 0:T:t_end;
N = length(t);

% Define time-varying parameters
a1 = 0.3 * ones(N, 1);
a0 = 0.4 * ones(N, 1);
b1 = 0.1 * ones(N, 1);
b0 = 0.2 * ones(N, 1);

% Create parameter change at t = 20s
change_time = 20;
change_index = find(t >= change_time, 1);
b0(change_index:end) = 0.5;  % b0 changes from 0.2 to 0.5

% Generate input signal
rng(42);
u = randn(N, 1);

% Generate output signal with time-varying parameters
y = zeros(N, 1);
for k = 3:N
    y(k) = -a1(k)*y(k-1) - a0(k)*y(k-2) + b1(k)*u(k-1) + b0(k)*u(k-2);
end

% Add measurement noise
noise_level = 0.01;
y_noisy = y + noise_level*randn(N, 1);

% Initialize RLS algorithm parameters
theta = zeros(N, 4);
theta(1:2, :) = repmat([0, 0, 0, 0], 2, 1);

% Initialize covariance matrix P
P = zeros(4, 4, N);
P(:,:,1:2) = repmat(100*eye(4), 1, 1, 2);

% Forgetting factor (smaller value for faster adaptation to changes)
lambda = 0.95;

% Run RLS algorithm
for k = 3:N
    phi = [-y_noisy(k-1); -y_noisy(k-2); u(k-1); u(k-2)];
    epsilon = y_noisy(k) - phi' * theta(k-1,:)';
    
    P_prev = P(:,:,k-1);
    P(:,:,k) = (P_prev - (P_prev * phi * phi' * P_prev) / (lambda + phi' * P_prev * phi)) / lambda;
    
    K = P(:,:,k) * phi;
    theta(k,:) = theta(k-1,:) + (K * epsilon)';
end

% Display parameter estimation results for time-varying system
disp('=== PART 2: DISCRETE SYSTEM WITH TIME-VARYING PARAMETERS ===');

% Display results before, at, and after the parameter change
before_change = find(t < change_time, 1, 'last');
after_change = change_index + round(N/10);  % A bit after change
final_point = N;

checkpoints = [before_change, change_index, after_change, final_point];
checkpoint_labels = {'Before change', 'At change', 'Shortly after change', 'Final'};

for i = 1:length(checkpoints)
    k = checkpoints(i);
    disp([checkpoint_labels{i}, ' parameters at t = ', num2str(t(k)), 's:']);
    disp(['True:      a1 = ', num2str(a1(k)), ', a0 = ', num2str(a0(k)), ...
          ', b1 = ', num2str(b1(k)), ', b0 = ', num2str(b0(k))]);
    disp(['Estimated: a1 = ', num2str(theta(k,1)), ', a0 = ', num2str(theta(k,2)), ...
          ', b1 = ', num2str(theta(k,3)), ', b0 = ', num2str(theta(k,4))]);
    disp(['Error (%): a1 = ', num2str(100*(theta(k,1)-a1(k))/a1(k)), ...
          ', a0 = ', num2str(100*(theta(k,2)-a0(k))/a0(k)), ...
          ', b1 = ', num2str(100*(theta(k,3)-b1(k))/b1(k)), ...
          ', b0 = ', num2str(100*(theta(k,4)-b0(k))/b0(k))]);
end

% Combined plot (as before)
fig2 = figure('Name', 'Time-Varying System Identification - Combined', 'NumberTitle', 'off');
subplot(2,1,1);
plot(t, theta(:,1), 'r-', t, theta(:,2), 'g-', t, theta(:,3), 'b-', t, theta(:,4), 'm-', 'LineWidth', 1.5);
hold on;
plot(t, a1, 'r--', t, a0, 'g--', t, b1, 'b--', t, b0, 'm--', 'LineWidth', 1);
hold off;
title(['Parameter Estimation for Time-Varying System (λ = ', num2str(lambda), ')']);
xlabel('Time [s]');
ylabel('Parameter values');
legend('Estimated a_1', 'Estimated a_0', 'Estimated b_1', 'Estimated b_0', ...
       'True a_1', 'True a_0', 'True b_1', 'True b_0');
grid on;

% Plot diagonal elements of P matrix
subplot(2,1,2);
plot(t, squeeze(P(1,1,:)), 'r-', t, squeeze(P(2,2,:)), 'g-', ...
     t, squeeze(P(3,3,:)), 'b-', t, squeeze(P(4,4,:)), 'm-', 'LineWidth', 1.5);
title('Covariance Matrix Diagonal Elements');
xlabel('Time [s]');
ylabel('P matrix diagonal values');
legend('P(1,1)', 'P(2,2)', 'P(3,3)', 'P(4,4)');
grid on;

% Save the combined figure
saveas(fig2, 'part2_combined.png');

% Individual parameter plots with auto-scaling y-axis
param_names = {'a_1', 'a_0', 'b_1', 'b_0'};
true_values = {a1, a0, b1, b0};  % For time-varying parameters, use arrays

for i = 1:4
    fig = figure('Name', ['Time-Varying System - ' param_names{i}], 'NumberTitle', 'off');
    plot(t, theta(:,i), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(t, true_values{i}, 'r--', 'LineWidth', 1.5);
    
    % Add a vertical line at the change point
    xline(change_time, 'k--', 'Parameter Change');
    
    hold off;
    title(['Parameter Estimation for ' param_names{i}]);
    xlabel('Time [s]');
    ylabel(['Parameter ' param_names{i} ' value']);
    legend(['Estimated ' param_names{i}], ['True ' param_names{i}]);
    grid on;
    % Auto-scale y-axis with some margin
    ylim_current = ylim;
    ylim_range = ylim_current(2) - ylim_current(1);
    ylim([ylim_current(1) - 0.1*ylim_range, ylim_current(2) + 0.1*ylim_range]);
    
    % Save individual parameter figure
    saveas(fig, ['part2_' param_names{i} '.png']);
end

% Individual covariance matrix plots
for i = 1:4
    fig = figure('Name', ['Time-Varying System - P(' num2str(i) ',' num2str(i) ')'], 'NumberTitle', 'off');
    plot(t, squeeze(P(i,i,:)), 'b-', 'LineWidth', 1.5);
    % Add a vertical line at the change point
    xline(change_time, 'k--', 'Parameter Change');
    title(['Covariance Matrix Element P(' num2str(i) ',' num2str(i) ')']);
    xlabel('Time [s]');
    ylabel(['P(' num2str(i) ',' num2str(i) ') value']);
    grid on;
    
    % Save covariance figure
    saveas(fig, ['part2_P' num2str(i) num2str(i) '.png']);
end

%% PART 3: CONTINUOUS SYSTEM IDENTIFICATION
% G2(s) = (s + 1)/(s^2 + 2s + 3)

clear all;
close all;

% Simulation parameters
T = 0.01;     % Smaller sample time for continuous system
t_end = 20;
t = 0:T:t_end;
N = length(t);

% Define continuous system
num = [1 1];
den = [1 2 3];

% Convert to discrete-time equivalent (for simulation)
sys_cont = tf(num, den);
sys_disc = c2d(sys_cont, T, 'zoh');  % Zero-order hold discretization
[num_d, den_d] = tfdata(sys_disc, 'v');

% Extract discrete parameters
a1_disc = -den_d(2);
a0_disc = -den_d(3);
b1_disc = num_d(2);
b0_disc = num_d(3);

% Display discrete equivalent parameters
disp('=== PART 3: CONTINUOUS SYSTEM IDENTIFICATION ===');
disp('Discrete equivalent parameters of G2(s):');
disp(['a1 = ' num2str(a1_disc)]);
disp(['a0 = ' num2str(a0_disc)]);
disp(['b1 = ' num2str(b1_disc)]);
disp(['b0 = ' num2str(b0_disc)]);

% Generate input signal
rng(42);
u = randn(N, 1);

% Generate output signal using discrete equivalent model
y = zeros(N, 1);
for k = 3:N
    y(k) = a1_disc*y(k-1) + a0_disc*y(k-2) + b1_disc*u(k-1) + b0_disc*u(k-2);
end

% Add measurement noise
noise_level = 0.01;
y_noisy = y + noise_level*randn(N, 1);

% Initialize RLS algorithm
theta = zeros(N, 4);
theta(1:2, :) = repmat([0, 0, 0, 0], 2, 1);

P = zeros(4, 4, N);
P(:,:,1:2) = repmat(100*eye(4), 1, 1, 2);

lambda = 0.98;

% Run RLS algorithm
for k = 3:N
    phi = [y_noisy(k-1); y_noisy(k-2); u(k-1); u(k-2)];
    epsilon = y_noisy(k) - phi' * theta(k-1,:)';
    
    P_prev = P(:,:,k-1);
    P(:,:,k) = (P_prev - (P_prev * phi * phi' * P_prev) / (lambda + phi' * P_prev * phi)) / lambda;
    
    K = P(:,:,k) * phi;
    theta(k,:) = theta(k-1,:) + (K * epsilon)';
end

% Display parameter estimation results at different time points
disp('Continuous system parameter estimation results:');
disp('True parameters (discrete equivalent): ');
disp(['a1 = ', num2str(a1_disc), ', a0 = ', num2str(a0_disc), ...
      ', b1 = ', num2str(b1_disc), ', b0 = ', num2str(b0_disc)]);

% Display results at 25%, 50%, 75% and 100% of simulation time
checkpoints = [round(N*0.25), round(N*0.5), round(N*0.75), N];
for i = 1:length(checkpoints)
    k = checkpoints(i);
    disp(['Parameters at t = ', num2str(t(k)), 's (', num2str(k), '/', num2str(N), ' samples):']);
    disp(['a1 = ', num2str(theta(k,1)), ', a0 = ', num2str(theta(k,2)), ...
          ', b1 = ', num2str(theta(k,3)), ', b0 = ', num2str(theta(k,4))]);
    disp(['Error (%): a1 = ', num2str(100*(theta(k,1)-a1_disc)/a1_disc), ...
          ', a0 = ', num2str(100*(theta(k,2)-a0_disc)/a0_disc), ...
          ', b1 = ', num2str(100*(theta(k,3)-b1_disc)/b1_disc), ...
          ', b0 = ', num2str(100*(theta(k,4)-b0_disc)/b0_disc)]);
end

% Combined plot (as before)
fig3 = figure('Name', 'Continuous System Identification - Combined', 'NumberTitle', 'off');
subplot(2,1,1);
plot(t, theta(:,1), 'r-', t, theta(:,2), 'g-', t, theta(:,3), 'b-', t, theta(:,4), 'm-', 'LineWidth', 1.5);
hold on;
plot(t, a1_disc*ones(size(t)), 'r--', t, a0_disc*ones(size(t)), 'g--', ...
     t, b1_disc*ones(size(t)), 'b--', t, b0_disc*ones(size(t)), 'm--', 'LineWidth', 1);
hold off;
title('Parameter Estimation for G2(s) = (s + 1)/(s^2 + 2s + 3)');
xlabel('Time [s]');
ylabel('Parameter values');
legend('Estimated a_1', 'Estimated a_0', 'Estimated b_1', 'Estimated b_0', ...
       'True a_1', 'True a_0', 'True b_1', 'True b_0');
grid on;

% Plot diagonal elements of P matrix
subplot(2,1,2);
plot(t, squeeze(P(1,1,:)), 'r-', t, squeeze(P(2,2,:)), 'g-', ...
     t, squeeze(P(3,3,:)), 'b-', t, squeeze(P(4,4,:)), 'm-', 'LineWidth', 1.5);
title('Covariance Matrix Diagonal Elements');
xlabel('Time [s]');
ylabel('P matrix diagonal values');
legend('P(1,1)', 'P(2,2)', 'P(3,3)', 'P(4,4)');
grid on;

% Save the combined figure
saveas(fig3, 'part3_combined.png');

% Individual parameter plots with auto-scaling y-axis
param_names = {'a_1', 'a_0', 'b_1', 'b_0'};
true_values = [a1_disc, a0_disc, b1_disc, b0_disc];

for i = 1:4
    fig = figure('Name', ['Continuous System - ' param_names{i}], 'NumberTitle', 'off');
    plot(t, theta(:,i), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(t, true_values(i)*ones(size(t)), 'r--', 'LineWidth', 1.5);
    hold off;
    title(['Parameter Estimation for ' param_names{i}]);
    xlabel('Time [s]');
    ylabel(['Parameter ' param_names{i} ' value']);
    legend(['Estimated ' param_names{i}], ['True ' param_names{i}]);
    grid on;
    % Auto-scale y-axis with some margin
    ylim_current = ylim;
    ylim_range = ylim_current(2) - ylim_current(1);
    ylim([ylim_current(1) - 0.1*ylim_range, ylim_current(2) + 0.1*ylim_range]);
    
    % Save individual parameter figure
    saveas(fig, ['part3_' param_names{i} '.png']);
end

% Individual covariance matrix plots
for i = 1:4
    fig = figure('Name', ['Continuous System - P(' num2str(i) ',' num2str(i) ')'], 'NumberTitle', 'off');
    plot(t, squeeze(P(i,i,:)), 'b-', 'LineWidth', 1.5);
    title(['Covariance Matrix Element P(' num2str(i) ',' num2str(i) ')']);
    xlabel('Time [s]');
    ylabel(['P(' num2str(i) ',' num2str(i) ') value']);
    grid on;
    
    % Save covariance figure
    saveas(fig, ['part3_P' num2str(i) num2str(i) '.png']);
end

%% PART 4: CONTINUOUS SYSTEM WITH TIME-VARYING PARAMETERS
% G2(s) with changing numerator coefficient

clear all;
close all;

% Simulation parameters
T = 0.01;
t_end = 40;
t = 0:T:t_end;
N = length(t);

% Define initial and final continuous systems
num1 = [1 1];  % Initial numerator
den1 = [1 2 3];  % Denominator stays the same
sys_cont1 = tf(num1, den1);
sys_disc1 = c2d(sys_cont1, T, 'zoh');
[num_d1, den_d1] = tfdata(sys_disc1, 'v');

num2 = [1 2];  % Changed numerator coefficient
den2 = [1 2 3];
sys_cont2 = tf(num2, den2);
sys_disc2 = c2d(sys_cont2, T, 'zoh');
[num_d2, den_d2] = tfdata(sys_disc2, 'v');

% Set up time-varying parameters
change_time = 20;
change_index = find(t >= change_time, 1);

% Initialize parameter arrays
a1 = zeros(N, 1);
a0 = zeros(N, 1);
b1 = zeros(N, 1);
b0 = zeros(N, 1);

% Fill with appropriate values
a1(1:change_index-1) = den_d1(2);
a0(1:change_index-1) = den_d1(3);
b1(1:change_index-1) = num_d1(2);
b0(1:change_index-1) = num_d1(3);

a1(change_index:end) = den_d2(2);
a0(change_index:end) = den_d2(3);
b1(change_index:end) = num_d2(2);
b0(change_index:end) = num_d2(3);

% Generate input
rng(42);
u = randn(N, 1);

% Generate output signal using time-varying parameters
y = zeros(N, 1);
for k = 3:N
    y(k) = -a1(k)*y(k-1) - a0(k)*y(k-2) + b1(k)*u(k-1) + b0(k)*u(k-2);
end

% Add measurement noise
noise_level = 0.01;
y_noisy = y + noise_level*randn(N, 1);

% Initialize RLS algorithm parameters
theta = zeros(N, 4);
theta(1:2, :) = repmat([0, 0, 0, 0], 2, 1);

% Initialize covariance matrix P
P = zeros(4, 4, N);
P(:,:,1:2) = repmat(100*eye(4), 1, 1, 2);

% Forgetting factor (smaller value for faster adaptation to changes)
lambda = 0.95;

% Run RLS algorithm
for k = 3:N
    phi = [-y_noisy(k-1); -y_noisy(k-2); u(k-1); u(k-2)];
    epsilon = y_noisy(k) - phi' * theta(k-1,:)';
    
    P_prev = P(:,:,k-1);
    P(:,:,k) = (P_prev - (P_prev * phi * phi' * P_prev) / (lambda + phi' * P_prev * phi)) / lambda;
    
    K = P(:,:,k) * phi;
    theta(k,:) = theta(k-1,:) + (K * epsilon)';
end

% Display parameter estimation results for time-varying continuous system
disp('=== PART 4: CONTINUOUS SYSTEM WITH TIME-VARYING PARAMETERS ===');
disp('Initial continuous system G2(s) = (s + 1)/(s^2 + 2s + 3)');
disp('Final continuous system G2(s) = (s + 2)/(s^2 + 2s + 3)');

% Display discrete equivalents
disp('Initial discrete equivalent parameters:');
disp(['a1 = ', num2str(-den_d1(2)), ', a0 = ', num2str(-den_d1(3)), ...
      ', b1 = ', num2str(num_d1(2)), ', b0 = ', num2str(num_d1(3))]);

disp('Final discrete equivalent parameters:');
disp(['a1 = ', num2str(-den_d2(2)), ', a0 = ', num2str(-den_d2(3)), ...
      ', b1 = ', num2str(num_d2(2)), ', b0 = ', num2str(num_d2(3))]);

% Display results before, at, and after the parameter change
before_change = find(t < change_time, 1, 'last');
after_change = change_index + round(N/10);  % A bit after change
final_point = N;

checkpoints = [before_change, change_index, after_change, final_point];
checkpoint_labels = {'Before change', 'At change', 'Shortly after change', 'Final'};

for i = 1:length(checkpoints)
    k = checkpoints(i);
    disp([checkpoint_labels{i}, ' parameters at t = ', num2str(t(k)), 's:']);
    disp(['True:      a1 = ', num2str(-a1(k)), ', a0 = ', num2str(-a0(k)), ...
          ', b1 = ', num2str(b1(k)), ', b0 = ', num2str(b0(k))]);
    disp(['Estimated: a1 = ', num2str(theta(k,1)), ', a0 = ', num2str(theta(k,2)), ...
          ', b1 = ', num2str(theta(k,3)), ', b0 = ', num2str(theta(k,4))]);
    disp(['Error (%): a1 = ', num2str(100*(theta(k,1)-(-a1(k)))/(-a1(k))), ...
          ', a0 = ', num2str(100*(theta(k,2)-(-a0(k)))/(-a0(k))), ...
          ', b1 = ', num2str(100*(theta(k,3)-b1(k))/b1(k)), ...
          ', b0 = ', num2str(100*(theta(k,4)-b0(k))/b0(k))]);
end

% Combined plot (as before)
fig4 = figure('Name', 'Time-Varying Continuous System - Combined', 'NumberTitle', 'off');
subplot(2,1,1);
plot(t, theta(:,1), 'r-', t, theta(:,2), 'g-', t, theta(:,3), 'b-', t, theta(:,4), 'm-', 'LineWidth', 1.5);
hold on;
plot(t, -a1, 'r--', t, -a0, 'g--', t, b1, 'b--', t, b0, 'm--', 'LineWidth', 1);
hold off;
title(['Parameter Estimation for Time-Varying Continuous System (λ = ', num2str(lambda), ')']);
xlabel('Time [s]');
ylabel('Parameter values');
legend('Estimated a_1', 'Estimated a_0', 'Estimated b_1', 'Estimated b_0', ...
       'True a_1', 'True a_0', 'True b_1', 'True b_0');
grid on;

% Plot diagonal elements of P matrix
subplot(2,1,2);
plot(t, squeeze(P(1,1,:)), 'r-', t, squeeze(P(2,2,:)), 'g-', ...
     t, squeeze(P(3,3,:)), 'b-', t, squeeze(P(4,4,:)), 'm-', 'LineWidth', 1.5);
title('Covariance Matrix Diagonal Elements');
xlabel('Time [s]');
ylabel('P matrix diagonal values');
legend('P(1,1)', 'P(2,2)', 'P(3,3)', 'P(4,4)');
grid on;

% Save the combined figure
saveas(fig4, 'part4_combined.png');

% Individual parameter plots with auto-scaling y-axis
param_names = {'a_1', 'a_0', 'b_1', 'b_0'};
true_values = {-a1, -a0, b1, b0};  % For time-varying parameters, use arrays

for i = 1:4
    fig = figure('Name', ['Time-Varying Continuous System - ' param_names{i}], 'NumberTitle', 'off');
    plot(t, theta(:,i), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(t, true_values{i}, 'r--', 'LineWidth', 1.5);
    
    % Add a vertical line at the change point
    xline(change_time, 'k--', 'Parameter Change');
    
    hold off;
    title(['Parameter Estimation for ' param_names{i}]);
    xlabel('Time [s]');
    ylabel(['Parameter ' param_names{i} ' value']);
    legend(['Estimated ' param_names{i}], ['True ' param_names{i}]);
    grid on;
    % Auto-scale y-axis with some margin
    ylim_current = ylim;
    ylim_range = ylim_current(2) - ylim_current(1);
    ylim([ylim_current(1) - 0.1*ylim_range, ylim_current(2) + 0.1*ylim_range]);
    
    % Save individual parameter figure
    saveas(fig, ['part4_' param_names{i} '.png']);
end

% Individual covariance matrix plots
for i = 1:4
    fig = figure('Name', ['Time-Varying Continuous System - P(' num2str(i) ',' num2str(i) ')'], 'NumberTitle', 'off');
    plot(t, squeeze(P(i,i,:)), 'b-', 'LineWidth', 1.5);
    % Add a vertical line at the change point
    xline(change_time, 'k--', 'Parameter Change');
    title(['Covariance Matrix Element P(' num2str(i) ',' num2str(i) ')']);
    xlabel('Time [s]');
    ylabel(['P(' num2str(i) ',' num2str(i) ') value']);
    grid on;
    
    % Save covariance figure
    saveas(fig, ['part4_P' num2str(i) num2str(i) '.png']);
end

% End of script