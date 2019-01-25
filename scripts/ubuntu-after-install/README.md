# Ubuntu-after-install

### NAME

ubuntu-after-install.sh - Configure a device after a fresh install of Ubuntu 18.04 LTS

### SYNOPSIS

`ubuntu-after-install.sh [OPTION]`

### DESCRIPTION

Script `ubuntu-after-install.sh` is a *setup script* ideally run immediately following the first successful boot into **Ubuntu "Bionic Beaver" 18.04 LTS** [1].

A choice of either a **workstation** or **server** setup is available. *Server* is a basic console setup, whereas the *workstation* choice installs a range of desktop applications.

Alternately, in lieu of a pre-defined list of Ubuntu packages, the user may specify their own custom list of packages to be installed.

### OPTIONS

```bash
-h              print details
-p PKG_LIST     install packages from PKG_LIST [2]
```

### EXAMPLES

Run script (requires superuser privileges) ...

```bash
./ubuntu-after-install.sh
```

Install the list of packages specified in `my-pkg-list` ...

```bash
./ubuntu-after-install.sh -p my-pkg-list
```

### AUTHOR

Daniel Wayne Armstrong
https://www.circuidipity.com

### LICENSE

GPLv2. See ``LICENSE`` for more details.

### SEE ALSO

1. [Ubuntu MATE 18.04](https://www.circuidipity.com/ubuntu-mate-1804/)

2. [Install (almost) the same list of Debian packages on multiple machines](https://www.circuidipity.com/debian-package-list/)
