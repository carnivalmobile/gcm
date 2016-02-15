# GCM

[![Build Status](https://travis-ci.org/carnivalmobile/gcm.svg?branch=master)](https://travis-ci.org/carnivalmobile/gcm) [![Hex.pm](https://img.shields.io/hexpm/v/gcm.svg?style=flat-square)](https://hex.pm/packages/gcm)

## Installation

First, add GCM to your mix.exs dependencies:

```elixir
def deps do
  [{:gcm, "~> 1.2"}]
end
```

and run `mix deps.get`. Now, list the `:gcm` application as your application dependency:

```elixir
def application do
  [applications: [:gcm]]
end
```

## Basic Usage

A successful push looks like this:

```
iex> GCM.push("api_key", ["registration_id1", "registration_id2"], %{notification: %{ title: "Hello!"} })
{:ok,
 %{body: "...",
   canonical_ids: [], failure: 0,
   headers: [{"Content-Type", "application/json; charset=UTF-8"},
    {"Vary", "Accept-Encoding"}, {"Transfer-Encoding", "chunked"}],
   invalid_registration_ids: [], not_registered_ids: [], status_code: 200, success: 2}}
```

A successful push may have a list of `canonical_ids` which means that you **should** update your registration id to the `new` one.

```
iex> GCM.push(api_key, ["registration_id1", "registration_id2"])
{:ok,
 %{body: "...",
   canonical_ids: [%{ old: "registration_id1", new: "new_registration_id1"}], failure: 0,
   headers: [{"Content-Type", "application/json; charset=UTF-8"},
    {"Vary", "Accept-Encoding"}, {"Transfer-Encoding", "chunked"}],
   invalid_registration_ids: [],
   not_registered_ids: [], status_code: 200, success: 2}}
```

A partial successful push may have `not_registered_ids` and/or `invalid_registration_ids`.
A "not registered id" is a registration id that was valid. According to GCM: "An existing registration token may cease to be valid in a number of scenarios..."

An invalid registration is just wrong data.

```
iex> GCM.push(api_key, ["registration_id1", "registration_id2", "registration_id3"])
{:ok,
 %{body: "...",
   canonical_ids: [], failure: 2,
   headers: [{"Content-Type", "application/json; charset=UTF-8"},
    {"Vary", "Accept-Encoding"}, {"Transfer-Encoding", "chunked"}],
   invalid_registration_ids: ["registration_id2"],
   not_registered_ids: ["registration_id1"], status_code: 200, success: 1}}
```

If the push failed the return is `{:error, reason}` where reason will include more information on what failed.

More info here: https://developers.google.com/cloud-messaging/http
