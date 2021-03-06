defmodule TequilaWeb.InviteController do
  use TequilaWeb, :controller

  alias Tequila.Invites
  alias Tequila.Invites.Invite
  alias Tequila.Invites.Redeem
  alias TequilaWeb.InviteEmail

  def index(conn, _params) do
    invites = Invites.list_pending_by_owner(conn.assigns[:current_user])
    render(conn, "index.html", invites: invites)
  end

  def new(conn, _params) do
    changeset = Invites.change_invite(%Invite{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"invite" => invite}) do
    case Invites.create_invite(invite, conn.assigns[:current_user]) do
      {:ok, invite} ->
        InviteEmail.invite(invite, conn.assigns[:current_user])
        |> IO.inspect()
        |> Tequila.Mailer.deliver()
        |> IO.inspect()

        conn
        |> put_flash(:info, gettext("Invite sent to %{invitee}.", invitee: invite.invitee))
        |> redirect(to: Routes.invite_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => invite_id}) do
    try do
      invite = Invites.find!(invite_id)
      Invites.delete_invite!(invite)

      conn
      |> put_flash(
        :info,
        gettext("The invite addressed to %{invitee} was successfully deleted.",
          invitee: invite.invitee
        )
      )
      |> redirect(to: Routes.invite_path(conn, :index))
    rescue
      _ ->
        conn
        |> put_flash(:error, gettext("Couldn't delete the invite. Please try again later."))
        |> redirect(to: Routes.invite_path(conn, :index))
    end
  end

  def redeem(conn, %{"invite" => invite_id}) do
    case Invites.find_for_redeem(invite_id) do
      nil ->
        conn
        |> put_flash(
          :error,
          gettext(
            "The invite link you used isn't valid. Please ask the person that invited you again."
          )
        )
        |> redirect(to: Routes.session_path(conn, :new))

      invite ->
        changeset = Invites.change_redeem(%Redeem{email: invite.invitee})

        conn
        |> put_layout("unauthenticated.html")
        |> render("redeem.html", invite: invite, changeset: changeset)
    end
  end

  def register(conn, %{"invite" => invite_id, "redeem" => redeem_params}) do
    case Invites.find_for_redeem(invite_id) do
      nil ->
        conn
        |> put_flash(
          :error,
          gettext(
            "The invite link you used isn't valid. Please ask the person that invited you again."
          )
        )
        |> redirect(to: Routes.session_path(conn, :new))

      invite ->
        case Invites.redeem(invite, redeem_params) do
          {:error, changeset} ->
            conn
            |> put_layout("unauthenticated.html")
            |> render("redeem.html", invite: invite, changeset: changeset)

          {:ok, _user} ->
            conn
            |> redirect(to: Routes.session_path(conn, :new))
        end
    end
  end
end
