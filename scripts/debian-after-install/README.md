Debian-after-install
====================

![Debian](debian-banner.png)

NAME
----

**debian-after-install.sh** - Configure a device after a fresh install of Debian.

SYNOPSIS
--------

`debian-after-install.sh [OPTION]`

DESCRIPTION
-----------

Script `debian-after-install.sh` is ideally run after the first successful boot into a [minimal install](https://www.circuidipity.com/minimal-debian/) of Debian 10 aka "buster" release.

User may choose to remain with the stable release or track the unstable aka "sid" package repository.

A choice of either [w]orkstation or [s]erver setup is available. [S]erver is a basic console setup, whereas [w]orkstation is a more complete setup with the option of installing:
    * [Openbox](https://www.circuidipity.com/openbox/)
    * GNOME desktop environment
    * Xorg (no desktop)
    
Alternately, in lieu of a pre-defined list of Debian packages, the user may specify their own [custom list of packages](https://www.circuidipity.com/debian-package-list/) to be installed.

OPTIONS
-------

```
-h              print details
-p PKG_LIST     install packages from PKG_LIST
```

EXAMPLES
--------

Run script ...

```
# ./debian-after-install.sh
```

Install the list of packages specified in `my-pkg-list` ...

```
# ./debian-after-install.sh -p my-pkg-list
```

AUTHOR
------

[Daniel Wayne Armstrong](https://www.dwarmstrong.org)

LICENSE
-------

GPLv3. See [LICENSE](https://github.com/vonbrownie/linux-post-install/blob/master/LICENSE) for more details.

SEE ALSO
--------

* [More Debian: debian-after-install](https://www.circuidipity.com/debian-after-install/)
* [Minimal Debian](https://www.circuidipity.com/minimal-debian/)
* [Roll your own Linux desktop using Openbox](https://www.circuidipity.com/openbox/)
* [Install (almost) the same list of Debian packages on multiple machines](https://www.circuidipity.com/debian-package-list/)
