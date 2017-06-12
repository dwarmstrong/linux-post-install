===================
debian-stable-setup
===================

Script **debian-stable-setup.sh** is ideally run immediately following the first successful boot into your new Debian installation.

Building on a minimal install [0] the system will be configured to track Debian's _stable_ release. A choice of either a console setup (option '-b') or a more extensive graphical interface which includes the i3 tiling window manager [1] plus a packages collection suitable for a workstation will be installed.

[0] "Minimal Debian" <http://www.circuidipity.com/minimal-debian.html>
[1] "Tiling window manager" <http://www.circuidipity.com/i3-tiling-window-manager.html>

Depends: ``bash``

Synopsis
========

.. code-block:: bash

    debian-stable-setup.sh [ options ] USER

Example: Post-install setup of a machine for (existing) USER 'foo' ...

.. code-block:: bash

    # ./debian-stable-setup.sh foo

Usage
=====

**0.** Install program folder on target machine.

**1.** Copy ``config.sample`` to ``config`` and (optional) enable settings. All settings are **disabled** by default.

**2.** Run program!

Happy hacking!

Author
======

| Daniel Wayne Armstrong (aka) VonBrownie
| http://www.circuidipity.com

License
=======

GPLv2. See ``LICENSE`` for more details.
