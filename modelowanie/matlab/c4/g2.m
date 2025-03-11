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
disp('Discrete equivalent parameters:');
disp(['a1 = ' num2str(a1_disc)]);
disp(['a0 = ' num2str(a0_disc)]);
disp(['b1 = ' num2str(b1_disc)]);
disp(['b0 = ' num2str(b0_disc)]);

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