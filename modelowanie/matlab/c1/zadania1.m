% Prosta implementacja zadania 1: Dyskretyzacja układu 1/(s^2 + 1)
clear all; close all; clc;

if ~exist('zad1', 'dir')
    mkdir('zad1');
end

% Parametry
Ts_values = [1, 0.5, 0.1]; % Okresy próbkowania
sys_continuous = tf(1, [1 0 1]); % G(s) = 1/(s^2 + 1)

% Pętla po okresach próbkowania
for i = 1:length(Ts_values)
    Ts = Ts_values(i);
    t_continuous = 0:0.01:10; % Czas ciągły
    t_discrete = 0:Ts:10;     % Czas dyskretny
    
    % Odpowiedź skokowa układu ciągłego
    y_continuous = step(sys_continuous, t_continuous);
    
    % Dyskretyzacja metodami aproksymacji pochodnej
    % Różnica wprzód: s = (z-1)/Ts -> G(z) = 1/((z-1)^2/Ts^2 + 1)
    den_forward = [1 -2 1]/Ts^2 + [0 0 1]; % (z-1)^2 = z^2 - 2z + 1
    sys_forward = tf([1], den_forward, Ts);
    
    % Różnica wstecz: s = (z-1)/(Ts*z) -> G(z) = 1/((z-1)^2/(Ts^2*z^2) + 1)
    den_backward = [1 -2 1]/Ts^2 + [1 0 0]; % Przesunięcie o z^2 i uproszczenie
    sys_backward = tf([1], den_backward, Ts);
    
    % Tustin: użyjemy c2d
    sys_tustin = c2d(sys_continuous, Ts, 'tustin');
    
    % Odpowiedzi skokowe układów dyskretnych
    y_forward = step(sys_forward, t_discrete);
    y_backward = step(sys_backward, t_discrete);
    y_tustin = step(sys_tustin, t_discrete);
    
    % Wykres
    figure('Position', [100 100 800 400]);
    plot(t_continuous, y_continuous, 'k-', 'LineWidth', 2, 'DisplayName', 'Ciągły');
    hold on;
    stairs(t_discrete, y_forward, 'r--', 'LineWidth', 2, 'DisplayName', 'Różnica wprzód');
    stairs(t_discrete, y_backward, 'b--', 'LineWidth', 2, 'DisplayName', 'Różnica wstecz');
    stairs(t_discrete, y_tustin, 'g--', 'LineWidth', 2, 'DisplayName', 'Tustin');
    xlabel('Czas [s]');
    ylabel('Wyjście');
    title(['Odpowiedź skokowa, T = ', num2str(Ts), ' s']);
    legend;
    grid on;
    hold off;
    saveas(gcf, fullfile('zad1', ['skokowa_', num2str(Ts), '.png']), 'png');
end

disp('Wykresy dla zadania 1 wygenerowane.');