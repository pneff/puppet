#
#  Created by Luke Kanies on 2007-9-22.
#  Copyright (c) 2007. All rights reserved.

require 'puppet'
require 'puppet/util/checksums'
require 'puppet/indirector'

# A checksum class to model translating checksums to file paths.  This
# is the new filebucket.
class Puppet::Checksum
    include Puppet::Util::Checksums

    extend Puppet::Indirector

    indirects :checksum

    attr_reader :algorithm, :content

    def algorithm=(value)
        raise ArgumentError, "Checksum algorithm #{value} is not supported" unless respond_to?(value)
        value = value.intern if value.is_a?(String)
        @algorithm = value
        # Reset the checksum so it's forced to be recalculated.
        @checksum = nil
    end

    # Calculate (if necessary) and return the checksum
    def checksum
        @checksum = send(algorithm, content) unless @checksum
        @checksum
    end

    def initialize(content, algorithm = "md5")
        raise ArgumentError.new("You must specify the content") unless content

        @content = content

        # Init to avoid warnings.
        @checksum = nil

        self.algorithm = algorithm
    end

    # This is here so the Indirector::File terminus works correctly.
    def name
        checksum
    end

    def to_s
        "Checksum<{#{algorithm}}#{checksum}>"
    end
end
