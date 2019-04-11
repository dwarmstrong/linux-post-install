# Ubuntu-after-install

#### NAME

ubuntu-after-install.sh - Configure a device after a fresh install of Ubuntu

#### SYNOPSIS

`ubuntu-after-install.sh [OPTION]`

#### DESCRIPTION

Script 'ubuntu-after-install.sh' is ideally run after the first successful boot into a _desktop_ install of Ubuntu's _18.04 LTS_ aka "bionic beaver" release.

A few tweaks will be made here and there, and a range of applications will be installed.

Alternately, in lieu of a pre-defined list of Ubuntu packages, the user may specify their own custom list of packages to be installed.

#### OPTIONS

```bash
-h              print details
-p PKG_LIST     install packages from PKG_LIST
```

#### EXAMPLES

Run script ...

```bash
# ./ubuntu-after-install.sh
```

Install the list of packages specified in `my-pkg-list` ...

```bash
# ./ubuntu-after-install.sh -p my-pkg-list
```

#### AUTHOR

[Daniel Wayne Armstrong](https://www.circuidipity.com)

#### SOURCE

[ubuntu-after-install](https://github.com/vonbrownie/linux-post-install/blob/master/scripts/ubuntu-after-install)

#### LICENSE

GPLv2. See [LICENSE](https://github.com/vonbrownie/linux-post-install/blob/master/LICENSE) for more details.

#### SEE ALSO

* [Install (almost) the same list of Debian packages on multiple machines](https://www.circuidipity.com/debian-package-list/)
