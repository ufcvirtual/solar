require 'digest/md5'

module Devise
  module Encryptors
    class Md5 < Base
      def self.digest(password, stretches, salt, pepper)
        without_salt = nil
        str = [password, without_salt].flatten.compact.join
        Digest::MD5.hexdigest(str)
      end
    end
  end
end
