# dependency-runner

## Setup / Dependencies

### Preconfigured Linux Virtual Machine

1. Install [VirtualBox](https://www.virtualbox.org)
2. Install [Vagrant](https://www.vagrantup.com/downloads)
3. Clone this repo, `cd` inside the cloned directory, then `vagrant up`. Takes about 20 mins, go get some coffee
4. Run `vagrant ssh`. Great, now you are now inside the guest machine!
5. Inside the guest machine, `cd dependency-runner`

### Manual Setup

You need to get all these things installed:

- `python3.9` & `venv` (e.g. see [here](https://www.liquidweb.com/kb/how-to-install-and-update-python-to-3-9-in-ubuntu/) for Ubuntu)
- `pip` (e.g. `apt install python3-pip`), then update setuptools:
    + `python3.9 -m pip install --upgrade pip`
    + `python3.9 -m pip install --upgrade setuptools`
    + `python3.9 -m pip install --upgrade distlib`
- `node` (e.g. with [nvm](https://github.com/nvm-sh/nvm#installing-and-updating))
- `yarn` (`npm install -g yarn`)
- `verdaccio` (`npm install -g verdaccio`)
- `cargo` (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- `swift` (follow the directions for Linux [here](https://swift.org/download/))

## Running Tests

Run tests with `swift test`.
