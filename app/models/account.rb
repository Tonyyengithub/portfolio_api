# frozen_string_literal: true

require 'sequel'
require 'json'
require_relative './password'

module Portfolio
  # Models a registered account
  class Account < Sequel::Model
    one_to_many :owned_projects, class: :'Portfolio::Project', key: :owner_id
    many_to_many :collaborations,
                 class: :'Portfolio::Project',
                 join_table: :accounts_projects,
                 left_key: :collaborator_id, right_key: :project_id

    plugin :association_dependencies,
           owned_projects: :destroy,
           collaborations: :nullify

    plugin :whitelist_security
    set_allowed_columns :username, :email, :password

    plugin :timestamps, update_on_create: true

    def self.create_github_account(github_account)
      create(username: github_account[:username],
             email:    github_account[:email])
    end

    def projects
      owned_projects + collaborations
    end

    def password=(new_password)
      self.password_digest = Password.digest(new_password)
    end

    def password?(try_password)
      digest = Portfolio::Password.from_digest(password_digest)
      digest.correct?(try_password)
    end

    def to_json(options = {})
      JSON(
        {
          type:       'account',
          attributes: public_attributes_hash
        }, options
      )
    end

    def public_attributes_hash
      {
        username: username,
        email:    email
      }
    end
  end
end
