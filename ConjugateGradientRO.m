function [x, flag, relres, iter, resvec, xhist] = ConjugateGradientRO(A, b, tol, maxit, x0)
%
%   ConjugateGradientRO tries to solve the linear system A*x = b for x iteratively with the conjugate gradients method where A is a symmetric positive definite matrix.
%   Re-Orthogonalization of the residuals is used to simulate exact arithmetics.
%   When the attempt is successful, Conjugate Gradient displays a message to confirm convergence.
%   If ConjugateGradientRO fails to converge after the maximum number of iterations or halts for any reason,
%   it displays a diagnostic message that includes the relative residual norm(b-A*x)/norm(b) and the iteration number at which the method stopped.
%   Displayed messages are omitted if the flag is returned.
%   
%   POSSIBLE FUNCTION SIGNATURES
%
%   x = ConjugateGradientRO(A,b)
%   x = ConjugateGradientRO(A,b,tol)
%   x = ConjugateGradientRO(A,b,tol,maxit)
%   x = ConjugateGradientRO(A,b,tol,maxit,x0)
%   [x,flag] = ConjugateGradientRO(___)
%   [x,flag,relres] = ConjugateGradientRO(___)
%   [x,flag,relres,iter] = ConjugateGradientRO(___)
%   [x,flag,relres,iter,resvec] = ConjugateGradientRO(___)
%
%   INPUT ARGUMENTS
%   
%   A      - symmetric positive definite n x n matrix ()
%   b      - right hand side 1 x n vector
%   tol    - tolerance on relative residual norm(r)/norm(b) (default 1e-6)
%   maxit  - maximum number of iterations (default min(n, 20))
%   x0     - initial guess (default zero vector)
%   
%   OUTPUT ARGUMENTS
%   
%   x      - approximate solution
%   flag   - specifies whether the algorithm successfully converged. When flag = 0, convergence was successful
%   relres - relative residual norm(b-A*x)/norm(b). If flag is 0, then relres <= tol
%   iter   - iteration number iter at which x was computed
%   resvec - vector of the residual norm at each iteration, including the first residual norm(b-A*x0)
%   
%   FLAG VALUES
%   
%   0      - Success: ConjugateGradientRO converged to the desired tolerance tol within maxit iterations.
%   1      - Failure: ConjugateGradientRO iterated maxit iterations but did not converge.
%   4      - Failure: One of the scalar quantities calculated by the ConjugateGradientRO algorithm became too small or too large to continue computing.
%   

% check input arguments
try
    % default parameters
    if nargin < 2
        errID = 'ConjugateGradientRO:inputError';
        msgtext = 'Not enough inputs. Needs at least matrix and rhs.';
        throw(MException(errID, msgtext));
    end
    if nargin < 3
        tol = 1e-6;
    end
    if nargin < 4
        maxit = min(size(A,1), 20);
    end
    if nargin < 5
        x0 = zeros(length(b), 1);
    end
    if nargin < 6
        storehist = false;
    end
    
    % check if matrix is square
    [n, m] = size(A);
    if n ~= m
        errID = 'ConjugateGradientRO:inputError';
        msgtext = 'Input matrix is not square. Size is %d x %d.';
        throw(MException(errID, msgtext, n, m));
    end
    
    % check if matrix is symmetric
    if ~all(all(A == A'))
        errID = 'ConjugateGradientRO:inputError';
        msgtext = 'Input matrix is not symmetric';
        throw(MException(errID, msgtext));
    end
    
    % check rhs
    if length(b) ~= n
        errID = 'ConjugateGradientRO:inputError';
        msgtext = 'Length of rhs %d does not match matrix size %d.';
        throw(MException(errID, msgtext, length(b), n));
    end
    
    % check initial guess
    if length(x0) ~= n
        errID = 'ConjugateGradientRO:inputError';
        msgtext = 'Length of initial guess %d does not match matrix size %d.';
        throw(MException(errID, msgtext, length(x0), n));
    end
catch exception
    disp('ConjugateGradientRO:inputError')
    throw(exception)
end

alpha = 0;
beta = 0;
r = b - A*x0;
r2 = r' * r;
p = r;
Ap = zeros(1, n);
x = x0;
resvec_ = [r2];

flag_ = -1;
abstol2 = (tol*norm(b))^2;
residuals = r;

try
    for i=1:maxit
        iter_ = i-1;
        Ap = A*p;
        alpha = r2 / (p' * Ap);
        x = x + alpha * p;
        r = r - alpha * Ap;
        % perform reorthogonalization to simulate exact arithmetic
        for count = 1:2
            for j = 1:i
                r = r - r'*residuals(:, j)/resvec_(j) * residuals(:, j);
            end
        end
        % storing residual vector for reorthogonalization
        residuals = [residuals, r];
        r2 = r'*r;
        resvec_(i+1) = r2;
        if r2 <= abstol2
            % success: method converged to specified tolerance
            flag_ = 0;
            relres_ = norm(r)/norm(b);
            if nargout == 1
                disp(['ConjugateGradientRO converged at iteration ', num2str(iter_), ' to a solution with relative residual ', num2str(relres_), '.'])
            end
            break
        end
        beta = r2/resvec_(i);
        p = r + beta * p;
    end
catch
    % failure: numerical exception during iteration
    flag_ = 4;
    iter_ = 0;
    relres_ = 0;
    if nargout == 1
        disp('One of the scalar quantities calculated by the ConjugateGradientRO algorithm became too small or too large to continue computing.')
    end
end

if flag_ < 0
    % failure: maximum number of iterations reached
    flag_ = 1;
    iter_ = maxit;
    relres_ = norm(r)/norm(b);
    if nargout == 1
        disp(['ConjugateGradientRO stopped at iteration ', num2str(maxit), ' without converging to the desired tolerance ', num2str(tol)])
        disp('because the maximum number of iterations was reached.')
        disp(['The iterate returned (number ', num2str(maxit), ') has relative residual ', num2str(relres_),'.'])
    end
end

% variable number of output arguments
if nargout > 1
    flag = flag_;
end
if nargout > 2
    relres = relres_;
end
if nargout > 3
    iter = iter_;
end
if nargout > 4
    resvec = sqrt(resvec_(:));
end