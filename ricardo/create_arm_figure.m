function hFig = create_arm_figure(arm_params)

hFig.f = figure;
clf
hold on
hFig.h_la = plot(0,0,'-k');
hFig.h_ua = plot(0,0,'-k');
hFig.h_pect = plot(0,0,'-r');
hFig.h_del = plot(0,0,'-r');
hFig.h_bi = plot(0,0,'-r');
hFig.h_tri = plot(0,0,'-r');   
hFig.h_text = text(-.9*sum(arm_params.l),.9*sum(arm_params.l),'t = 0 s');
hFig.h_F = plot(0,0,'-k');
hFig.h_hist = plot(0,0,'.b');
hFig.h_la2 = plot(0,0,'-','Color',[.5 .5 .5]);
hFig.h_ua2 = plot(0,0,'-','Color',[.5 .5 .5]);
hFig.h_hand = plot(0,0,'.k');
hFig.h_Xreal = plot(0,0,'.b');
hFig.h_Freal = plot(0,0,'-b');
xlim([-sum(arm_params.l) sum(arm_params.l)])
ylim([-sum(arm_params.l) sum(arm_params.l)])
axis square
    