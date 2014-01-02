function x = Wiener_filter(spikes, w)

x = spikes(:)'*w;
