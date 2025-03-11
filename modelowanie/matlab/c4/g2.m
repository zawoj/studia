% Online identification of continuous system G2
% G2(s) = (s + 1)/(s^2 + 2s + 3)

clear all;
close all;
clc;

% Simulation parameters
T = 0.01;     % Sample time (smaller for continuous system)
t_end = 20;   % Simulation end time
t = 0:T:t_end;
N = length(t);

% Create continuous system using transfer function
num = [1 1];
den = [1 2 3];
sys_cont = tf(num, den);

% Convert to discrete time system for simulation
sys_disc = c2d(sys_cont, T, 'zoh');
[num_d, den_d] = tfdata(sys_disc, 'v');

% Extract discrete parameters
a1_disc = -den_d(2);
a0_disc = -den_d(3);
b1_disc = num_d(2);
b0_disc = num_d(3);

% Display discrete parameters
fprintf('Continuous System G2 - Discrete equivalent parameters:\n');
fprintf('a1 = %.6f\n', a1_disc);
fprintf('a0 = %.6f\n', a0_disc);
fprintf('b1 = %.6f\n', b1_disc);
fprintf('b0 = %.6f\n\n', b0_disc);

% Input signal - white noise for better excitation
u = randn(N,1);

% Output signal initialization
y = zeros(N,1);

% Generate output data
for k = 3:N
    y(k) = a1_disc*y(k-1) + a0_disc*y(k-2) + b1_disc*u(k-1) + b0_disc*u(k-2);
end

% Add output noise
noise_level = 0.01;
y_noisy = y + noise_level*randn(N,1);

% RLS algorithm for continuous system identification
% Initial parameter estimates
theta = zeros(N-2, 4);   % [a1, a0, b1, b0]
theta(1,:) = [0, 0, 0, 0];

% Initial covariance matrix
P = zeros(4, 4, N-2);
P(:,:,1) = 100*eye(4);

% Forgetting factor
lambda = 0.98;

% Estimation loop
for k = 2:N-2
    % Regressor vector
    phi = [y_noisy(k+1); y_noisy(k); u(k+1); u(k)];
    
    % Prediction error
    epsilon = y_noisy(k+2) - phi' * theta(k-1,:)';
    
    % Gain calculation
    K = P(:,:,k-1) * phi / (lambda + phi' * P(:,:,k-1) * phi);
    
    % Parameter update
    theta(k,:) = theta(k-1,:) + (K * epsilon)';
    
    % Covariance matrix update
    P(:,:,k) = (P(:,:,k-1) - K * phi' * P(:,:,k-1)) / lambda;
end

% Display final parameter estimates
fprintf('Continuous System G2 - Fixed Parameters Results (λ = %.2f):\n', lambda);
fprintf('True parameters: a1=%.6f, a0=%.6f, b1=%.6f, b0=%.6f\n', a1_disc, a0_disc, b1_disc, b0_disc);
fprintf('Final estimated parameters: a1=%.6f, a0=%.6f, b1=%.6f, b0=%.6f\n', theta(end,1), theta(end,2), theta(end,3), theta(end,4));
fprintf('Parameter estimation errors: a1=%.6f, a0=%.6f, b1=%.6f, b0=%.6f\n\n', ...
    abs(a1_disc-theta(end,1)), abs(a0_disc-theta(end,2)), abs(b1_disc-theta(end,3)), abs(b0_disc-theta(end,4)));

% Plot results
figure(1)
plot(t(3:N), theta(:,1), 'r-', t(3:N), theta(:,2), 'g-', ...
     t(3:N), theta(:,3), 'b-', t(3:N), theta(:,4), 'm-', 'LineWidth', 2);
hold on;
plot(t(3:N), a1_disc*ones(size(t(3:N))), 'r--', ...
     t(3:N), a0_disc*ones(size(t(3:N))), 'g--', ...
     t(3:N), b1_disc*ones(size(t(3:N))), 'b--', ...
     t(3:N), b0_disc*ones(size(t(3:N))), 'm--', 'LineWidth', 1);
hold off;
xlabel('Time [s]');
ylabel('Parameter values');
legend('Estimated a_1', 'Estimated a_0', 'Estimated b_1', 'Estimated b_0', ...
       'True a_1', 'True a_0', 'True b_1', 'True b_0');
title('Parameter Estimation for Continuous System G2 (Discretized)');
grid on;
saveas(gcf, 'G2_parameter_estimation.png');

% Plot diagonal elements of P matrix
figure(2)
plot(t(3:N), squeeze(P(1,1,:)), 'r-', ...
     t(3:N), squeeze(P(2,2,:)), 'g-', ...
     t(3:N), squeeze(P(3,3,:)), 'b-', ...
     t(3:N), squeeze(P(4,4,:)), 'm-', 'LineWidth', 2);
xlabel('Time [s]');
ylabel('P matrix diagonal elements');
legend('P(1,1)', 'P(2,2)', 'P(3,3)', 'P(4,4)');
title('Covariance Matrix Diagonal Elements');
grid on;
saveas(gcf, 'G2_covariance_matrix.png');

%% Time-varying parameters for continuous system
% Reset
clear all;
close all;

% Simulation parameters
T = 0.01;
t_end = 40;
t = 0:T:t_end;
N = length(t);

% Initial continuous system 
num1 = [1 1];
den1 = [1 2 3];
sys_cont1 = tf(num1, den1);
sys_disc1 = c2d(sys_cont1, T, 'zoh');
[num_d1, den_d1] = tfdata(sys_disc1, 'v');

% System after parameter change
num2 = [1 2];  % Changing numerator coefficient from 1 to 2
den2 = [1 2 3];
sys_cont2 = tf(num2, den2);
sys_disc2 = c2d(sys_cont2, T, 'zoh');
[num_d2, den_d2] = tfdata(sys_disc2, 'v');

% Initialize parameters arrays
a1 = zeros(N,1);
a0 = zeros(N,1);
b1 = zeros(N,1);
b0 = zeros(N,1);

% Fill parameters
change_time = 20;
change_index = find(t >= change_time, 1);

% First system parameters
a1(1:change_index-1) = -den_d1(2);
a0(1:change_index-1) = -den_d1(3);
b1(1:change_index-1) = num_d1(2);
b0(1:change_index-1) = num_d1(3);

% Second system parameters
a1(change_index:end) = -den_d2(2);
a0(change_index:end) = -den_d2(3);
b1(change_index:end) = num_d2(2);
b0(change_index:end) = num_d2(3);

% Display the change in parameters
fprintf('Time-Varying Continuous System G2:\n');
fprintf('System parameters before t = %.1f seconds:\n', change_time);
fprintf('a1 = %.6f, a0 = %.6f, b1 = %.6f, b0 = %.6f\n', a1(1), a0(1), b1(1), b0(1));
fprintf('System parameters after t = %.1f seconds:\n', change_time);
fprintf('a1 = %.6f, a0 = %.6f, b1 = %.6f, b0 = %.6f\n\n', a1(end), a0(end), b1(end), b0(end));

% Input signal - white noise
u = randn(N,1);

% Output signal initialization
y = zeros(N,1);

% Generate output data with time-varying parameters
for k = 3:N
    y(k) = a1(k)*y(k-1) + a0(k)*y(k-2) + b1(k)*u(k-1) + b0(k)*u(k-2);
end

% Add noise
noise_level = 0.01;
y_noisy = y + noise_level*randn(N,1);

% RLS algorithm with forgetting factor
theta = zeros(N-2, 4);
theta(1,:) = [0, 0, 0, 0];

P = zeros(4, 4, N-2);
P(:,:,1) = 100*eye(4);

% Test different forgetting factors
lambda = 0.95;

for k = 2:N-2
    phi = [y_noisy(k+1); y_noisy(k); u(k+1); u(k)];
    epsilon = y_noisy(k+2) - phi' * theta(k-1,:)';
    K = P(:,:,k-1) * phi / (lambda + phi' * P(:,:,k-1) * phi);
    theta(k,:) = theta(k-1,:) + (K * epsilon)';
    P(:,:,k) = (P(:,:,k-1) - K * phi' * P(:,:,k-1)) / lambda;
end

% Display results for time-varying system
fprintf('Time-Varying System Results (λ = %.2f):\n', lambda);
fprintf('Final true parameters: a1=%.6f, a0=%.6f, b1=%.6f, b0=%.6f\n', a1(end), a0(end), b1(end), b0(end));
fprintf('Final estimated parameters: a1=%.6f, a0=%.6f, b1=%.6f, b0=%.6f\n', theta(end,1), theta(end,2), theta(end,3), theta(end,4));
fprintf('Parameter estimation errors: a1=%.6f, a0=%.6f, b1=%.6f, b0=%.6f\n\n', ...
    abs(a1(end)-theta(end,1)), abs(a0(end)-theta(end,2)), abs(b1(end)-theta(end,3)), abs(b0(end)-theta(end,4)));

% Plot results for time-varying continuous system
figure(3)
plot(t(3:N), theta(:,1), 'r-', t(3:N), theta(:,2), 'g-', ...
     t(3:N), theta(:,3), 'b-', t(3:N), theta(:,4), 'm-', 'LineWidth', 2);
hold on;
plot(t(3:N), a1(3:N), 'r--', t(3:N), a0(3:N), 'g--', ...
     t(3:N), b1(3:N), 'b--', t(3:N), b0(3:N), 'm--', 'LineWidth', 1);
hold off;
xlabel('Time [s]');
ylabel('Parameter values');
legend('Estimated a_1', 'Estimated a_0', 'Estimated b_1', 'Estimated b_0', ...
       'True a_1', 'True a_0', 'True b_1', 'True b_0');
title(['Time-Varying Continuous System Parameters (λ = ', num2str(lambda), ')']);
grid on;
saveas(gcf, sprintf('G2_time_varying_lambda_%.2f.png', lambda));

% Plot diagonal elements of P matrix
figure(4)
plot(t(3:N), squeeze(P(1,1,:)), 'r-', ...
     t(3:N), squeeze(P(2,2,:)), 'g-', ...
     t(3:N), squeeze(P(3,3,:)), 'b-', ...
     t(3:N), squeeze(P(4,4,:)), 'm-', 'LineWidth', 2);
xlabel('Time [s]');
ylabel('P matrix diagonal elements');
legend('P(1,1)', 'P(2,2)', 'P(3,3)', 'P(4,4)');
title(['Covariance Matrix Diagonal Elements (λ = ', num2str(lambda), ')']);
grid on;
saveas(gcf, sprintf('G2_time_varying_covariance_lambda_%.2f.png', lambda));

% Compare different forgetting factors
lambdas = [0.90, 0.95, 0.98];
figure(5);
hold on;

for i = 1:length(lambdas)
    lambda = lambdas(i);
    
    % Reset and recalculate with this lambda
    theta_lambda = zeros(N-2, 4);
    theta_lambda(1,:) = [0, 0, 0, 0];
    
    P_lambda = zeros(4, 4, N-2);
    P_lambda(:,:,1) = 100*eye(4);
    
    for k = 2:N-2
        phi = [y_noisy(k+1); y_noisy(k); u(k+1); u(k)];
        epsilon = y_noisy(k+2) - phi' * theta_lambda(k-1,:)';
        K = P_lambda(:,:,k-1) * phi / (lambda + phi' * P_lambda(:,:,k-1) * phi);
        theta_lambda(k,:) = theta_lambda(k-1,:) + (K * epsilon)';
        P_lambda(:,:,k) = (P_lambda(:,:,k-1) - K * phi' * P_lambda(:,:,k-1)) / lambda;
    end
    
    % Only plot b1 as it changes at t=20
    plot(t(3:N), theta_lambda(:,3), 'LineWidth', 2);
    
    % Print results for this lambda
    fprintf('Results for λ = %.2f:\n', lambda);
    fprintf('Final b1 estimation: %.6f (True b1: %.6f, Error: %.6f)\n', ...
        theta_lambda(end,3), b1(end), abs(b1(end)-theta_lambda(end,3)));
end

plot(t(3:N), b1(3:N), 'k--', 'LineWidth', 2);
hold off;
xlabel('Time [s]');
ylabel('b1 Parameter Value');
legend('\lambda = 0.90', '\lambda = 0.95', '\lambda = 0.98', 'True b1');
title('Effect of Different Forgetting Factors on b1 Tracking');
grid on;
saveas(gcf, 'G2_forgetting_factor_comparison.png');

fprintf('All figures have been saved as PNG files.\n');