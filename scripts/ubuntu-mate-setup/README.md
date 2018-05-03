# ubuntu-mate-setup

## SYNOPSIS

```
ubuntu-mate-stable-setup.sh [ options ] USER
```

## OPTIONS

```
    -h              print details
    -p PKG_LIST     install packages from PKG_LIST
```

## EXAMPLE

Post-install setup of a machine running Ubuntu MATE 17.10 "Artful Aardvark" for USER 'foo' ...

```
sudo ./ubuntu-mate-setup.sh foo
```

Install packages from 'pkg-list' ...

```
sudo ./ubuntu-mate-setup.sh -p pkg-list foo
```

## DESCRIPTION

Script **ubuntu-mate-setup.sh** is ideally run immediately following the first successful boot into your new Ubuntu MATE installation.

Building on the default setup of release 17.10 "Artful Aardvark", a choice of either ...

1) configuration tweaks and extra desktop packages; or
2) duplicate the [same list of packages as PKG_LIST](https://www.circuidipity.com/debian-package-list)

... will be installed.

## USE

**0.** Install program folder on target machine.

**1.** Copy ``config.sample`` to ``config`` and (optional) enable settings. All settings are **disabled** by default.

**2.** Run program!

## DEPENDS

``bash``

Happy hacking!

### Author

Daniel Wayne Armstrong (aka) VonBrownie <br />
https://www.circuidipity.com

### License

GPLv2. See ``LICENSE`` for more details.
