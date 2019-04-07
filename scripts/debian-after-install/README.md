# Debian-after-install

![Debian](debian-banner.png)

Link: ["More Debian: debian-after-install"](https://www.circuidipity.com/debian-after-install/)

## NAME

**debian-after-install.sh** - Configure a device after a fresh install of Debian's _testing_ release.

## SYNOPSIS

`debian-after-install.sh [OPTION]`

## DESCRIPTION

Script `debian-after-install.sh` is ideally run after the first successful boot into a [minimal install of Debian](https://www.circuidipity.com/minimal-debian/) _testing_ aka "buster" release.

A choice of either [w]orkstation or [s]erver setup is available. [S]erver is a basic console setup, whereas [w]orkstation is a more complete setup using Xorg and the lightweight [Openbox window manager](https://www.circuidipity.com/openbox/) plus a range of desktop applications.
    
Alternately, in lieu of a pre-defined list of Debian packages, the user may specify their own [custom list of packages](https://www.circuidipity.com/debian-package-list/) to be installed.

## OPTIONS

```bash
-h              print details
-p PKG_LIST     install packages from PKG_LIST
```

## EXAMPLES

Run script (requires root privileges) ...

```bash
./debian-after-install.sh
```

Install the list of packages specified in `my-pkg-list` ...

```bash
./debian-after-install.sh -p my-pkg-list
```

## AUTHOR

[Daniel Wayne Armstrong](https://www.circuidipity.com)

## LICENSE

GPLv2. See [LICENSE](https://github.com/vonbrownie/linux-post-install/blob/master/LICENSE) for more details.
