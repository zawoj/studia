% Identyfikacja układu dyskretnego G2(z) = (0.1z^2 + 0.2z + 0.3)/(z^3 + 0.3z^2 + 0.4z + 0.2)

% Parametry symulacji
N = 200;       % liczba próbek
ts = 0.1;      % okres próbkowania

% Parametry układu
b = [0.1, 0.2, 0.3];
a = [1, 0.3, 0.4, 0.2];

% Poziom szumu
noise_level = 0.35; % poziom szumu (15% amplitudy)

% Generacja wymuszenia losowego (najbardziej efektywne dla identyfikacji)
rng(42); % dla powtarzalności wyników
u = rand(1, N);
y_clean = dlsim(b, a, u);
% Dodanie szumu gaussowskiego
rng(43); % dla powtarzalności wyników szumu
y = y_clean + noise_level*std(y_clean)*randn(size(y_clean));

% Funkcja do identyfikacji układu trzeciego rzędu
function [theta, singular_values] = identify_system_third_order(u, y)
    % Ensure both u and y are row vectors
    if size(u, 2) == 1
        u = u';
    end
    if size(y, 2) == 1
        y = y';
    end
    
    % Budowa macierzy Phi dla układu trzeciego rzędu
    % Używamy tych samych indeksów dla wszystkich kolumn
    n = length(y);
    Phi = zeros(n-4, 6);
    for i = 4:n-1
        Phi(i-3,:) = [u(i) u(i-1) u(i-2) -y(i) -y(i-1) -y(i-2)];
    end
    Y = y(5:n)';
    
    % Rozwiązanie metodą pseudoinwersji
    theta = pinv(Phi) * Y;
    
    % Analiza wartości szczególnych
    singular_values = svd(Phi);
    
    % Wyświetlenie wyników
    disp('Identyfikowane parametry:');
    disp(['Prawdziwe parametry: b2 = ' num2str(0.1) ', b1 = ' num2str(0.2) ...
        ', b0 = ' num2str(0.3) ', a2 = ' num2str(0.3) ', a1 = ' num2str(0.4) ...
        ', a0 = ' num2str(0.2)]);
    disp(['Estymowane parametry: b2 = ' num2str(theta(1)) ', b1 = ' num2str(theta(2)) ...
        ', b0 = ' num2str(theta(3)) ', a2 = ' num2str(theta(4)) ...
        ', a1 = ' num2str(theta(5)) ', a0 = ' num2str(theta(6))]);
    
    disp('Wartości szczególne:');
    disp(num2str(singular_values'));
end

% Identyfikacja układu G2
disp('===== IDENTYFIKACJA UKŁADU G2 =====');
[theta_g2, sv_g2] = identify_system_third_order(u, y);

% Walidacja modelu
function validate_model_third_order(u, y, theta)
    b_id = [theta(1), theta(2), theta(3)];
    a_id = [1, theta(4), theta(5), theta(6)];
    
    % Symulacja modelu zidentyfikowanego
    y_id = dlsim(b_id, a_id, u);
    
    % Obliczenie błędu średniokwadratowego
    mse = mean((y - y_id).^2);
    
    % Wykresy
    figure('Position', [100, 100, 1000, 800]); % Jeszcze większy rozmiar wykresu
    
    subplot(3,1,1);
    plot(u, 'LineWidth', 2);
    title('Walidacja modelu G2', 'FontSize', 16);
    ylabel('Wejście u(k)', 'FontSize', 14);
    grid on;
    set(gca, 'FontSize', 12);
    xlim([0 100]); % Ograniczenie zakresu osi X
    
    subplot(3,1,2);
    plot(y, 'b', 'LineWidth', 2);
    hold on;
    plot(y_id, 'r--', 'LineWidth', 2);
    legend('Rzeczywiste wyjście (z szumem)', 'Wyjście modelu', 'FontSize', 12, 'Location', 'best');
    ylabel('Wyjście y(k)', 'FontSize', 14);
    grid on;
    set(gca, 'FontSize', 12);
    xlim([0 100]); % Ograniczenie zakresu osi X
    
    subplot(3,1,3);
    plot(y - y_id, 'LineWidth', 2);
    title(['Błąd predykcji, MSE = ' num2str(mse)], 'FontSize', 16);
    ylabel('Błąd', 'FontSize', 14);
    xlabel('Numer próbki k', 'FontSize', 14);
    grid on;
    set(gca, 'FontSize', 12);
    xlim([0 100]); % Ograniczenie zakresu osi X
    
    % Save the plots
    saveas(gcf, 'G2_validation.png');
    
    disp(['MSE dla modelu G2: ' num2str(mse)]);
end

% Walidacja modelu G2
validate_model_third_order(u, y, theta_g2);