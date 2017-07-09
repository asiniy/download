# `download`

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
