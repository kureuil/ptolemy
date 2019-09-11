defmodule Tequila.Invites do
  @moduledoc """
  The Invites Context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Tequila.Repo
  alias Tequila.Invites.Invite
  alias Tequila.Invites.Redeem
  alias Tequila.Accounts
  alias Tequila.Accounts.User

  @doc """
  Lists all pending invites created by the given user.

  ## Examples

      iex> list_pending_by_owner(%User{})
      [%Invite{}, ...]

  """
  def list_pending_by_owner(%User{id: owner_id}) do
    Repo.all(
      from i in Invite,
        where: i.owner_id == ^owner_id,
        order_by: i.inserted_at
    )
  end

  def find!(id) do
    Repo.one!(from i in Invite, where: i.id == ^id)
  end

  def change_invite(%Invite{} = invite) do
    Invite.changeset(invite, %{})
  end

  def create_invite(attrs, %User{} = owner) do
    %Invite{}
    |> Invite.changeset(attrs)
    |> Changeset.put_assoc(:owner, owner)
    |> Repo.insert()
  end

  def find_for_redeem(id) do
    query =
      from i in Invite,
        where: i.id == ^id and i.inserted_at < datetime_add(i.inserted_at, 5, "day")

    query
    |> Repo.one()
    |> Repo.preload(:owner)
  end

  def change_redeem(%Redeem{} = redeem) do
    Redeem.changeset(redeem, %{})
  end

  def delete_invite!(%Invite{} = invite) do
    Repo.delete!(invite)
  end

  def redeem(%Invite{} = invite, %{} = redeem_params) do
    case Redeem.changeset(%Redeem{}, redeem_params) do
      %{valid?: true} = changeset ->
        redeem = Changeset.apply_changes(changeset)

        case Repo.transaction(fn ->
               {:ok, user} = Accounts.create_user(Redeem.to_user(redeem), invite.owner)
               {:ok, _} = Accounts.create_credential(Redeem.to_credential(redeem), user)
               delete_invite!(invite)
               user
             end) do
          {:ok, user} ->
            {:ok, user}

          {:error, _} ->
            {:error, changeset}
        end

      changeset ->
        {:error, changeset}
    end
  end
end
