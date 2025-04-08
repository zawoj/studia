% Identyfikacja parametru a_k jednowymiarowego układu liniowego
% z użyciem algorytmu filtru Kalmana

clear all;
close all;
clc;

% Simulation parameters
T = 0.1;      % Sample time
t_end = 20;   % Simulation end time
t = 0:T:t_end;
N = length(t);

% System model: x(k+1) = a_k * x(k) + w(k)
% Measurement: y(k) = x(k) + v(k)

% Set true parameter to identify
a_true = 0.8;  % Default value, will be varied in tests

% Input signal - random uniform values between -1 and 1
u = 2*rand(N,1) - 1;

% Variance of system and measurement noise
q_w = 0.01;  % System noise variance
r_v = 0.01;  % Measurement noise variance

% Generate system output
x = zeros(N,1);
y = zeros(N,1);

% Initial condition
x(1) = 0;

% Generate system states and noisy measurements
for k = 1:N-1
    % System noise
    w = sqrt(q_w)*randn;
    
    % State update
    x(k+1) = a_true * x(k) + u(k) + w;
    
    % Measurement noise
    v = sqrt(r_v)*randn;
    
    % Measurement
    y(k) = x(k) + v;
end
y(N) = x(N) + sqrt(r_v)*randn;  % Last measurement

% Kalman filter for parameter identification
% We treat a_k as a state to be estimated

% Initialize parameter estimate and error covariance
a_hat = zeros(N,1);
P = zeros(N,1);

% Initial guesses
a_hat(1) = 0;     % Initial parameter estimate
P(1) = 1;         % Initial error covariance

% Test different values of q_a
q_a_values = [0.001, 0.01, 0.1];

for qi = 1:length(q_a_values)
    q_a = q_a_values(qi);
    
    % Reset estimates for this test
    a_hat = zeros(N,1);
    P = zeros(N,1);
    
    % Initial guesses
    a_hat(1) = 0;
    P(1) = 1;
    
    % Kalman filter loop
    for k = 1:N-1
        % Prediction step
        a_hat_minus = a_hat(k);
        P_minus = P(k) + q_a;
        
        % Kalman gain calculation
        K = P_minus * x(k) / (x(k)^2 * P_minus + q_w + r_v);
        
        % Update step
        a_hat(k+1) = a_hat_minus + K * (y(k+1) - a_hat_minus * x(k) - u(k));
        P(k+1) = (1 - K * x(k)) * P_minus;
    end
    
    % Plot results for this q_a value
    figure(qi);
    plot(t, a_hat, 'b-', t, a_true*ones(size(t)), 'r--', 'LineWidth', 2);
    xlabel('Time [s]');
    ylabel('Parameter estimate');
    legend(['Estimated a_k (q_a = ', num2str(q_a), ')'], 'True a_k');
    title(['Parameter Identification with q_a = ', num2str(q_a)]);
    grid on;
    saveas(gcf, sprintf('zad1_qa_%.4f.png', q_a));
    
    % Print final estimation error
    fprintf('q_a = %.4f: Final a_k estimate = %.4f, True a_k = %.4f, Error = %.4f\n', ...
        q_a, a_hat(end), a_true, abs(a_true - a_hat(end)));
end

%% Test different true parameter values
a_true_values = [0.5, 0.8, 0.95];
q_a = 0.01;  % Use a fixed q_a value

figure(length(q_a_values) + 1);
hold on;

for ai = 1:length(a_true_values)
    a_true = a_true_values(ai);
    
    % Generate system output for this a_true
    x = zeros(N,1);
    y = zeros(N,1);
    x(1) = 0;
    
    for k = 1:N-1
        w = sqrt(q_w)*randn;
        x(k+1) = a_true * x(k) + u(k) + w;
        v = sqrt(r_v)*randn;
        y(k) = x(k) + v;
    end
    y(N) = x(N) + sqrt(r_v)*randn;
    
    % Reset estimates
    a_hat = zeros(N,1);
    P = zeros(N,1);
    a_hat(1) = 0;
    P(1) = 1;
    
    % Kalman filter loop
    for k = 1:N-1
        % Prediction step
        a_hat_minus = a_hat(k);
        P_minus = P(k) + q_a;
        
        % Kalman gain calculation
        K = P_minus * x(k) / (x(k)^2 * P_minus + q_w + r_v);
        
        % Update step
        a_hat(k+1) = a_hat_minus + K * (y(k+1) - a_hat_minus * x(k) - u(k));
        P(k+1) = (1 - K * x(k)) * P_minus;
    end
    
    % Plot results for this a_true value
    plot(t, a_hat, 'LineWidth', 2);
    
    % Print final estimation error
    fprintf('a_true = %.2f: Final a_k estimate = %.4f, Error = %.4f\n', ...
        a_true, a_hat(end), abs(a_true - a_hat(end)));
end

% Add reference lines
for ai = 1:length(a_true_values)
    plot(t, a_true_values(ai)*ones(size(t)), '--', 'LineWidth', 1);
end

xlabel('Time [s]');
ylabel('Parameter estimate');
legend_labels = {};
for ai = 1:length(a_true_values)
    legend_labels{ai} = ['Estimated a_k (a_{true} = ', num2str(a_true_values(ai)), ')'];
end
for ai = 1:length(a_true_values)
    legend_labels{ai+length(a_true_values)} = ['True a_k = ', num2str(a_true_values(ai))];
end
legend(legend_labels);
title('Parameter Identification for Different True Values');
grid on;
hold off;
saveas(gcf, 'zad1_different_a_true.png');

%% Test different noise levels
a_true = 0.8;  % Fixed true parameter
q_a = 0.01;    % Fixed q_a

% Pairs of [q_w, r_v] to test
noise_pairs = [
    0.001, 0.001;  % Low system and measurement noise
    0.01, 0.01;    % Medium system and measurement noise
    0.1, 0.1       % High system and measurement noise
];

figure(length(q_a_values) + 2);
hold on;

for ni = 1:size(noise_pairs, 1)
    q_w = noise_pairs(ni, 1);
    r_v = noise_pairs(ni, 2);
    
    % Generate system output for these noise levels
    x = zeros(N,1);
    y = zeros(N,1);
    x(1) = 0;
    
    for k = 1:N-1
        w = sqrt(q_w)*randn;
        x(k+1) = a_true * x(k) + u(k) + w;
        v = sqrt(r_v)*randn;
        y(k) = x(k) + v;
    end
    y(N) = x(N) + sqrt(r_v)*randn;
    
    % Reset estimates
    a_hat = zeros(N,1);
    P = zeros(N,1);
    a_hat(1) = 0;
    P(1) = 1;
    
    % Kalman filter loop
    for k = 1:N-1
        % Prediction step
        a_hat_minus = a_hat(k);
        P_minus = P(k) + q_a;
        
        % Kalman gain calculation
        K = P_minus * x(k) / (x(k)^2 * P_minus + q_w + r_v);
        
        % Update step
        a_hat(k+1) = a_hat_minus + K * (y(k+1) - a_hat_minus * x(k) - u(k));
        P(k+1) = (1 - K * x(k)) * P_minus;
    end
    
    % Plot results for these noise levels
    plot(t, a_hat, 'LineWidth', 2);
    
    % Print final estimation error
    fprintf('q_w = %.4f, r_v = %.4f: Final a_k estimate = %.4f, Error = %.4f\n', ...
        q_w, r_v, a_hat(end), abs(a_true - a_hat(end)));
end

% Add reference line for true parameter
plot(t, a_true*ones(size(t)), 'k--', 'LineWidth', 2);

xlabel('Time [s]');
ylabel('Parameter estimate');
legend_labels = {};
for ni = 1:size(noise_pairs, 1)
    legend_labels{ni} = ['q_w = r_v = ', num2str(noise_pairs(ni, 1))];
end
legend_labels{size(noise_pairs, 1) + 1} = 'True a_k';
legend(legend_labels);
title('Parameter Identification with Different Noise Levels');
grid on;
hold off;
saveas(gcf, 'zad1_different_noise_levels.png');

fprintf('All figures have been saved as PNG files.\n');
