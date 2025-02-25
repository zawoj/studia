% Prosta implementacja zadania 3: Dyskretyzacja układów 1, 2, 3 rzędu
clear all; close all; clc;

if ~exist('zad3', 'dir')
    mkdir('zad3');
end

% Parametry
Ts = 0.5; % Okres próbkowania
t_continuous = 0:0.01:10; % Czas ciągły
t_discrete = 0:Ts:10;     % Czas dyskretny

% Definicja układów
sys1 = tf(1, [1 3]);              % G1(s) = 1/(s + 3)
sys2 = tf([1 1], [1 2 3]);       % G2(s) = (s + 1)/(s^2 + 2s + 3)
sys3 = tf([1 2], [1 2 1 1]);     % G3(s) = (s + 2)/(s^3 + 2s^2 + s + 1)

systems = {sys1, sys2, sys3};
titles = {'1. rzędu', '2. rzędu', '3. rzędu'};

% Pętla po układach
for i = 1:length(systems)
    sys_continuous = systems{i};
    
    % Dyskretyzacja metodami odpowiedzi
    sys_impulse = c2d(sys_continuous, Ts, 'impulse'); % Odpowiednik impulsowy
    sys_zoh = c2d(sys_continuous, Ts, 'zoh');        % Odpowiednik skokowy (ZOH)
    sys_foh = c2d(sys_continuous, Ts, 'foh');        % Odpowiednik liniowo-narastający (FOH)
    
    % Odpowiedź impulsowa
    y_cont_impulse = impulse(sys_continuous, t_continuous);
    y_impulse = impulse(sys_impulse, t_discrete);
    y_zoh_impulse = impulse(sys_zoh, t_discrete);
    y_foh_impulse = impulse(sys_foh, t_discrete);
    
figure('Position', [100 100 800 400]);
plot(t_continuous, y_cont_impulse, 'k-', 'LineWidth', 2, 'DisplayName', 'Ciągły');
hold on;
stairs(t_discrete, y_impulse, 'r--', 'LineWidth', 2, 'DisplayName', 'Impulsowy');
stairs(t_discrete, y_zoh_impulse, 'b--', 'LineWidth', 2, 'DisplayName', 'ZOH');
stairs(t_discrete, y_foh_impulse, 'g--', 'LineWidth', 2, 'DisplayName', 'FOH');
xlabel('Czas [s]');
ylabel('Wyjście');
title(['Odpowiedź impulsowa, ', titles{i}, ', T = 0.5 s']);
legend;
grid on;
hold off;
saveas(gcf, fullfile('zad3', ['Impulsowa_', titles{i}, '.png']), 'png');
    
    % Odpowiedź skokowa
    y_cont_step = step(sys_continuous, t_continuous);
    y_impulse_step = step(sys_impulse, t_discrete);
    y_zoh_step = step(sys_zoh, t_discrete);
    y_foh_step = step(sys_foh, t_discrete);
    
figure('Position', [100 100 800 400]);
plot(t_continuous, y_cont_step, 'k-', 'LineWidth', 2, 'DisplayName', 'Ciągły');
hold on;
stairs(t_discrete, y_impulse_step, 'r--', 'LineWidth', 2, 'DisplayName', 'Impulsowy');
stairs(t_discrete, y_zoh_step, 'b--', 'LineWidth', 2, 'DisplayName', 'ZOH');
stairs(t_discrete, y_foh_step, 'g--', 'LineWidth', 2, 'DisplayName', 'FOH');
xlabel('Czas [s]');
ylabel('Wyjście');
title(['Odpowiedź skokowa, ', titles{i}, ', T = 0.5 s']);
legend;
grid on;
hold off;
saveas(gcf, fullfile('zad3', ['Skokowa_', titles{i}, '.png']), 'png');
    
    % Odpowiedź na sygnał liniowo-narastający
    u_ramp_cont = t_continuous; % Sygnał liniowy dla czasu ciągłego: u(t) = t
    u_ramp_disc = t_discrete;   % Sygnał liniowy dla czasu dyskretnego
    y_cont_ramp = lsim(sys_continuous, u_ramp_cont, t_continuous);
    y_impulse_ramp = lsim(sys_impulse, u_ramp_disc, t_discrete);
    y_zoh_ramp = lsim(sys_zoh, u_ramp_disc, t_discrete);
    y_foh_ramp = lsim(sys_foh, u_ramp_disc, t_discrete);
    
figure('Position', [100 100 800 400]);
plot(t_continuous, y_cont_ramp, 'k-', 'LineWidth', 2, 'DisplayName', 'Ciągły');
hold on;
stairs(t_discrete, y_impulse_ramp, 'r--', 'LineWidth', 2, 'DisplayName', 'Impulsowy');
stairs(t_discrete, y_zoh_ramp, 'b--', 'LineWidth', 2, 'DisplayName', 'ZOH');
stairs(t_discrete, y_foh_ramp, 'g--', 'LineWidth', 2, 'DisplayName', 'FOH');
xlabel('Czas [s]');
ylabel('Wyjście');
title(['Odpowiedź na sygnał liniowy, ', titles{i}, ', T = 0.5 s']);
legend;
grid on;
hold off;
saveas(gcf, fullfile('zad3', ['Liniowa_', titles{i}, '.png']), 'png');
end

disp('Wykresy dla zadania 3 wygenerowane.');