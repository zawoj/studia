% Identyfikacja wybranego parametru dla układu dwuwymiarowego
% z użyciem algorytmu filtru Kalmana

clear all;
close all;
clc;

% Simulation parameters
T_s = 0.1;     % Sample time
t_end = 30;    % Simulation end time
t = 0:T_s:t_end;
N = length(t);

% System matrices
A = [0.99  0.095; 
    -0.19  0.9];
B = [0.005; 
     0.095];
C = [1 0];
D = [0];

% Let's select a11 (first element of A matrix) as the parameter to identify
a11_true = A(1,1);

% System dimensions
n = size(A, 1);  % State dimension
m = size(C, 1);  % Output dimension

% Input signal - random uniform values between -1 and 1
u = 2*rand(N,1) - 1;

% Noise covariance matrices
Q = [0.0005 0; 0 0.0005];  % System noise covariance
R = 0.0001;                 % Measurement noise covariance

% Initialize state and output
x = zeros(n, N);
y = zeros(m, N);

% Generate system states and noisy measurements
for k = 1:N-1
    % System noise
    w = mvnrnd([0 0], Q)';
    
    % State update
    x(:, k+1) = A * x(:, k) + B * u(k) + w;
    
    % Measurement noise
    v = sqrt(R) * randn;
    
    % Output
    y(:, k) = C * x(:, k) + v;
end
y(:, N) = C * x(:, N) + sqrt(R) * randn;  % Last measurement

% Kalman filter for parameter identification
% We'll identify a11 (first element of A matrix)

% Augmented state: [x; a11]
% Augmented system:
% [x(k+1); a11(k+1)] = [A(a11), 0; 0, 1] * [x(k); a11(k)] + [B; 0] * u(k) + [w; w_a]
% y(k) = [C, 0] * [x(k); a11(k)] + v(k)

% Test different values of q_a (parameter dynamics noise variance)
q_a_values = [0.0001, 0.001, 0.01];

for qi = 1:length(q_a_values)
    q_a = q_a_values(qi);
    
    % Initialize augmented state and covariance
    x_aug = zeros(n+1, N);  % [x; a11]
    P_aug = zeros(n+1, n+1, N);
    
    % Initial values
    x_aug(:, 1) = [x(:, 1); 0.5];  % Initial guess for a11 is 0.5
    P_aug(:,:, 1) = diag([0.1, 0.1, 1]);  % High initial uncertainty for parameter
    
    % Augmented system matrices
    % Note: A_aug will be constructed at each step with the current a11 estimate
    B_aug = [B; 0];
    C_aug = [C, 0];
    
    % Augmented noise covariance
    Q_aug = blkdiag(Q, q_a);
    
    % Kalman filter loop
    for k = 1:N-1
        % Current a11 estimate
        a11_hat = x_aug(3, k);
        
        % Construct augmented A matrix with current a11 estimate
        A_hat = [a11_hat, A(1,2); A(2,1), A(2,2)];
        A_aug = [A_hat, zeros(n,1); zeros(1,n), 1];
        
        % Prediction step
        x_minus = A_aug * x_aug(:, k) + B_aug * u(k);
        P_minus = A_aug * P_aug(:,:, k) * A_aug' + Q_aug;
        
        % Kalman gain calculation
        K = P_minus * C_aug' / (C_aug * P_minus * C_aug' + R);
        
        % Update step
        x_aug(:, k+1) = x_minus + K * (y(:, k+1) - C_aug * x_minus);
        P_aug(:,:, k+1) = (eye(n+1) - K * C_aug) * P_minus;
    end
    
    % Extract parameter estimates
    a11_est = x_aug(3, :);
    
    % Plot results for this q_a value
    figure(qi);
    plot(t, a11_est, 'b-', t, a11_true*ones(size(t)), 'r--', 'LineWidth', 2);
    xlabel('Time [s]');
    ylabel('Parameter a_{11} estimate');
    legend(['Estimated a_{11} (q_a = ', num2str(q_a), ')'], 'True a_{11}');
    title(['Parameter Identification with q_a = ', num2str(q_a)]);
    grid on;
    saveas(gcf, sprintf('zad2_qa_%.4f.png', q_a));
    
    % Print final estimation error
    fprintf('q_a = %.4f: Final a11 estimate = %.4f, True a11 = %.4f, Error = %.4f\n', ...
        q_a, a11_est(end), a11_true, abs(a11_true - a11_est(end)));
end

%% Test different system noise levels
% Keep q_a fixed at a moderate value
q_a = 0.001;

% Test different system noise covariance matrices
Q_values = {
    [0.00005 0; 0 0.00005],  % Low system noise
    [0.0005 0; 0 0.0005],    % Medium system noise (default)
    [0.005 0; 0 0.005]       % High system noise
};

figure(length(q_a_values) + 1);
hold on;

for qi = 1:length(Q_values)
    Q = Q_values{qi};
    
    % Generate system states and noisy measurements with this Q
    x = zeros(n, N);
    y = zeros(m, N);
    
    for k = 1:N-1
        % System noise
        w = mvnrnd([0 0], Q)';
        
        % State update
        x(:, k+1) = A * x(:, k) + B * u(k) + w;
        
        % Measurement noise
        v = sqrt(R) * randn;
        
        % Output
        y(:, k) = C * x(:, k) + v;
    end
    y(:, N) = C * x(:, N) + sqrt(R) * randn;
    
    % Initialize augmented state and covariance
    x_aug = zeros(n+1, N);
    P_aug = zeros(n+1, n+1, N);
    
    % Initial values
    x_aug(:, 1) = [x(:, 1); 0.5];
    P_aug(:,:, 1) = diag([0.1, 0.1, 1]);
    
    % Augmented system matrices
    B_aug = [B; 0];
    C_aug = [C, 0];
    
    % Augmented noise covariance
    Q_aug = blkdiag(Q, q_a);
    
    % Kalman filter loop
    for k = 1:N-1
        % Current a11 estimate
        a11_hat = x_aug(3, k);
        
        % Construct augmented A matrix with current a11 estimate
        A_hat = [a11_hat, A(1,2); A(2,1), A(2,2)];
        A_aug = [A_hat, zeros(n,1); zeros(1,n), 1];
        
        % Prediction step
        x_minus = A_aug * x_aug(:, k) + B_aug * u(k);
        P_minus = A_aug * P_aug(:,:, k) * A_aug' + Q_aug;
        
        % Kalman gain calculation
        K = P_minus * C_aug' / (C_aug * P_minus * C_aug' + R);
        
        % Update step
        x_aug(:, k+1) = x_minus + K * (y(:, k+1) - C_aug * x_minus);
        P_aug(:,:, k+1) = (eye(n+1) - K * C_aug) * P_minus;
    end
    
    % Extract parameter estimates
    a11_est = x_aug(3, :);
    
    % Plot results for this Q
    plot(t, a11_est, 'LineWidth', 2);
    
    % Print final estimation error
    Q_magnitude = Q(1,1);
    fprintf('System noise Q = %.5f: Final a11 estimate = %.4f, Error = %.4f\n', ...
        Q_magnitude, a11_est(end), abs(a11_true - a11_est(end)));
end

% Add reference line
plot(t, a11_true*ones(size(t)), 'k--', 'LineWidth', 2);

xlabel('Time [s]');
ylabel('Parameter a_{11} estimate');
legend_labels = {};
for qi = 1:length(Q_values)
    Q_magnitude = Q_values{qi}(1,1);
    legend_labels{qi} = ['Q = ', num2str(Q_magnitude)];
end
legend_labels{length(Q_values) + 1} = 'True a_{11}';
legend(legend_labels);
title(['Parameter Identification with Different System Noise Levels (q_a = ', num2str(q_a), ')']);
grid on;
hold off;
saveas(gcf, 'zad2_different_system_noise.png');

%% Test different measurement noise levels
% Keep q_a and Q fixed
q_a = 0.001;
Q = [0.0005 0; 0 0.0005];  % Default system noise

% Test different measurement noise variances
R_values = [0.00001, 0.0001, 0.001];

figure(length(q_a_values) + 2);
hold on;

for ri = 1:length(R_values)
    R = R_values(ri);
    
    % Generate system states and noisy measurements with this R
    x = zeros(n, N);
    y = zeros(m, N);
    
    for k = 1:N-1
        % System noise
        w = mvnrnd([0 0], Q)';
        
        % State update
        x(:, k+1) = A * x(:, k) + B * u(k) + w;
        
        % Measurement noise
        v = sqrt(R) * randn;
        
        % Output
        y(:, k) = C * x(:, k) + v;
    end
    y(:, N) = C * x(:, N) + sqrt(R) * randn;
    
    % Initialize augmented state and covariance
    x_aug = zeros(n+1, N);
    P_aug = zeros(n+1, n+1, N);
    
    % Initial values
    x_aug(:, 1) = [x(:, 1); 0.5];
    P_aug(:,:, 1) = diag([0.1, 0.1, 1]);
    
    % Augmented system matrices
    B_aug = [B; 0];
    C_aug = [C, 0];
    
    % Augmented noise covariance
    Q_aug = blkdiag(Q, q_a);
    
    % Kalman filter loop
    for k = 1:N-1
        % Current a11 estimate
        a11_hat = x_aug(3, k);
        
        % Construct augmented A matrix with current a11 estimate
        A_hat = [a11_hat, A(1,2); A(2,1), A(2,2)];
        A_aug = [A_hat, zeros(n,1); zeros(1,n), 1];
        
        % Prediction step
        x_minus = A_aug * x_aug(:, k) + B_aug * u(k);
        P_minus = A_aug * P_aug(:,:, k) * A_aug' + Q_aug;
        
        % Kalman gain calculation
        K = P_minus * C_aug' / (C_aug * P_minus * C_aug' + R);
        
        % Update step
        x_aug(:, k+1) = x_minus + K * (y(:, k+1) - C_aug * x_minus);
        P_aug(:,:, k+1) = (eye(n+1) - K * C_aug) * P_minus;
    end
    
    % Extract parameter estimates
    a11_est = x_aug(3, :);
    
    % Plot results for this R
    plot(t, a11_est, 'LineWidth', 2);
    
    % Print final estimation error
    fprintf('Measurement noise R = %.5f: Final a11 estimate = %.4f, Error = %.4f\n', ...
        R, a11_est(end), abs(a11_true - a11_est(end)));
end

% Add reference line
plot(t, a11_true*ones(size(t)), 'k--', 'LineWidth', 2);

xlabel('Time [s]');
ylabel('Parameter a_{11} estimate');
legend_labels = {};
for ri = 1:length(R_values)
    legend_labels{ri} = ['R = ', num2str(R_values(ri))];
end
legend_labels{length(R_values) + 1} = 'True a_{11}';
legend(legend_labels);
title(['Parameter Identification with Different Measurement Noise Levels (q_a = ', num2str(q_a), ')']);
grid on;
hold off;
saveas(gcf, 'zad2_different_measurement_noise.png');

fprintf('All figures have been saved as PNG files.\n');
