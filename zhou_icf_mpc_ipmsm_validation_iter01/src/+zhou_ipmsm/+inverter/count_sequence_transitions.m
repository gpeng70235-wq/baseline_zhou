function count = count_sequence_transitions(states)
%COUNT_SEQUENCE_TRANSITIONS Total bridge-leg state changes in a sequence.

assert(size(states, 2) == 3, 'ZhouIPMSM:InvalidSwitchState', ...
    'Switch-state matrix must have three columns.');
if size(states, 1) < 2
    count = 0;
else
    count = sum(abs(diff(states, 1, 1)), 'all');
end
end

