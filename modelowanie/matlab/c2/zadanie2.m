% Skrypt do zadania 2: Identyfikacja parametrów rozładowania kondensatora
clear all; close all;

% Dane pomiarowe
t = [0 1 2 3 4 5 6 7]; % Czas [s]
Uc = [100 75 55 40 30 20 15 10]; % Napięcie [V]

% Linearyzacja: ln(Uc) = ln(U0) - a*t
y = log(Uc); % y = ln(Uc)
A = [ones(length(t), 1) -t']; % Macierz A: [1 -t]
b = y'; % Wektor b: ln(Uc)

% Rozwiązanie za pomocą pseudoodwrotności
z = pinv(A) * b; % z(1) = ln(U0), z(2) = a
U0_est = exp(z(1)); % Estymowane U0
a_est = z(2); % Estymowane a

% Obliczenie estymowanej krzywej
Uc_est = U0_est * exp(-a_est * t);

% Obliczenie błędów
ee = (Uc - Uc_est) * (Uc - Uc_est)'; % Suma kwadratów błędów estymacji
disp(['Suma kwadratów błędów estymacji (ee): ', num2str(ee)]);

% Wykres
figure;
plot(t, Uc, 'r+', 'MarkerSize', 10, 'LineWidth', 1.5); hold on;
plot(t, Uc_est, 'g-', 'LineWidth', 2);
xlabel('Czas [s]');
ylabel('Napięcie [V]');
title(['Identyfikacja: U_0 = ', num2str(U0_est), ' V, a = ', num2str(a_est), ' 1/s']);
legend('Dane pomiarowe', 'Zidentyfikowana funkcja');
grid on;

% Wypisanie wyników
disp(['Estymowane U_0: ', num2str(U0_est), ' V']);
disp(['Estymowane a: ', num2str(a_est), ' 1/s']);