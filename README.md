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

## About [Brutalist](https://brutalist.press)

<a href="https://brutalist.press">
  <img src="https://github.com/asiniy/download/blob/master/brutalist_logo.png"
  width="400"
  height="106"
  alt="Brutalist">
</a>
<br /><br />

`download` package is maintained and funded by folks from [Brutalist](https://brutalist.press) - media platform for writing and sharing news and stories with strong focus on traditional values, think-tank level analytics and political research.
