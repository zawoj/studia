% Online identification of discrete system G1
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

% Input signal - white noise for better excitation
u = randn(N,1);

% Output signal initialization
y = zeros(N,1);

% Generate output data
for k = 3:N
    y(k) = -a1_true*y(k-1) - a0_true*y(k-2) + b1_true*u(k-1) + b0_true*u(k-2);
end

% Add output noise - test robustness
noise_level = 0.01;
y_noisy = y + noise_level*randn(N,1);

% RLS algorithm implementation
% Initial parameter estimates - arbitrary values
theta = zeros(N-2, 4);   % [a1, a0, b1, b0]
theta(1,:) = [0, 0, 0, 0];

% Initial covariance matrix
P = zeros(4, 4, N-2);
P(:,:,1) = 100*eye(4);   % High initial uncertainty

% Forgetting factor
lambda = 0.98;

% Estimation loop
for k = 2:N-2
    % Regressor vector
    phi = [-y_noisy(k+1); -y_noisy(k); u(k+1); u(k)];
    
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
plot(t(3:N), a1_true*ones(size(t(3:N))), 'r--', ...
     t(3:N), a0_true*ones(size(t(3:N))), 'g--', ...
     t(3:N), b1_true*ones(size(t(3:N))), 'b--', ...
     t(3:N), b0_true*ones(size(t(3:N))), 'm--', 'LineWidth', 1);
hold off;
xlabel('Time [s]');
ylabel('Parameter values');
legend('Estimated a_1', 'Estimated a_0', 'Estimated b_1', 'Estimated b_0', ...
       'True a_1', 'True a_0', 'True b_1', 'True b_0');
title('Parameter Estimation for Discrete System G1');
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

%% Time-varying parameters test
% Reset
clear all;
close all;

% Simulation parameters
T = 0.1;
t_end = 40;
t = 0:T:t_end;
N = length(t);

% Initialize parameters
a1 = 0.3 * ones(N,1);
a0 = 0.4 * ones(N,1);
b1 = 0.1 * ones(N,1);
b0 = 0.2 * ones(N,1);

% Create parameter changes
change_time = 20;
change_index = find(t >= change_time, 1);
b0(change_index:end) = 0.5;  % Parameter b0 changes from 0.2 to 0.5 at t=20

% Input signal - white noise
u = randn(N,1);

% Output signal initialization
y = zeros(N,1);

% Generate output data with time-varying parameters
for k = 3:N
    y(k) = -a1(k)*y(k-1) - a0(k)*y(k-2) + b1(k)*u(k-1) + b0(k)*u(k-2);
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
lambda = 0.95;  % Try also with 0.98, 0.90

for k = 2:N-2
    phi = [-y_noisy(k+1); -y_noisy(k); u(k+1); u(k)];
    epsilon = y_noisy(k+2) - phi' * theta(k-1,:)';
    K = P(:,:,k-1) * phi / (lambda + phi' * P(:,:,k-1) * phi);
    theta(k,:) = theta(k-1,:) + (K * epsilon)';
    P(:,:,k) = (P(:,:,k-1) - K * phi' * P(:,:,k-1)) / lambda;
end

% Plot results for time-varying system
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
title(['Parameter Estimation for Time-Varying System (λ = ', num2str(lambda), ')']);
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