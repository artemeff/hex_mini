defmodule HexMini.ConfigTest do
  use HexMini.Case

  alias HexMini.Config

  @public File.read!("priv/keys/public_key.pem")
  @private File.read!("priv/keys/private_key.pem")

  describe "#ensure_public_key!/1" do
    test "returns public_key if it is valid" do
      assert @public == Config.ensure_public_key!(@public)
    end

    test "raise error when provide wrong key" do
      assert_raise(RuntimeError, "using PrivateKeyInfo for public_key, but SubjectPublicKeyInfo is expected", fn ->
        Config.ensure_public_key!(@private)
      end)
    end

    test "raise error when provide invalid path to key" do
      assert_raise(File.Error, ~s(could not read file "invalid": no such file or directory), fn ->
        Config.ensure_public_key!("invalid")
      end)
    end

    test "raise error when provide invalid key" do
      assert_raise(RuntimeError, "invalid public_key", fn ->
        Config.ensure_public_key!("mix.exs")
      end)
    end

    test "raise error when provide empty key" do
      assert_raise(RuntimeError, "public_key is empty", fn ->
        Config.ensure_public_key!("")
      end)
    end
  end

  describe "#ensure_private_key!/1" do
    test "returns public_key if it is valid" do
      assert @private == Config.ensure_private_key!(@private)
    end

    test "raise error when provide wrong key" do
      assert_raise(RuntimeError, "using SubjectPublicKeyInfo for private_key, but PrivateKeyInfo is expected", fn ->
        Config.ensure_private_key!(@public)
      end)
    end

    test "raise error when provide invalid path to key" do
      assert_raise(File.Error, ~s(could not read file "invalid": no such file or directory), fn ->
        Config.ensure_private_key!("invalid")
      end)
    end

    test "raise error when provide invalid key" do
      assert_raise(RuntimeError, "invalid private_key", fn ->
        Config.ensure_private_key!("mix.exs")
      end)
    end

    test "raise error when provide empty key" do
      assert_raise(RuntimeError, "private_key is empty", fn ->
        Config.ensure_private_key!("")
      end)
    end
  end

  describe "#ensure_path!/1" do
    test "returns path" do
      assert "priv/repo" == Config.ensure_path!("priv/repo")
    end

    test "raise error when path does not exist" do
      assert_raise(RuntimeError, "undefined/path does not exist", fn ->
        Config.ensure_path!("undefined/path")
      end)
    end

    test "raise error when pass path to the file" do
      assert_raise(RuntimeError, "mix.exs is not a directory", fn ->
        Config.ensure_path!("mix.exs")
      end)
    end
  end

  describe "#transform_credentials!/1" do
    test "returns list of tuples with names and tokens" do
      assert Config.transform_credentials!("john:doe\nuser1:token")
          == [{"user1", "token"}, {"john", "doe"}]
    end

    test "raise error when names have duplicates" do
      assert_raise(RuntimeError, "names in credentials are not unique", fn ->
        Config.transform_credentials!("john:1\njohn:2")
      end)
    end

    test "raise error when tokens have duplicates" do
      assert_raise(RuntimeError, "tokens in credentials are not unique", fn ->
        Config.transform_credentials!("john1:token\njohn2:token")
      end)
    end
  end
end
