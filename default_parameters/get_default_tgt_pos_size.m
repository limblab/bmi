function [tgt_pos,tgt_size] = get_default_tgt_pos_size(tgt_id)
    tgt_size = [4 4];
    r = 10; %radius

    num_tgt = length(tgt_id);
    tgt_pos = nan(num_tgt,2);
    
    for i = 1:num_tgt
        if ~tgt_id(i)
            tgt_pos(i,:) = [0 0];
        else
            tgt_pos(i,:) = [r*cos(2*pi*(tgt_id(i)-1)/8) r*sin(2*pi()*(tgt_id(i)-1)/8)];
        end
    end
end