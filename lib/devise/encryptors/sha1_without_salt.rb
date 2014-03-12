# lib/devise/encryptors/sha1_without_salt.rb
require 'digest/sha1'

module Devise
  module Encryptable
    module Encryptors
      class Sha1WithoutSalt < Base
        def self.digest(password, stretches, salt, pepper)
          Digest::SHA1.hexdigest(password)
        end
      end
    end
  end
end
