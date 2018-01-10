# Debian _stable_ release setup

![Debian](files/img/debian_9_banner.png)

## NAME

debian-stable-setup.sh - Debian post-install configuration

## SYNOPSIS

`debian-stable-setup.sh [OPTION] username`

## DESCRIPTION

Script `debian-stable-setup.sh` is ideally run immediately following the first successful boot into a new install of Debian's `stable` release.

A choice of either ...

0) a basic console setup; or
1) a more complete setup using the **i3 tiling window manager** plus desktop packages; or
2) install the list of packages specified in `PKG_LIST`

... will be configured.

To use program ... 

0) Install program folder on target machine.
1) Copy `config.sample` to `config` and (optional) enable settings. All settings are **disabled** by default.
2) Run program!

## OPTIONS

```bash
-h              print details
-b              basic setup (console only)
-p PKG_LIST     install packages from PKG_LIST
```

## EXAMPLES

Post-install setup of a machine for username `foo` ...

```bash
# debian-stable-setup.sh foo
```

Install the list of packages specified in `my-pkg-list` ...

```bash
# xdeb -p my-pkg-list foo
```

## AUTHOR

Daniel Wayne Armstrong
https://www.circuidipity.com

## LICENSE

GPLv3. See ``LICENSE`` for more details.

## SEE ALSO

[Minimal Debian](https://www.circuidipity.com/minimal-debian/)

[Lightweight and a delight: i3 tiling window manager](https://www.circuidipity.com/i3-tiling-window-manager/)

[Install (almost) the same list of Debian packages on multiple machines](https://www.circuidipity.com/debian-package-list/]
