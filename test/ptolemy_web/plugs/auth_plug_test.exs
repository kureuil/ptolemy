defmodule TequilaWeb.AuthPlugTest do
  use TequilaWeb.ConnCase
  import Ecto.Query
  alias Tequila.Repo
  alias Tequila.Accounts
  alias Tequila.Accounts.Credential
  alias TequilaWeb.AuthPlug

  def fixture_owner() do
    email = "louis@example.com"

    try do
      Accounts.get_user_by_email!(email)
    rescue
      _ in Ecto.NoResultsError ->
        {:ok, user} = Accounts.create_user(%{email: email})
        user
    end
  end

  def fixture_credential() do
    query = from(c in Credential, where: c.provider == "email" and c.uid == "louis@example.com")

    Repo.one(query) ||
      Repo.insert!(%Credential{
        provider: "email",
        uid: "louis@example.com",
        token: "supersecretpassword",
        user_id: fixture_owner().id
      })
  end

  describe "Authentication Plug" do
    setup [:create_owner, :create_credential]

    test "Redirects to sign in page if there is no data in session", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{})
      conn = AuthPlug.call(conn, %{})
      assert redirected_to(conn) =~ Routes.session_path(conn, :new)
    end

    test "Ignores session data if :current_user is already assigned", %{
      conn: conn,
      owner: owner,
      credential: credential
    } do
      other_user =
        Repo.insert!(%Accounts.User{
          email: "walouis@example.com"
        })

      session =
        Repo.insert!(%Accounts.Session{
          invalidated_at: nil,
          user_id: owner.id,
          credential_id: credential.id
        })

      conn = Plug.Test.init_test_session(conn, %{"user:session" => session.id})
      conn = Plug.Conn.assign(conn, :current_user, other_user)
      conn = AuthPlug.call(conn, %{})
      assert conn.assigns[:current_user] == other_user
    end

    test "Assigns to the connection the user associated to the session", %{
      conn: conn,
      owner: owner,
      credential: credential
    } do
      session =
        Repo.insert!(%Accounts.Session{
          invalidated_at: nil,
          user_id: owner.id,
          credential_id: credential.id
        })

      conn = Plug.Test.init_test_session(conn, %{"user:session" => session.id})
      conn = AuthPlug.call(conn, %{})
      assert conn.assigns[:current_user].id == owner.id
    end
  end

  defp create_owner(_) do
    owner = fixture_owner()
    {:ok, owner: owner}
  end

  defp create_credential(_) do
    credential = fixture_credential()
    {:ok, credential: credential}
  end
end
