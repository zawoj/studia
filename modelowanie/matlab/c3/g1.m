% Identyfikacja układu dyskretnego G1(z) = (0.1z + 0.2)/(z^2 + 0.3z + 0.4)

% Parametry symulacji
N = 100;       % liczba próbek
ts = 0.1;      % okres próbkowania

% Parametry układu
b = [0.1, 0.2];
a = [1, 0.3, 0.4];

% Poziom szumu
noise_level = 0.15; % zwiększony poziom szumu (15% amplitudy)

% Generacja sygnałów wejściowych dla porównania różnych typów wymuszeń
t = (0:N-1)*ts;

% Przypadek 1: Wymuszenie skokiem jednostkowym
u_step = ones(1, N);
y_step_clean = dlsim(b, a, u_step);
% Dodanie szumu gaussowskiego
rng(1); % dla powtarzalności wyników
y_step = y_step_clean + noise_level*std(y_step_clean)*randn(size(y_step_clean));

% Przypadek 2: Wymuszenie sygnałem losowym
rng(42); % dla powtarzalności wyników
u_rand = rand(1, N);
y_rand_clean = dlsim(b, a, u_rand);
% Dodanie szumu gaussowskiego
rng(2);
y_rand = y_rand_clean + noise_level*std(y_rand_clean)*randn(size(y_rand_clean));

% Przypadek 3: Wymuszenie sinusoidą
u_sin = sin(t);
y_sin_clean = dlsim(b, a, u_sin);
% Dodanie szumu gaussowskiego
rng(3);
y_sin = y_sin_clean + noise_level*std(y_sin_clean)*randn(size(y_sin_clean));

% Przypadek 4: Wymuszenie sumą sinusoid o różnych częstotliwościach
u_multi = sin(t) + sin(3*t) + sin(5*t);
y_multi_clean = dlsim(b, a, u_multi);
% Dodanie szumu gaussowskiego
rng(4);
y_multi = y_multi_clean + noise_level*std(y_multi_clean)*randn(size(y_multi_clean));

% Funkcja do identyfikacji metodą najmniejszych kwadratów
% oraz analizy uwarunkowania problemu
function [theta, singular_values] = identify_system(u, y)
    % Ensure both u and y are column vectors
    if size(u, 1) == 1
        u = u(:);  % Convert to column vector if it's a row vector
    end
    if size(y, 1) == 1
        y = y(:);  % Convert to column vector if it's a row vector
    end
    
    % Budowa macierzy Phi dla układu drugiego rzędu
    Phi = [u(2:end-1) u(1:end-2) -y(2:end-1) -y(1:end-2)];
    Y = y(3:end);
    
    % Rozwiązanie metodą pseudoinwersji
    theta = pinv(Phi) * Y;
    
    % Analiza wartości szczególnych
    singular_values = svd(Phi);
    
    % Dodatkowe równanie dla chwili początkowej
    Phi2 = [u(1) 0 -y(1) 0; Phi];
    Y2 = [y(2); Y];
    
    % Rozwiązanie z dodatkowym równaniem
    theta2 = pinv(Phi2) * Y2;
    
    % Analiza wartości szczególnych dla rozszerzonej macierzy
    singular_values2 = svd(Phi2);
    
    % Wyświetlenie wyników
    disp('Identyfikowane parametry:');
    disp(['Prawdziwe parametry: b1 = ' num2str(0.1) ', b0 = ' num2str(0.2) ...
        ', a1 = ' num2str(0.3) ', a0 = ' num2str(0.4)]);
    disp(['Estymowane parametry (bez dodatkowego równania): b1 = ' num2str(theta(1)) ...
        ', b0 = ' num2str(theta(2)) ', a1 = ' num2str(theta(3)) ', a0 = ' num2str(theta(4))]);
    disp(['Estymowane parametry (z dodatkowym równaniem): b1 = ' num2str(theta2(1)) ...
        ', b0 = ' num2str(theta2(2)) ', a1 = ' num2str(theta2(3)) ', a0 = ' num2str(theta2(4))]);
    
    disp('Wartości szczególne:');
    disp(['Bez dodatkowego równania: ' num2str(singular_values')]);
    disp(['Z dodatkowym równaniem: ' num2str(singular_values2')]);
end

% Identyfikacja dla różnych typów wymuszenia
disp('===== WYMUSZENIE SKOKIEM JEDNOSTKOWYM =====');
[theta_step, sv_step] = identify_system(u_step, y_step);

disp('===== WYMUSZENIE SYGNAŁEM LOSOWYM =====');
[theta_rand, sv_rand] = identify_system(u_rand, y_rand);

disp('===== WYMUSZENIE SINUSOIDĄ =====');
[theta_sin, sv_sin] = identify_system(u_sin, y_sin);

disp('===== WYMUSZENIE SUMĄ SINUSOID =====');
[theta_multi, sv_multi] = identify_system(u_multi, y_multi);

% Walidacja modelu - porównanie odpowiedzi modelu zidentyfikowanego z rzeczywistym
function validate_model(u, y, theta, model_name)
    % Ensure inputs have correct dimensions
    if size(u, 1) == 1
        u = u(:);  % Convert to column vector if it's a row vector
    end
    if size(y, 1) == 1
        y = y(:);  % Convert to column vector if it's a row vector
    end
    
    b_id = [theta(1), theta(2)];
    a_id = [1, theta(3), theta(4)];
    
    % Symulacja modelu zidentyfikowanego
    y_id = dlsim(b_id, a_id, u);
    
    % Ensure y_id has the same shape as y for plotting
    if size(y_id, 2) ~= size(y, 2)
        y_id = reshape(y_id, size(y));
    end
    
    % Obliczenie błędu średniokwadratowego
    mse = mean((y - y_id).^2);
    
    % Wykresy
    figure('Position', [100, 100, 800, 600]); % Zwiększony rozmiar wykresu
    
    subplot(3,1,1);
    plot(u, 'LineWidth', 1.5);
    title(['Walidacja modelu - ' model_name], 'FontSize', 14);
    ylabel('Wejście u(k)', 'FontSize', 12);
    grid on;
    set(gca, 'FontSize', 11);
    
    % Save the first plot
    saveas(gcf, [model_name '_input.png']);
    
    subplot(3,1,2);
    plot(1:length(y), y, 'b', 'LineWidth', 1.5);
    hold on;
    plot(1:length(y_id), y_id, 'r--', 'LineWidth', 1.5);
    legend('Rzeczywiste wyjście (z szumem)', 'Wyjście modelu', 'FontSize', 11, 'Location', 'best');
    ylabel('Wyjście y(k)', 'FontSize', 12);
    grid on;
    set(gca, 'FontSize', 11);
    
    % Save the second plot
    saveas(gcf, [model_name '_output.png']);
    
    subplot(3,1,3);
    plot(y - y_id, 'LineWidth', 1.5);
    title(['Błąd predykcji, MSE = ' num2str(mse)], 'FontSize', 14);
    ylabel('Błąd', 'FontSize', 12);
    xlabel('Numer próbki k', 'FontSize', 12);
    grid on;
    set(gca, 'FontSize', 11);
    
    % Save the third plot
    saveas(gcf, [model_name '_error.png']);
    
    disp(['MSE dla modelu ' model_name ': ' num2str(mse)]);
end

% Walidacja modeli
validate_model(u_step, y_step, theta_step, 'G1 z wymuszeniem skokowym');
validate_model(u_rand, y_rand, theta_rand, 'G1 z wymuszeniem losowym');
validate_model(u_sin, y_sin, theta_sin, 'G1 z wymuszeniem sinusoidalnym');
validate_model(u_multi, y_multi, theta_multi, 'G1 z wymuszeniem sumą sinusoid');