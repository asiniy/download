# `download`

[![Build Status](https://travis-ci.org/asiniy/download.svg?branch=master)](https://travis-ci.org/asiniy/download)
[![hexdocs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](https://hexdocs.pm/download/Download.html#from/2)
![badge](https://img.shields.io/hexpm/v/download.svg)

Simply downloads remote file and stores it in the filesystem.

``` elixir
Download.from(url, options)
```

[Documentation](https://hexdocs.pm/download/Download.html#from/2)

## Features

* Small RAM consumption
* Ability to limit downloaded file size
* Uses httpoison

## Installation
Into mix.exs:
```elixir
def deps do
  [{:download, "~> x.x.x"}]
end
```
Only in elixir 1.3 an below:
``` elixir
def application do
  [applications: [:download]]
end
```
