# Debian-after-install

### NAME

debian-after-install.sh - Configure a device after a fresh install of Debian "Buster"

### SYNOPSIS

`debian-after-install.sh [OPTION]`

### DESCRIPTION

Script `debian-after-install.sh` [1] is a *setup script* ideally run immediately following the first successful boot into a minimal install [2] of Debian "Buster".

A choice of either a **workstation** or **server** setup is available. *Server* is a basic console setup, whereas the *workstation* choice is a more extensive configuration using the lightweight **Openbox** [3] window manager and a range of desktop applications.

Alternately, in lieu of a pre-defined list of Debian packages, the user may specify their own custom list of packages to be installed.

### OPTIONS

```bash
-h              print details
-p PKG_LIST     install packages from PKG_LIST [4]
```

### EXAMPLES

Run script (requires superuser privileges) ...

```bash
./debian-stable-setup.sh
```

Install the list of packages specified in `my-pkg-list` ...

```bash
./debian-stable-setup.sh -p my-pkg-list
```

### AUTHOR

Daniel Wayne Armstrong
https://www.circuidipity.com

### LICENSE

GPLv2. See ``LICENSE`` for more details.

### SEE ALSO

TODO
```
1. [Console tools: debian-after-install](https://www.circuidipity.com/.../)
```

2. [Minimal Debian](https://www.circuidipity.com/minimal-debian/)

3. [Roll your own Linux desktop using Openbox](https://www.circuidipity.com/openbox/)

4. [Install (almost) the same list of Debian packages on multiple machines](https://www.circuidipity.com/debian-package-list/)
