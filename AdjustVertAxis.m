function AdjustVertAxis(H)
% adjust the vertical axis of a plot to a value specified by H

Hn = get(gcf,'Children');

for plt = 1:length(Hn)

    P = get(Hn(plt),'OuterPosition'); % 4D row vector; last value is height

    P(4) = H;

    set(Hn(plt),'OuterPosition',P)
end