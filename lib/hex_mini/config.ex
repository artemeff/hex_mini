defmodule HexMini.Config do
  defmodule Error do
    defexception [:message]

    @impl true
    def exception(message) do
      %__MODULE__{message: message}
    end
  end

  defmacro __using__(_opts \\ []) do
    quote do
      import HexMini.Config, only: [path_env: 1, credentials_env: 1, public_key_env: 1, private_key_env: 1]
    end
  end

  def path_env(env, default) do
    path = System.get_env(env) || default

    if File.exists?(path) && File.dir?(path) do
      path
    else
      raise Error, "#{path} does not exist"
    end
  end

  def credentials_env(path_env) do
    path_env |> fetch_env!() |> credentials()
  end

  # TODO check for uniqueness for usernames and tokens
  def credentials(path) do
    slugs = path |> read_file!() |> String.split("\n")

    Enum.reduce(slugs, [], fn(slug, acc) ->
      case String.split(slug, ":", parts: 2) do
        [user, token] -> [{user, token} | acc]
        _ -> acc
      end
    end)
  end

  def public_key_env(env) do
    public_key(System.get_env(env))
  end

  def public_key(contents_or_path) do
    key_config(contents_or_path, fn(key) ->
      case :public_key.pem_decode(key) do
        [{:SubjectPublicKeyInfo, _key, _}] -> key
        [{type, _, _}] -> raise Error, "using #{inspect(type)} for public_key"
        _ -> nil
      end
    end)
  end

  def private_key_env(env) do
    private_key(System.get_env(env))
  end

  def private_key(contents_or_path) do
    key_config(contents_or_path, fn(key) ->
      case :public_key.pem_decode(key) do
        [{:PrivateKeyInfo, _key, _}] -> key
        [{type, _, _}] -> raise Error, "using #{inspect(type)} for private_key"
        _ -> nil
      end
    end)
  end

  defp key_config(nil, _) do
    nil
  end
  defp key_config(contents_or_path, encoder) do
    case encoder.(contents_or_path) do
      nil -> key_config_file(contents_or_path, encoder)
      key -> key
    end
  end

  defp key_config_file(path, encoder) do
    path |> read_file!() |> encoder.()
  end

  defp fetch_env!(name) do
    System.get_env(name) || raise Error, "env #{name} is not set"
  end

  defp read_file!(path) do
    case File.read(path) do
      {:ok, contents} -> contents
      {:error, reason} -> raise Error, "#{:file.format_error(reason)} `#{path}`"
    end
  end
end
