fig=figure;
set(fig,'renderer','zbuffer');
[x y z] = sphere(100);
colormap(jet);
s = surface(x,y,z,'edgecolor','none');
axis off equal vis3d;
camlight;
shading interp;
lighting gouraud;
set(fig,'renderer','openGL');
t = surface(x*1.2,y*1.2,z*1.2,'facecolor',[.1 .1 .1]);
set(t,'edgecolor','none');
alpha(t,.1);
rotate3d on;
