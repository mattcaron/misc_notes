1. As of 11.04, it's in repos.

sudo aptitude install gdc-4.6

2. gtkd:

git clone 
https://github.com/gtkd-developers/GtkD.git
cd GtkD
make libs

(make all fails because some of the demos use things which aren't
supported under gdc 4.6)






Notes:
Old: D 1.0 with Tango
New: D 2.0 with Phobos


Deprecated:

1.) Grab the precompiled tango:

http://www.dsource.org/projects/tango/wiki/DmdDownloads

2.) chuck it in /usr/local/apps/

3.) Symlink tomfoolery

2. WxD

Download:
http://sourceforge.net/projects/wxd/files/wxD/

sudo aptitude install libwxgtk2.8-dev

COMPILER=GDC LIBRARY=Phobos make

3. building 

gdc -I/home/matt/workspace/code/wxd/wxd -c -o wxHello.o wxHello.d

NOTE: ORDER MATTERS (not sure why):
gdc -o wxHello wxHello.o -L/home/matt/workspace/code/wxd/wxd -lwxd -lwxc `wx-config --libs` -lstdc++

one shot:
gdc -o wxHello wxHello.d -I/home/matt/workspace/code/wxd/wxd -L/home/matt/workspace/code/wxd/wxd -lwxd -lwxc `wx-config --libs` -lstdc++

(Note that this is stupid, as we will have multiple objects, but hey...)





