= arch-setup =

== SYNOPSIS ==

.. code-block:: bash

    arch-setup.sh [ options ] USER

== OPTIONS ==

.. code-block:: bash

    -h              print details
    -b              basic setup (console only)
    -p PKG_LIST     install packages from PKG_LIST

== EXAMPLE ==

Post-install setup of a machine running Arch Linux for username 'foo' ...

.. code-block:: bash

    # arch-setup.sh foo

Install packages from 'pkg-list' ...

.. code-block:: bash

    # arch-setup.sh -p pkg-list foo

== DESCRIPTION ==

Script **arch-setup.sh** is ideally run immediately following the first successful boot into your new Arch Linux installation.

Building on a minimal install, the system will be configured with a choice of either ...

1) a basic console setup; or
2) a more complete setup which includes the `i3 tiling window manager <http://www.circuidipity.com/i3-tiling-window-manager.html>`_ plus a packages collection suitable for a workstation; or
3) install the `same list of packages as PKG_LIST <http://www.circuidipity.com/debian-package-list.html>`_

... will be installed.

== USE ==

**0.** Install program folder on target machine.

**1.** Copy ``config.sample`` to ``config`` and (optional) enable settings. All settings are **disabled** by default.

**2.** Run program!

== DEPENDS ==

``bash``

Happy hacking!

== Author ==

| Daniel Wayne Armstrong (aka) VonBrownie
| http://www.circuidipity.com

== License ==

GPLv2. See ``LICENSE`` for more details.
