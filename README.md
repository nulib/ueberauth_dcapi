# Ueberauth Strategy for Northwestern University Library Digital Collections API

[![Build](https://github.com/nulib/ueberauth_dcapi/actions/workflows/test.yml/badge.svg)](https://github.com/nulib/ueberauth_dcapi/actions/workflows/test.yml)
[![Coverage](https://coveralls.io/repos/github/nulib/ueberauth_dcapi/badge.svg?branch=main)](https://coveralls.io/github/nulib/ueberauth_dcapi?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/ueberauth_dcapi.svg)](https://hex.pm/packages/ueberauth_dcapi)

Northwestern University Library Digital Collections API strategy for [Ueberauth](https://github.com/ueberauth/ueberauth)

## Installation

  1. Add `ueberauth` and `ueberauth_dcapi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ueberauth, "~> 0.2"},
    {:ueberauth_dcapi, "~> 0.1"},
  ]
end
```

  2. Ensure `ueberauth_dcapi` is started before your application:

```elixir
def application do
  [applications: [:ueberauth_dcapi]]
end
```

  3. Configure the DC API integration in `config/config.exs`:

```elixir
config :ueberauth, Ueberauth,
  providers: [dcapi: {Ueberauth.Strategy.DcAPI, [
    base_url: "https://api.dc.library.northwestern.edu/",
    cookie: "dcApi472819"
  ]}]
```

  4. In `AuthController` use the DcAPI strategy in your `login/4` function:

```elixir
def login(conn, _params, _current_user, _claims) do
  conn
  |> Ueberauth.Strategy.DcApi.handle_request!
end
```

## Contributing

Issues and Pull Requests are always welcome!
