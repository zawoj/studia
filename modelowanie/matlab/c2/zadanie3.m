% Skrypt do zadania 3: Identyfikacja parametrów krzywej balansowania samolotu
clear all; close all;

% Dane pomiarowe
v = [80 90 100 110 120 140 160 180 200]; % Prędkość [m/s]
n = [8 12 11 9 14 6 9 12 10]; % Liczba pomiarów

% Kąt delta w stopniach i minutach
delta_deg = [-3 -2 -2 -1 -1 0 0 0 0]; % Stopnie
delta_min = [-44 -58 -16 -39 -21 -38 -7 10 35]; % Minuty
delta = delta_deg + delta_min / 60; % Przeliczenie na stopnie dziesiętne

% Przygotowanie danych do regresji
x = 1 ./ (v.^2); % 1/v^2 jako zmienna niezależna
y = delta; % Kąt delta

% Macierz A i wektor b z uwzględnieniem wag (n)
A = [ones(length(v), 1) x']; % [1, 1/v^2]
b = y';

% Rozwiązanie z pseudoodwrotnością (bez wag)
z = pinv(A) * b;
a0_est = z(1); % Estymowane a0
a1_est = z(2); % Estymowane a1

% Rozwiązanie z wagami (uwzględnienie n)
W = diag(n); % Macierz diagonalna z wagami
z_weighted = pinv(A' * W * A) * A' * W * b; % Ważona regresja
a0_est_weighted = z_weighted(1);
a1_est_weighted = z_weighted(2);

% Obliczenie estymowanej krzywej
v_fine = 80:1:200; % Gęstszy wektor prędkości do wykresu
delta_est = a0_est + a1_est ./ (v_fine.^2);
delta_est_weighted = a0_est_weighted + a1_est_weighted ./ (v_fine.^2);

% Obliczenie błędów (suma kwadratów)
delta_calc = a0_est + a1_est ./ (v.^2);
delta_calc_weighted = a0_est_weighted + a1_est_weighted ./ (v.^2);
ee = sum(n .* (delta - delta_calc_weighted).^2); % Błąd estymacji z wagami
disp(['Suma kwadratów błędów estymacji (ee, ważone): ', num2str(ee)]);

% Wykres
figure;
scatter(v, delta, n*10, 'r', 'filled'); hold on; % Rozmiar punktów proporcjonalny do n
plot(v_fine, delta_est, 'b-', 'LineWidth', 1.5);
plot(v_fine, delta_est_weighted, 'g-', 'LineWidth', 2);
xlabel('Prędkość [m/s]');
ylabel('Kąt odchylenia \delta [°]');
title(['Identyfikacja: a_0 = ', num2str(a0_est_weighted), '°, a_1 = ', num2str(a1_est_weighted), '°·m²/s²']);
legend('Dane pomiarowe (rozmiar ~ n)', 'Regresja bez wag', 'Regresja z wagami');
grid on;

% Wypisanie wyników
disp('Regresja bez wag:');
disp(['Estymowane a_0: ', num2str(a0_est), '°']);
disp(['Estymowane a_1: ', num2str(a1_est), '°·m²/s²']);
disp('Regresja z wagami:');
disp(['Estymowane a_0: ', num2str(a0_est_weighted), '°']);
disp(['Estymowane a_1: ', num2str(a1_est_weighted), '°·m²/s²']);