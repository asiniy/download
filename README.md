# `download`

[![hexdocs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](https://hexdocs.pm/download/Download.html#from/2)
![badge](https://img.shields.io/hexpm/v/download.svg)

Simply downloads remote file and stores it in the filesystem.

``` elixir
Download.from(url, options)
```

## Features

* Small RAM consumption
* Ability to limit downloaded file size
* Uses httpoison

## Installation

```elixir
def deps do
  [{:download, "~> x.x.x"}]
end
```

Into `mix.exs`

``` elixir
def application do
  [applications: [:download]]
end
```
