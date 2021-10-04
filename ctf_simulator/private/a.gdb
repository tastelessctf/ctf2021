set follow-fork-mode child
ps socat --attach
c


define magic
b *uw_frame_state_for+1096
c
end
