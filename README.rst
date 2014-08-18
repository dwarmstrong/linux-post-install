==================
linux-post-install
==================

Post-install configuration of Debian GNU/Linux. Track the wheezy/stable, jessie/testing, or sid/unstable branch with the option of installing the Openbox window manager + extra apps suitable for a desktop environment.

See: "Debian Wheezy Minimal Install"
http://www.circuidipity.com/install-debian-wheezy-screenshot-tour.html

"Install Debian using grml-debootstrap"
http://www.circuidipity.com/grml-debootstrap.html

TIP
---

Import a list of packages that duplicate the configuration from another system running Debian.

See: "Duplicate Debian package selection on multiple machines"
http://www.circuidipity.com/dpkg-duplicate.html

... and run this script with option '-i' and the location of the package list.

**EXAMPLE**
  Install packages from *package-list.txt*:
  (as_root)# ./debian-post-install-main.sh -i package-list.txt

Author
======

| Daniel Wayne Armstrong (aka) VonBrownie
| http://www.circuidipity.com
| https://twitter.com/circuidipity
| daniel@circuidipity.com

License
=======

GPLv2. See ``LICENSE`` for more details.
