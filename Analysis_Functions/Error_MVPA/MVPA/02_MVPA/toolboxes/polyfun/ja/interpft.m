% INTERPFT   FFT(高速フーリエ変換)法を使った1次元補間
% 
% Y = INTERPFT(X,N) は、X のフーリエ変換で補間によって得られる長さ N の
% ベクトル Y を出力します。 
%
% X が行列の場合、補間は各列に対して行われます。
% X が配列の場合、補間は最初に1でない次元に対して行われます。
%
% INTERPFT(X,N,DIM) は、次元 DIM について補間を行います。
%
% x(t) が、等間隔の点でサンプリングされた区間 p をもつ t の周期関数と
% 仮定すると、T(i) = (i-1)*p/M、i = 1:M、M = length(X) のとき、
% X(i) = x(T(i)) となります。y(t) は、同じ区間をもつ他の周期関数で、
% T(j) = (j-1)*p/N、j = 1:N、N = length(Y) のとき、Y(j) = y(T(j)) と
% なります。N が M の整数倍の場合、Y(1:N/M:N) = Xになります。
%
% 例 : 
%      % 三角形のような信号を補間するための設定を行います。
%      y  = [0:.5:2 1.5:-.5:-2 -1.5:.5:0]; % 等間隔
%      factor = 5; % 5 の係数で補間
%      m  = length(y)*factor;
%      x  = 1:factor:m;
%      xi = 1:m;
%      yi = interpft(y,m);
%      plot(x,y,'o',xi,yi,'*')
%      legend('Original data','Interpolated data')
%
% データ入力 x のサポートクラス
%      float: double, single
%  
% 参考 INTERP1.


%   Copyright 1984-2006 The MathWorks, Inc. 
