defmodule HexMini.Config do
  defmacro __using__(_opts \\ []) do
    quote do
      import HexMini.Config, only: [env!: 1, env: 2]

      alias HexMini.Config
    end
  end

  def env!(key) do
    System.get_env(key) || raise "env #{key} is not set"
  end

  def env(key, default) do
    System.get_env(key) || default
  end

  def ensure_public_key!(contents) do
    key_config(contents, "public_key", :SubjectPublicKeyInfo)
  end

  def ensure_private_key!(contents) do
    key_config(contents, "private_key", :PrivateKeyInfo)
  end

  def transform_credentials!(contents) do
    contents
    |> String.split("\n")
    |> Enum.reduce([], fn(slug, acc) ->
         case String.split(slug, ":", parts: 2) do
           [user, token] -> [{user, token} | acc]
           _ -> acc
         end
       end)
    |> check_credentials_uniqueness!()
  end

  defp key_config(contents, name, _type) when contents in [nil, ""] do
    raise "#{name} is empty"
  end
  defp key_config(contents, name, expected_type) do
    case :public_key.pem_decode(contents) do
      [{^expected_type, _key, _}] -> contents
      [{type, _key, _}] -> raise "using #{type} for #{name}, but #{expected_type} is expected"
      _ -> raise "invalid #{name}"
    end
  end

  defp check_credentials_uniqueness!(credentials) do
    names = Enum.map(credentials, &(elem(&1, 0)))

    unless list_uniq?(names) do
      raise "names in credentials are not unique"
    end

    tokens = Enum.map(credentials, &(elem(&1, 1)))

    unless list_uniq?(tokens) do
      raise "tokens in credentials are not unique"
    end

    credentials
  end

  defp list_uniq?(list) do
    length(list) == length(Enum.uniq(list))
  end
end
