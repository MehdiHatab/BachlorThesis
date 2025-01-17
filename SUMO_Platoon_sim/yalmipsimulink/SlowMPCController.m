function uout = SlowMPCController(currentx,currentr,t)

persistent constraints
persistent objective
persistent x u r
persistent ops

 % Should only be required at t=0, but but some reason simulink calls
 % multiple times at t=0, and at the next call t>0 all persistant are
 % cleared (seen in R2012a)
if t == 0 || isempty(constraints)
    % Compute discrete-time dynamics
    Plant = ss(tf(1,[1 0 0]));
    A = Plant.A;
    B = Plant.B;
    C = Plant.C;
    D = Plant.D;
    Ts = 0.1;
    Gd = c2d(Plant,Ts);
    Ad = Gd.A;
    Bd = Gd.B;
    
    % Define data for MPC controller
    N = 10;
    Q = 10;
    R = 0.1;
    
    % Avoid explosion of internally defined variables in YALMIP
    yalmip('clear')
    
    % Setup the optimization problem
    u = sdpvar(repmat(1,1,N),repmat(1,1,N));
    x = sdpvar(repmat(2,1,N+1),repmat(1,1,N+1));
    sdpvar r
    % Define simple standard MPC controller
    % Current state is known so we replace this
    constraints = [];
    objective = 0;
    for k = 1:N
        objective = objective + (r-C*x{k})'*Q*(r-C*x{k})+u{k}'*R*u{k};
        constraints = [constraints, x{k+1} == Ad*x{k}+Bd*u{k}];
        constraints = [constraints, -5 <= u{k}<= 5];
    end
    
    % Solve, and constrain the symbolic initial state and reference
    ops = sdpsettings('verbose',0);
    sol = solvesdp([constraints,x{1} == currentx, r == currentr],objective,ops);       
    uout = double(u{1});
else    
    % Solve, and constrain the symbolic initial state and reference
    sol = solvesdp([constraints,x{1} == currentx, r == currentr],objective,ops);    
    % ...and return the optimal input
    uout = double(u{1});
end