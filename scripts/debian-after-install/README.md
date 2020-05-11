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

Script `debian-after-install.sh` is ideally run after the first successful boot into a [minimal install](https://www.dwarmstrong.org/minimal-debian/) of Debian 10 aka "buster" release.

A choice of either [w]orkstation or [s]erver is available. [S]erver is a basic console setup, whereas [w]orkstation is a more complete setup with the option of installing:
    
* [Openbox](https://www.circuidipity.com/openbox/)
* GNOME desktop environment
* Xorg (no desktop)
    
Alternately, in lieu of a pre-defined list of Debian packages, the user may specify their own [custom list of packages](https://www.dwarmstrong.org/debian-package-list/) to be installed.

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

LICENSE
-------

GPLv3. See [LICENSE](https://github.com/dwarmstrong/linux-post-install/blob/master/LICENSE) for more details.

SEE ALSO
--------

* [More Debian: debian-after-install](https://www.dwarmstrong.org/debian-after-install/)
* [Minimal Debian](https://www.dwarmstrong.org/minimal-debian/)
* [Roll your own Linux desktop using Openbox](https://www.dwarmstrong.org/openbox/)
* [Install (almost) the same list of Debian packages on multiple machines](https://www.dwarmstrong.org/debian-package-list/)
