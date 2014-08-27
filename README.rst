==================
linux-post-install
==================

Post-install configuration of Debian GNU/Linux.

**debian-post-install-main.sh**

Track the *wheezy* (stable), *jessie* (testing), or *sid* (unstable) branch with the option of installing the lightweight Openbox window manager + extra apps suitable for a desktop environment.

See: `Debian Wheezy Minimal Install <http://www.circuidipity.com/install-debian-wheezy-screenshot-tour.html>`_ and `Install Debian using grml-debootstrap <http://www.circuidipity.com/grml-debootstrap.html>`_ (circuidipity.com)

**c720-sidbook-post-install-main.sh**

Configures the **Acer C720 Chromebook** to track Debian's *sid* branch and installs Openbox.

See: `From Chromebook to Sidbook <http://www.circuidipity.com/c720-sidbook.html>`_ (circuidipity.com)

Install and Use
===============

To install *linux-post-install* from source:

.. code-block:: console

    $ wget -c https://github.com/vonbrownie/linux-post-install/releases/download/vX.X.X/linux-post-install-X.X.X.tar.gz
    $ tar -xvzf linuxpost-install-X.X.X.tar.gz
    $ cd linux-post-install-X.X.X
    $ sudo ./SCRIPT-post-install-main.sh

Happy hacking!

Author
======

| Daniel Wayne Armstrong (aka) VonBrownie
| http://www.circuidipity.com
| https://twitter.com/circuidipity
| daniel@circuidipity.com

License
=======

GPLv2. See ``LICENSE`` for more details.
