class AddUserToSpecimens < ActiveRecord::Migration[8.1]
  def change
    # Nullable on purpose: existing specimens (including the persistent prod
    # pgdata volume) predate ownership. Seeds backfill owners; new specimens
    # always get current_user. The FK nullifies if an owner is ever deleted.
    add_reference :specimens, :user, null: true, foreign_key: { on_delete: :nullify }
  end
end
