# HexMini — self-hosted minimal hex.pm

* [Installation](#Installation)
* [Usage](#Usage)
* [Configuration](#Configuration)
* [Contributing](#Contributing)

---

## Installation

### Generate Keypair

```bash
$ openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
$ openssl rsa -pubout -in private_key.pem -out public_key.pem
```

### Start HexMini using Docker

...

### Start HexMini using Docker Compose

...

---

## Usage

### Register private repo

```bash
$ curl http://<HOST>/public_key -so ~/.hex/<REPO_NAME>.pem
$ mix hex.repo add <REPO_NAME> http://<HOST> --public-key ~/.hex/<REPO_NAME>.pem --auth-key <AUTH_KEY>
```

### Use it to fetch packages

```elixir
defp deps do
  [
    {:package, "~> 1.0", repo: "<REPO_NAME>"},
  ]
end
```

### Use it to publish packages

```bash
$ HEX_API_URL=http://<HOST> HEX_API_KEY=<AUTH_KEY> mix hex.publish package
```

---

## Configuration

...

---

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
