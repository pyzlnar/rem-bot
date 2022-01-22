# Rem

Rem is a Discord bot written in elixir. \
It was written simply because I was bored and I really wanted to write my own Discord bot in Elixir.

This is the second iteration as the previous one was using another discord bot library (Alchemy)
which I dropped since it seemed to be less maintained and a bit more rough around the edges. \
My previous attempt can be found here: [pyzlnar/discord-bot](https://github.com/pyzlnar/discord-bot)

## Installation

### Erlang and Elixir

It's recommended to install through [asdf](https://github.com/asdf-vm/asdf)

```bash
$ asdf plugin-add elixir
$ asdf plugin-add erlang
$ asdf install
```

> :warning: asdf automatically uses the versions of Elixir, Erlang specified in
> [`.tool-versions`](.tool-versions). \
> If you choose not to use asdf, and encounter errors, ensure that the dependencies you are using
> match the versions specified in [`.tool-versions`](.tool-versions).

You can verify the installation by running: \
(And you can exit it by pressing CTRL+C twice. yeah...)

```bash
$ iex
Erlang/OTP 24 [erts-12.1.5] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1]

Interactive Elixir (1.13.2) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

### Dependencies

```bash
# Install dependencies
$ mix deps.get
# Compile
$ mix
```

### Environment

The project requires some environment variables to be set. (secrets!) \
The recomended method is through [direnv](https://github.com/direnv/direnv), but as long you setup
all variables in [`.env.example`](.env.example) you should be good.

```bash
$ cp .env.example .env
$ direnv allow .
```
Now just modify `.env` with the needed values.

## Running

Running in dev mode:

```bash
$ mix run --no-halt
```

With an interactive shell:

```bash
$ iex -S mix
```

In detached mode for prod

```bash
$ MIX_ENV=prod elixir --erl "-detached" -S mix run --no-halt

# You can stop it by killing the process
$ ps aux | grep elixir
pyzlnar 14381 (. . .) elixir -S mix run --no-halt
$ kill -9 14381
```

## Tests

Tests can be run with:

```bash
$ mix test
```

## License

Rem bot is released under the [MIT License](https://opensource.org/licenses/MIT).
