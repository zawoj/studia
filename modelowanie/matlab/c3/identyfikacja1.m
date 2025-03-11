Phi=[u(2:(end-1)) u(1:(end-2)) -y(2:(end-1)) -y(1:(end-2)) ];
Y=y(3:end);
theta=pinv(Phi)*Y
D=svd(Phi)

Phi2=[ u(1) 0 -y(1)  0
      u(2:(end-1)) u(1:(end-2)) -y(2:(end-1)) -y(1:(end-2))];
Y2=y(2:end);
theta2=pinv(Phi2)*Y2
D2=svd(Phi2)