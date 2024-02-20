class AddSftpIdToReport < ActiveRecord::Migration[6.0]
  def change
    add_reference :reports, :sftp, foreign_key: true
  end
end
