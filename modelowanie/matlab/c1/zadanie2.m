% Prosta implementacja zadania 2: Dyskretyzacja układu 1/(s^2 + s + 1)
clear all; close all; clc;

if ~exist('zad2', 'dir')
    mkdir('zad2');
end

% Parametry
Ts_values = [1, 0.5, 0.1]; % Okresy próbkowania
sys_continuous = tf(1, [1 1 1]); % G(s) = 1/(s^2 + s + 1)

% Pętla po okresach próbkowania
for i = 1:length(Ts_values)
    Ts = Ts_values(i);
    t_continuous = 0:0.01:20; % Czas ciągły (dłuższy, bo oscylacje)
    t_discrete = 0:Ts:20;     % Czas dyskretny
    
    % Odpowiedź skokowa układu ciągłego
    y_continuous = step(sys_continuous, t_continuous);
    
    % Dyskretyzacja metodami aproksymacji pochodnej
    % Różnica wprzód: s = (z-1)/Ts -> G(z) = 1/((z-1)^2/Ts^2 + (z-1)/Ts + 1)
    den_forward = [1 -2 1]/Ts^2 + [0 1 -1]/Ts + [0 0 1];
    sys_forward = tf([1], den_forward, Ts);
    
    % Różnica wstecz: s = (z-1)/(Ts*z) -> G(z) = 1/((z-1)^2/(Ts^2*z^2) + (z-1)/(Ts*z) + 1)
    den_backward = [1 -2 1]/Ts^2 + [0 1 -1]/Ts + [1 0 0];
    sys_backward = tf([1], den_backward, Ts);
    
    % Tustin: użyjemy c2d
    sys_tustin = c2d(sys_continuous, Ts, 'tustin');
    
    % Odpowiedzi skokowe układów dyskretnych
    y_forward = step(sys_forward, t_discrete);
    y_backward = step(sys_backward, t_discrete);
    y_tustin = step(sys_tustin, t_discrete);
    
    % Wykres odpowiedzi skokowej
    % figure('Position', [100 100 800 400]);
    % plot(t_continuous, y_continuous, 'k-', 'LineWidth', 2, 'DisplayName', 'Ciągły');
    % hold on;
    % stairs(t_discrete, y_forward, 'r--', 'LineWidth', 2, 'DisplayName', 'Różnica wprzód');
    % stairs(t_discrete, y_backward, 'b--', 'LineWidth', 2, 'DisplayName', 'Różnica wstecz');
    % stairs(t_discrete, y_tustin, 'g--', 'LineWidth', 2, 'DisplayName', 'Tustin');
    % xlabel('Czas [s]');
    % ylabel('Wyjście');
    % title(['Odpowiedź skokowa, T = ', num2str(Ts), ' s']);
    % legend;
    % grid on;
    % hold off;
    % saveas(gcf, fullfile('zad2', ['skokowa_', num2str(Ts), '.png']), 'png');
    
    % % Wykres charakterystyki częstotliwościowej (Bode)
    % figure('Position', [100 100 800 400]);
    % bode(sys_continuous, 'k-', sys_forward, 'r--', sys_backward, 'b--', sys_tustin, 'g--');
    % title(['Charakterystyka Bode, T = ', num2str(Ts), ' s']);
    % legend('Ciągły', 'Różnica wprzód', 'Różnica wstecz', 'Tustin');
    % grid on;
    % saveas(gcf, fullfile('zad2', ['bode_', num2str(Ts), '.png']), 'png');

    % Weryfikacja obliczeń ręcznych dla T = 0.5 metodą Tustina
    % Weryfikacja obliczeń ręcznych dla T = 0.5 metodą Tustina
if Ts == 0.5
    % Ręczne obliczenia dla równania różnicowego:
    % y[k] = (30/21)y[k-1] - (13/21)y[k-2] + (1/21)u[k] + (2/21)u[k-1] + (1/21)u[k-2]
    N = 5; % Liczba kroków
    y_manual = zeros(1, N);
    u = [0 0 ones(1, N)]; % u[-2] = 0, u[-1] = 0, u[0] = 1, itd.
    
    % Obliczenia ręczne
    for k = 1:N
        if k == 1
            y_manual(k) = (30/21)*0 - (13/21)*0 + (1/21)*u(k+2) + (2/21)*u(k+1) + (1/21)*u(k);
        elseif k == 2
            y_manual(k) = (30/21)*y_manual(k-1) - (13/21)*0 + (1/21)*u(k+2) + (2/21)*u(k+1) + (1/21)*u(k);
        else
            y_manual(k) = (30/21)*y_manual(k-1) - (13/21)*y_manual(k-2) + (1/21)*u(k+2) + (2/21)*u(k+1) + (1/21)*u(k);
        end
    end
    
    % Porównanie z sys_tustin
    y_tustin_verify = step(sys_tustin, 0:Ts:(N-1)*Ts);
    disp(['Weryfikacja dla T = ', num2str(Ts), ' s:']);
    disp('k    Ręczne    MATLAB (Tustin)');
    for k = 1:N
        fprintf('%d    %.6f    %.6f\n', k-1, y_manual(k), y_tustin_verify(k));
    end
end
end

disp('Wykresy dla zadania 2 wygenerowane.');